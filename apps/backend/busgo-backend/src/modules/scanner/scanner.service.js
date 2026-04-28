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

  // 3. Find the driver's bus + route
  const { data: buses } = await supabase
    .from('buses')
    .select('id, bus_number, route_id, bus_routes ( route_number, route_name )')
    .eq('driver_id', driverId)
    .limit(1);

  const bus = buses?.[0];
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

    return {
      action:    'alighted',
      passenger: { id: user.id, name: user.full_name, email: user.email },
      bus:       { id: bus.id, number: bus.bus_number,
                   route: bus.bus_routes?.route_number ?? null },
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

  return {
    action:    'boarded',
    passenger: { id: user.id, name: user.full_name, email: user.email },
    bus:       { id: bus.id, number: bus.bus_number,
                 route: bus.bus_routes?.route_number ?? null },
    trip,
    message:   `${user.full_name} has boarded successfully.`,
  };
}
