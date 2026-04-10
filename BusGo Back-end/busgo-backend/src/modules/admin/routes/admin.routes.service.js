import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

const ROUTE_SELECT = 'id, route_number, route_name, origin, destination, color, is_active, created_at';

export async function getAllRoutes({ includeInactive = false } = {}) {
  let query = supabase.from('bus_routes').select(ROUTE_SELECT).order('route_number');
  if (!includeInactive) query = query.eq('is_active', true);
  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

export async function getRouteById(routeId) {
  const { data, error } = await supabase
    .from('bus_routes').select(ROUTE_SELECT).eq('id', routeId).single();
  if (error) throw error;
  return data;
}

export async function createRoute({ routeNumber, routeName, origin, destination, color }, admin) {
  if (!routeNumber || !routeName || !origin || !destination) {
    throw Object.assign(
      new Error('route_number, route_name, origin, and destination are required'),
      { statusCode: 400 },
    );
  }

  const { data, error } = await supabase
    .from('bus_routes')
    .insert({
      route_number: routeNumber.trim(),
      route_name:   routeName.trim(),
      origin:       origin.trim(),
      destination:  destination.trim(),
      color:        color ?? '#1565C0',
    })
    .select(ROUTE_SELECT)
    .single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error(`Route number '${routeNumber}' already exists`), { statusCode: 409 });
    }
    throw error;
  }

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'CREATE', entity: 'Route', entityId: data.id,
    details: `Created route: ${routeNumber} — ${routeName}`,
  });

  return data;
}

export async function updateRoute(routeId, { routeNumber, routeName, origin, destination, color }, admin) {
  const updates = {};
  if (routeNumber !== undefined) updates.route_number = routeNumber.trim();
  if (routeName   !== undefined) updates.route_name   = routeName.trim();
  if (origin      !== undefined) updates.origin       = origin.trim();
  if (destination !== undefined) updates.destination  = destination.trim();
  if (color       !== undefined) updates.color        = color;

  if (Object.keys(updates).length === 0) return getRouteById(routeId);

  const { data, error } = await supabase
    .from('bus_routes').update(updates).eq('id', routeId).select(ROUTE_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Route', entityId: routeId,
    details: `Updated route: ${JSON.stringify(updates)}`,
  });

  return data;
}

export async function toggleRouteStatus(routeId, admin) {
  const current = await getRouteById(routeId);
  const newStatus = !current.is_active;

  const { data, error } = await supabase
    .from('bus_routes').update({ is_active: newStatus }).eq('id', routeId).select(ROUTE_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Route', entityId: routeId,
    details: `Route ${newStatus ? 'activated' : 'deactivated'}`,
  });

  return data;
}

export async function deleteRoute(routeId, admin) {
  const { count } = await supabase
    .from('buses').select('*', { count: 'exact', head: true }).eq('route_id', routeId);
  if (count > 0) {
    throw Object.assign(
      new Error(`Cannot delete: ${count} bus(es) still assigned to this route`),
      { statusCode: 409 },
    );
  }

  const { error } = await supabase.from('bus_routes').delete().eq('id', routeId);
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'DELETE', entity: 'Route', entityId: routeId,
    details: 'Route deleted',
  });
}
