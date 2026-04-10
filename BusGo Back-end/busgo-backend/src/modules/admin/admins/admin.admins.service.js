import { supabase } from '../../../config/supabase.js';
import { hashPassword } from '../../../utils/password.utils.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

const ADMIN_SELECT = 'id, full_name, email, phone, role, status, last_login, created_at, updated_at';

export async function listAdmins({ status, search }) {
  let query = supabase.from('admins').select(ADMIN_SELECT);
  if (status) query = query.eq('status', status);

  const { data, error } = await query.order('full_name');
  if (error) throw error;

  let result = data ?? [];
  if (search) {
    const q = search.toLowerCase();
    result = result.filter((a) =>
      a.full_name?.toLowerCase().includes(q) ||
      a.email?.toLowerCase().includes(q)
    );
  }
  return result;
}

export async function getAdminById(id) {
  const { data, error } = await supabase
    .from('admins').select(ADMIN_SELECT).eq('id', id).single();
  if (error) throw error;
  return data;
}

export async function createAdmin(fields, requestingAdmin) {
  const password_hash = await hashPassword(fields.password);

  const { data, error } = await supabase.from('admins').insert({
    full_name:     fields.full_name,
    email:         fields.email.toLowerCase(),
    phone:         fields.phone ?? null,
    password_hash,
    role:          fields.role ?? 'admin',
    status:        'active',
  }).select(ADMIN_SELECT).single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error('Email already exists'), { statusCode: 409 });
    }
    throw error;
  }

  createAuditLog({
    adminId: requestingAdmin.id, adminEmail: requestingAdmin.email,
    action: 'CREATE', entity: 'Admin', entityId: data.id,
    details: `Created admin account: ${data.full_name} (${data.role})`,
  });

  return data;
}

export async function updateAdmin(id, fields, requestingAdmin) {
  const updates = {};
  if (fields.full_name !== undefined) updates.full_name = fields.full_name;
  if (fields.phone     !== undefined) updates.phone     = fields.phone;
  if (fields.role      !== undefined) updates.role      = fields.role;

  const { data, error } = await supabase
    .from('admins').update(updates).eq('id', id).select(ADMIN_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: requestingAdmin.id, adminEmail: requestingAdmin.email,
    action: 'UPDATE', entity: 'Admin', entityId: id,
    details: `Updated: ${JSON.stringify(updates)}`,
  });

  return data;
}

export async function toggleAdminStatus(id, requestingAdmin) {
  const { data: current } = await supabase.from('admins').select('status').eq('id', id).single();
  const newStatus = current?.status === 'active' ? 'inactive' : 'active';

  const { data, error } = await supabase
    .from('admins').update({ status: newStatus }).eq('id', id).select(ADMIN_SELECT).single();
  if (error) throw error;

  createAuditLog({
    adminId: requestingAdmin.id, adminEmail: requestingAdmin.email,
    action: 'UPDATE', entity: 'Admin', entityId: id,
    details: `Status toggled to: ${newStatus}`,
  });

  return data;
}

export async function deleteAdmin(id, requestingAdmin) {
  // Prevent self-deletion
  if (id === requestingAdmin.id) {
    throw Object.assign(new Error('Cannot delete your own account'), { statusCode: 400 });
  }

  const { data: admin } = await supabase.from('admins').select('full_name, email').eq('id', id).single();
  await supabase.from('admins').delete().eq('id', id);

  createAuditLog({
    adminId: requestingAdmin.id, adminEmail: requestingAdmin.email,
    action: 'DELETE', entity: 'Admin', entityId: id,
    details: `Deleted admin: ${admin?.full_name} (${admin?.email})`,
  });
}
