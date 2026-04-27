import { supabase } from '../../config/supabase.js';

const DRIVER_SELECT = `
  id, driver_code, full_name, email, phone, rating,
  status, pending_review,
  bus_routes ( id, route_number, route_name, color, origin, destination )
`;

/**
 * Get driver profile with assigned bus info.
 */
export async function getDriverMe(driverId) {
  const { data: driver, error } = await supabase
    .from('drivers')
    .select(DRIVER_SELECT)
    .eq('id', driverId)
    .single();

  if (error) throw error;

  // Find assigned bus
  const { data: bus } = await supabase
    .from('buses')
    .select('id, bus_number, registration, status, current_lat, current_lng')
    .eq('driver_id', driverId)
    .maybeSingle();

  return { ...driver, bus: bus || null };
}

/**
 * Get driver's assigned route with all stops.
 */
export async function getDriverRoute(driverId) {
  const { data: driver } = await supabase
    .from('drivers')
    .select('route_id')
    .eq('id', driverId)
    .single();

  if (!driver?.route_id) {
    const err = new Error('No route assigned to this driver');
    err.statusCode = 404;
    throw err;
  }

  const { data: route, error: routeErr } = await supabase
    .from('bus_routes')
    .select('id, route_number, route_name, color, origin, destination, is_active')
    .eq('id', driver.route_id)
    .single();

  if (routeErr) throw routeErr;

  // Fetch stops ordered by stop_order
  const { data: stopsRaw } = await supabase
    .from('bus_stop_routes')
    .select('id, stop_order, bus_stops(id, stop_name, latitude, longitude)')
    .eq('route_id', driver.route_id)
    .order('stop_order');

  const stops = (stopsRaw ?? []).map((r) => ({
    junction_id: r.id,
    stop_order:  r.stop_order,
    id:          r.bus_stops?.id,
    stop_name:   r.bus_stops?.stop_name,
    latitude:    r.bus_stops?.latitude,
    longitude:   r.bus_stops?.longitude,
  }));

  return { ...route, stops };
}

/**
 * Update bus location for the bus driven by this driver.
 */
export async function updateDriverLocation(driverId, { latitude, longitude, speed, heading }) {
  // Use limit(1) — a driver may temporarily have >1 bus linked during reassignments;
  // .maybeSingle() rejects with "multiple rows" in that case, which crashes the request.
  const { data: buses, error: busErr } = await supabase
    .from('buses')
    .select('id')
    .eq('driver_id', driverId)
    .limit(1);

  if (busErr) throw busErr;
  const bus = buses?.[0];
  if (!bus) {
    const err = new Error('No bus assigned to this driver');
    err.statusCode = 404;
    throw err;
  }

  const { data, error } = await supabase
    .from('buses')
    .update({
      current_lat:         latitude,
      current_lng:         longitude,
      speed_kmh:           speed ?? 0,
      heading:             heading ?? null,
      last_location_update: new Date().toISOString(),
    })
    .eq('id', bus.id)
    .select('id, bus_number, current_lat, current_lng, speed_kmh, last_location_update')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Update passenger count on the driver's bus.
 */
export async function updatePassengerCount(driverId, { crowd_level }) {
  const validLevels = ['low', 'medium', 'high', 'full'];
  if (!validLevels.includes(crowd_level)) {
    const err = new Error('crowd_level must be one of: low, medium, high, full');
    err.statusCode = 400;
    throw err;
  }

  const { data: buses } = await supabase
    .from('buses')
    .select('id')
    .eq('driver_id', driverId)
    .limit(1);

  const bus = buses?.[0];
  if (!bus) {
    const err = new Error('No bus assigned to this driver');
    err.statusCode = 404;
    throw err;
  }

  const { data, error } = await supabase
    .from('buses')
    .update({ crowd_level })
    .eq('id', bus.id)
    .select('id, bus_number, crowd_level')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Create an emergency alert from the driver's bus.
 */
export async function createDriverAlert(driverId, { alert_type, description, latitude, longitude, priority }) {
  const validTypes = ['medical', 'criminal', 'breakdown', 'accident', 'harassment', 'other'];
  if (!validTypes.includes(alert_type)) {
    const err = new Error(`alert_type must be one of: ${validTypes.join(', ')}`);
    err.statusCode = 400;
    throw err;
  }

  // Find the bus for this driver (limit(1) tolerates multi-bus assignments)
  const { data: buses } = await supabase
    .from('buses')
    .select('id, bus_number')
    .eq('driver_id', driverId)
    .limit(1);
  const bus = buses?.[0];

  // Try with driver_id first; if the column doesn't exist yet (migration pending) retry without it
  let insertPayload = {
    bus_id:      bus?.id || null,
    driver_id:   driverId,
    alert_type,
    description: description || null,
    latitude:    latitude  || null,
    longitude:   longitude || null,
    priority:    priority  || 'P2',
    status:      'pending',
  };

  let { data, error } = await supabase
    .from('emergency_alerts')
    .insert(insertPayload)
    .select('id, alert_type, description, latitude, longitude, priority, status, created_at')
    .single();

  // If driver_id column missing (migration not run), retry without it
  if (error?.message?.includes('driver_id')) {
    const { driver_id: _dropped, ...fallbackPayload } = insertPayload;
    ({ data, error } = await supabase
      .from('emergency_alerts')
      .insert(fallbackPayload)
      .select('id, alert_type, description, latitude, longitude, priority, status, created_at')
      .single());
  }

  if (error) throw error;

  // Notify admins via admin_notifications
  await supabase.from('admin_notifications').insert({
    type:    'emergency',
    title:   `🚨 Driver Emergency: ${alert_type.toUpperCase()}`,
    message: `Bus ${bus?.bus_number ?? 'Unknown'} — ${description || alert_type}`,
    meta:    { alert_id: data.id, driver_id: driverId, bus_id: bus?.id },
  });

  return data;
}
