import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

const BUS_SELECT = `
  id, bus_number, registration, status, speed_kmh,
  current_lat, current_lng, heading, crowd_level,
  last_location_update, driver_name, driver_phone, driver_id,
  bus_routes ( id, route_number, route_name ),
  drivers    ( id, driver_code, full_name, rating, phone )
`;

export async function getAllBuses({ status, routeId, search }) {
  let query = supabase.from('buses').select(BUS_SELECT);

  if (status)  query = query.eq('status', status.toLowerCase());
  if (routeId) query = query.eq('route_id', routeId);

  const { data, error } = await query.order('bus_number');
  if (error) throw error;

  let result = data ?? [];
  if (search) {
    const q = search.toLowerCase();
    result = result.filter((b) =>
      b.bus_number?.toLowerCase().includes(q) ||
      b.registration?.toLowerCase().includes(q) ||
      String(b.bus_routes?.route_number ?? '').includes(q) ||
      b.drivers?.full_name?.toLowerCase().includes(q) ||
      b.driver_name?.toLowerCase().includes(q)
    );
  }
  return result;
}

export async function registerBus({ busNumber, routeId, registration, driverName, driverPhone }, admin) {
  if (!busNumber || !routeId || !driverName) {
    throw Object.assign(new Error('bus_number, route_id and driver_name are required'), { statusCode: 400 });
  }

  const { data, error } = await supabase
    .from('buses')
    .insert({
      bus_number:   busNumber.trim().toUpperCase(),
      route_id:     routeId,
      registration: registration?.trim() || null,
      driver_name:  driverName.trim(),
      driver_phone: driverPhone?.trim() || null,
      status:       'standby',
      crowd_level:  'low',
    })
    .select(BUS_SELECT)
    .single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error(`Bus number '${busNumber}' already exists`), { statusCode: 409 });
    }
    throw error;
  }

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'CREATE', entity: 'Bus', entityId: data.id,
    details: `Registered new bus: ${busNumber}`,
  });

  return data;
}

export async function updateBusAssignment(busId, { driverId, routeId, registration }, admin) {
  const updates = {};
  if (driverId      !== undefined) updates.driver_id   = driverId ?? null;
  if (routeId       !== undefined) updates.route_id    = routeId ?? null;
  if (registration  !== undefined) updates.registration = registration;

  if (Object.keys(updates).length === 0) return getBusById(busId);

  // If assigning a driver, also copy their name to driver_name for backward compat
  if (driverId) {
    const { data: drv } = await supabase
      .from('drivers').select('full_name, phone').eq('id', driverId).single();
    if (drv) {
      updates.driver_name  = drv.full_name;
      updates.driver_phone = drv.phone;
    }
  }

  const { data, error } = await supabase
    .from('buses').update(updates).eq('id', busId).select(BUS_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Bus', entityId: busId,
    details: `Updated bus assignment: ${JSON.stringify(updates)}`,
  });

  return data;
}

export async function updateBusStatus(busId, status, admin) {
  const validStatuses = ['active', 'standby', 'in_repair', 'breakdown', 'recalled', 'inactive'];
  if (!validStatuses.includes(status)) {
    throw Object.assign(new Error(`Invalid status: ${status}`), { statusCode: 400 });
  }

  const { data, error } = await supabase
    .from('buses').update({ status }).eq('id', busId).select(BUS_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Bus', entityId: busId,
    details: `Status changed to: ${status}`,
  });

  return data;
}

export async function getBusById(busId) {
  const { data, error } = await supabase
    .from('buses').select(BUS_SELECT).eq('id', busId).single();
  if (error) throw error;
  return data;
}

export async function getFleetStats() {
  const [total, active, standby, inRepair, breakdown] = await Promise.all([
    supabase.from('buses').select('*', { count: 'exact', head: true }),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'active'),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'standby'),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'in_repair'),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'breakdown'),
  ]);
  return {
    total:     total.count     ?? 0,
    active:    active.count    ?? 0,
    standby:   standby.count   ?? 0,
    in_repair: inRepair.count  ?? 0,
    breakdown: breakdown.count ?? 0,
  };
}
