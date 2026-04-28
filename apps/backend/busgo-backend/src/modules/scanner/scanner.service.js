import { supabase } from '../../config/supabase.js';

const QR_PREFIX = 'BUSGO-';
const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Process a passenger QR scan from the BUSGO Scanner app.
 *
 * Flow:
 *   1. Parse the QR payload  → extract user UUID
 *   2. Validate the user     → must exist + be active
 *   3. Find the driver's bus → driver must be assigned to one
 *   4. Toggle trip state:
 *        - No ongoing trip  → create one  (passenger is BOARDING)
 *        - Ongoing trip     → complete it (passenger is ALIGHTING)
 *
 * @param {string} driverId - JWT-extracted driver id
 * @param {{ qr_code: string }} dto
 * @returns {object} verifying-message payload
 */
export async function recordScan(driverId, { qr_code }) {
  // 1. Parse QR payload
  if (!qr_code.startsWith(QR_PREFIX)) {
    const err = new Error('Invalid QR code format. Expected BUSGO-<id>.');
    err.statusCode = 400;
    err.code = 'INVALID_QR';
    throw err;
  }
  const userId = qr_code.slice(QR_PREFIX.length).trim();
  if (!UUID_RE.test(userId)) {
    const err = new Error('Invalid QR code — not a valid user identifier.');
    err.statusCode = 400;
    err.code = 'INVALID_QR';
    throw err;
  }

  // 2. Look up the passenger
  const { data: user, error: userErr } = await supabase
    .from('users')
    .select('id, full_name, email, is_active')
    .eq('id', userId)
    .maybeSingle();

  if (userErr) throw userErr;
  if (!user) {
    const err = new Error('Passenger not found for this QR code.');
    err.statusCode = 404;
    err.code = 'USER_NOT_FOUND';
    throw err;
  }
  if (user.is_active === false) {
    const err = new Error('Passenger account is inactive.');
    err.statusCode = 403;
    err.code = 'USER_INACTIVE';
    throw err;
  }

  // 3. Find the driver's bus + route (picks the active one when multiple
  // are linked — see _findDriverBus for the ordering rules).
  const bus = await _findDriverBus(
    driverId,
    'id, bus_number, route_id, crowd_level, bus_routes ( route_number, route_name )',
  );
  if (!bus) {
    const err = new Error('Driver is not assigned to any bus.');
    err.statusCode = 400;
    err.code = 'NO_BUS_ASSIGNED';
    throw err;
  }

  // 4. Boarding vs alighting based on existing trip state
  const { data: ongoing } = await supabase
    .from('trips')
    .select('id, boarded_at')
    .eq('user_id', user.id)
    .eq('status', 'ongoing')
    .maybeSingle();

  if (ongoing) {
    // ── Alight: end the existing trip ────────────────────────────
    const fareLkr = 70; // flat-rate demo fare; replace with real calc
    const { data: trip, error: alightErr } = await supabase
      .from('trips')
      .update({
        status:      'completed',
        alighted_at: new Date().toISOString(),
        fare_lkr:    fareLkr,
      })
      .eq('id', ongoing.id)
      .select('id, status, boarded_at, alighted_at, fare_lkr')
      .single();

    if (alightErr) throw alightErr;

    const tripsCount = await _countOnBoard(bus.id);
    const onBoard    = Math.min(50, _crowdToCount(bus.crowd_level) + tripsCount);

    return {
      action:    'alighted',
      passenger: { id: user.id, name: user.full_name, email: user.email },
      bus:       { id: bus.id, number: bus.bus_number,
                   route: bus.bus_routes?.route_number ?? null,
                   on_board: onBoard, capacity: 50 },
      trip,
      message:   `Trip completed for ${user.full_name}. Fare Rs ${fareLkr}.`,
    };
  }

  // ── Board: create a new ongoing trip ───────────────────────────
  const { data: trip, error: boardErr } = await supabase
    .from('trips')
    .insert({
      user_id:  user.id,
      bus_id:   bus.id,
      route_id: bus.route_id,
      status:   'ongoing',
    })
    .select('id, status, boarded_at')
    .single();

  if (boardErr) throw boardErr;

  const tripsCountB = await _countOnBoard(bus.id);
  const onBoard     = Math.min(50, _crowdToCount(bus.crowd_level) + tripsCountB);

  return {
    action:    'boarded',
    passenger: { id: user.id, name: user.full_name, email: user.email },
    bus:       { id: bus.id, number: bus.bus_number,
                 route: bus.bus_routes?.route_number ?? null,
                 on_board: onBoard, capacity: 50 },
    trip,
    message:   `${user.full_name} has boarded successfully.`,
  };
}

/**
 * Live on-board count for the bus assigned to this driver.
 * Returns { on_board, capacity } so the scanner UI shows realistic numbers.
 *
 * Calculation:
 *   on_board = baseline (from bus.crowd_level)  + active scanned trips
 *
 * The baseline represents passengers who boarded before tracking started —
 * derived from the bus's seeded/admin-set `crowd_level`. Each scanner scan
 * then adds (boarding) or removes (alighting) from the live count.
 */
export async function getOnBoardForDriver(driverId) {
  const bus = await _findDriverBus(driverId, 'id, crowd_level');
  if (!bus) return { on_board: 0, capacity: 50, boarded_today: 0 };

  const baseline      = _crowdToCount(bus.crowd_level);
  const trips         = await _countOnBoard(bus.id);
  const boardedToday  = await _countBoardedToday(bus.id);
  const total         = Math.min(50, baseline + trips);
  return { on_board: total, capacity: 50, boarded_today: boardedToday };
}

/**
 * Total boardings (ongoing + completed) for this bus since midnight today.
 * Used by the driver dashboard's "Boarded" stat tile.
 */
async function _countBoardedToday(busId) {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  const { count } = await supabase
    .from('trips')
    .select('id', { count: 'exact', head: true })
    .eq('bus_id', busId)
    .gte('boarded_at', startOfDay.toISOString());
  return count ?? 0;
}

/**
 * Picks the right bus when a driver is linked to several buses.
 * Order of preference:
 *   1. status = 'active'
 *   2. most recent last_location_update
 *   3. anything (deterministic via bus_number)
 */
async function _findDriverBus(driverId, columns) {
  const { data: buses } = await supabase
    .from('buses')
    .select(`${columns}, status, last_location_update, bus_number`)
    .eq('driver_id', driverId)
    .order('status', { ascending: true })   // 'active' sorts before 'standby'
    .order('last_location_update', { ascending: false, nullsFirst: false })
    .order('bus_number', { ascending: true });
  return buses?.[0] ?? null;
}

function _crowdToCount(level) {
  switch (level) {
    case 'full':   return 45;
    case 'high':   return 32;
    case 'medium': return 18;
    case 'low':    return 6;
    default:       return 0;
  }
}

/**
 * Count ongoing trips for a bus — passengers who boarded via scanner.
 */
async function _countOnBoard(busId) {
  const { count } = await supabase
    .from('trips')
    .select('id', { count: 'exact', head: true })
    .eq('bus_id', busId)
    .eq('status', 'ongoing');
  return count ?? 0;
}

// Note: bus.crowd_level is now managed only by admin/driver explicit
// adjustments (driver app +/- buttons, admin Fleet Mgmt). The scanner
// no longer overwrites it on each scan because that creates a feedback
// loop with the baseline-derived display count.
