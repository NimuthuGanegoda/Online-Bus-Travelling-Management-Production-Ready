import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

// ── Stops for a specific route ────────────────────────────────────────────────

export async function getRouteStops(routeId) {
  const { data, error } = await supabase
    .from('bus_stop_routes')
    .select(`
      id,
      stop_order,
      bus_stops ( id, stop_name, latitude, longitude, created_at )
    `)
    .eq('route_id', routeId)
    .order('stop_order');

  if (error) throw error;
  return (data ?? []).map((r) => ({
    junction_id: r.id,
    stop_order:  r.stop_order,
    ...r.bus_stops,
  }));
}

// ── Create a brand-new stop and assign it to a route ─────────────────────────

export async function addStopToRoute(routeId, { stopName, latitude, longitude, stopOrder }, admin) {
  if (!stopName || latitude == null || longitude == null) {
    throw Object.assign(
      new Error('stop_name, latitude and longitude are required'),
      { statusCode: 400 },
    );
  }
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
    throw Object.assign(new Error('Invalid coordinates'), { statusCode: 400 });
  }

  // 1. Insert the stop (or reuse existing one with same name+coords)
  const { data: stop, error: stopErr } = await supabase
    .from('bus_stops')
    .insert({ stop_name: stopName.trim(), latitude, longitude })
    .select('id, stop_name, latitude, longitude')
    .single();

  if (stopErr) throw stopErr;

  // 2. Get next stop_order if not provided
  let order = stopOrder;
  if (order == null) {
    const { count } = await supabase
      .from('bus_stop_routes')
      .select('*', { count: 'exact', head: true })
      .eq('route_id', routeId);
    order = (count ?? 0) + 1;
  }

  // 3. Link stop to route
  const { data: junction, error: jErr } = await supabase
    .from('bus_stop_routes')
    .insert({ route_id: routeId, stop_id: stop.id, stop_order: order })
    .select('id, stop_order')
    .single();

  if (jErr) throw jErr;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'CREATE', entity: 'BusStop', entityId: stop.id,
    details: `Added stop "${stopName}" (order ${order}) to route ${routeId}`,
  });

  return { junction_id: junction.id, stop_order: junction.stop_order, ...stop };
}

// ── Assign an existing stop to a route ───────────────────────────────────────

export async function linkExistingStop(routeId, { stopId, stopOrder }, admin) {
  let order = stopOrder;
  if (order == null) {
    const { count } = await supabase
      .from('bus_stop_routes')
      .select('*', { count: 'exact', head: true })
      .eq('route_id', routeId);
    order = (count ?? 0) + 1;
  }

  const { data: junction, error } = await supabase
    .from('bus_stop_routes')
    .insert({ route_id: routeId, stop_id: stopId, stop_order: order })
    .select('id, stop_order')
    .single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error('Stop is already assigned to this route'), { statusCode: 409 });
    }
    throw error;
  }

  const { data: stop } = await supabase
    .from('bus_stops').select('id, stop_name, latitude, longitude').eq('id', stopId).single();

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Route', entityId: routeId,
    details: `Linked existing stop ${stopId} to route`,
  });

  return { junction_id: junction.id, stop_order: junction.stop_order, ...stop };
}

// ── Update stop order ─────────────────────────────────────────────────────────

export async function updateStopOrder(junctionId, stopOrder, admin) {
  const { data, error } = await supabase
    .from('bus_stop_routes')
    .update({ stop_order: stopOrder })
    .eq('id', junctionId)
    .select('id, stop_order, route_id, stop_id')
    .single();

  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'BusStop', entityId: junctionId,
    details: `Reordered stop to position ${stopOrder}`,
  });

  return data;
}

// ── Remove stop from route ────────────────────────────────────────────────────

export async function removeStopFromRoute(junctionId, admin) {
  const { data: junction } = await supabase
    .from('bus_stop_routes').select('route_id, stop_id, stop_order').eq('id', junctionId).single();

  const { error } = await supabase.from('bus_stop_routes').delete().eq('id', junctionId);
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'DELETE', entity: 'BusStop', entityId: junctionId,
    details: `Removed stop from route (order was ${junction?.stop_order})`,
  });
}

// ── List all stops (for existing-stop picker) ─────────────────────────────────

export async function getAllStops() {
  const { data, error } = await supabase
    .from('bus_stops')
    .select('id, stop_name, latitude, longitude')
    .order('stop_name');
  if (error) throw error;
  return data ?? [];
}
