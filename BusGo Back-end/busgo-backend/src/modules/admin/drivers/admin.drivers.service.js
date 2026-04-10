import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

const DRIVER_SELECT = `
  id, driver_code, full_name, email, phone, rating,
  status, pending_review, created_at, updated_at,
  bus_routes ( id, route_number, route_name )
`;

function nextDriverCode(existing) {
  const nums = existing
    .map((d) => parseInt(d.driver_code?.replace('DRV-', '') ?? '0', 10))
    .filter(Boolean);
  const next = nums.length ? Math.max(...nums) + 1 : 1;
  return `DRV-${String(next).padStart(3, '0')}`;
}

export async function listDrivers({ status, routeId, search, pendingOnly }) {
  let query = supabase.from('drivers').select(DRIVER_SELECT);

  if (pendingOnly) query = query.eq('status', 'pending');
  else if (status) query = query.eq('status', status);
  if (routeId) query = query.eq('route_id', routeId);

  const { data, error } = await query.order('full_name');
  if (error) throw error;

  let result = data ?? [];
  if (search) {
    const q = search.toLowerCase();
    result = result.filter((d) =>
      d.full_name?.toLowerCase().includes(q) ||
      d.email?.toLowerCase().includes(q) ||
      d.driver_code?.toLowerCase().includes(q)
    );
  }
  return result;
}

export async function getDriverById(id) {
  const { data, error } = await supabase
    .from('drivers').select(DRIVER_SELECT).eq('id', id).single();
  if (error) throw error;
  return data;
}

export async function createDriver(fields, admin) {
  // Generate next driver code
  const { data: existing } = await supabase.from('drivers').select('driver_code');
  const driver_code = nextDriverCode(existing ?? []);

  const { data, error } = await supabase.from('drivers').insert({
    driver_code,
    full_name:      fields.full_name,
    email:          fields.email.toLowerCase(),
    phone:          fields.phone ?? null,
    route_id:       fields.route_id ?? null,
    status:         'pending',
    pending_review: true,
  }).select(DRIVER_SELECT).single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error('Email already exists'), { statusCode: 409 });
    }
    throw error;
  }

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'CREATE', entity: 'Driver', entityId: data.id,
    details: `Created driver: ${data.full_name} (${driver_code})`,
  });

  return data;
}

export async function updateDriver(id, fields, admin) {
  const updates = {};
  if (fields.full_name !== undefined) updates.full_name = fields.full_name;
  if (fields.email     !== undefined) updates.email     = fields.email.toLowerCase();
  if (fields.phone     !== undefined) updates.phone     = fields.phone;
  if (fields.route_id  !== undefined) updates.route_id  = fields.route_id ?? null;
  if (fields.rating    !== undefined) updates.rating    = fields.rating;

  const { data, error } = await supabase
    .from('drivers').update(updates).eq('id', id).select(DRIVER_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Driver', entityId: id,
    details: `Updated: ${JSON.stringify(updates)}`,
  });

  return data;
}

export async function approveDriver(id, admin) {
  const { data, error } = await supabase
    .from('drivers')
    .update({ status: 'active', pending_review: false, rating: 5.0 })
    .eq('id', id)
    .select(DRIVER_SELECT)
    .single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'APPROVE', entity: 'Driver', entityId: id,
    details: `Approved and activated driver: ${data.full_name}`,
  });

  // Create admin notification
  await supabase.from('admin_notifications').insert({
    type: 'driver', title: 'Driver Approved',
    message: `${data.full_name} (${data.driver_code}) approved and activated`,
  });

  return data;
}

export async function rejectDriver(id, admin) {
  const { data: driver } = await supabase.from('drivers').select('full_name, driver_code').eq('id', id).single();

  await supabase.from('drivers').delete().eq('id', id);

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'REJECT', entity: 'Driver', entityId: id,
    details: `Rejected driver application: ${driver?.full_name} (${driver?.driver_code})`,
  });
}

export async function setDriverStatus(id, status, admin) {
  const valid = ['active', 'inactive'];
  if (!valid.includes(status)) {
    throw Object.assign(new Error(`Invalid status: ${status}`), { statusCode: 400 });
  }

  const { data, error } = await supabase
    .from('drivers').update({ status }).eq('id', id).select(DRIVER_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'Driver', entityId: id,
    details: `Status set to: ${status}`,
  });

  return data;
}

export async function deleteDriver(id, admin) {
  const { data: driver } = await supabase.from('drivers').select('full_name, driver_code').eq('id', id).single();
  await supabase.from('drivers').delete().eq('id', id);

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'DELETE', entity: 'Driver', entityId: id,
    details: `Deleted driver: ${driver?.full_name} (${driver?.driver_code})`,
  });
}
