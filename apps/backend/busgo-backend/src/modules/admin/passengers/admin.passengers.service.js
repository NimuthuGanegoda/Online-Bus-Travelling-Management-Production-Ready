import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';
import { hashPassword } from '../../../utils/password.utils.js';

const USER_SELECT = `
  id, full_name, email, username, phone, nic,
  membership_type, is_active, created_at, updated_at
`;

export async function listPassengers({ status, search, page = 1, pageSize = 20 }) {
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  let query = supabase.from('users').select(`${USER_SELECT}, trips(id)`, { count: 'exact' });

  // Map UI status to DB field
  if (status === 'active')    query = query.eq('is_active', true);
  if (status === 'inactive' || status === 'suspended') query = query.eq('is_active', false);

  const { data, count, error } = await query.range(from, to).order('full_name');
  if (error) throw error;

  // Compute trips_today (count trips boarded today per user)
  const today = new Date().toISOString().slice(0, 10);
  const userIds = (data ?? []).map((u) => u.id);

  let tripsToday = {};
  if (userIds.length) {
    const { data: todayTrips } = await supabase
      .from('trips')
      .select('user_id')
      .in('user_id', userIds)
      .gte('boarded_at', `${today}T00:00:00Z`);
    (todayTrips ?? []).forEach((t) => {
      tripsToday[t.user_id] = (tripsToday[t.user_id] ?? 0) + 1;
    });
  }

  let result = (data ?? []).map((u) => ({
    ...u,
    total_trips:  u.trips?.length ?? 0,
    trips_today:  tripsToday[u.id] ?? 0,
    status:       u.is_active ? 'active' : 'suspended',
    trips: undefined, // remove raw trips array
  }));

  if (search) {
    const q = search.toLowerCase();
    result = result.filter((u) =>
      u.full_name?.toLowerCase().includes(q) ||
      u.email?.toLowerCase().includes(q) ||
      u.username?.toLowerCase().includes(q) ||
      u.nic?.toLowerCase().includes(q)
    );
  }

  return { data: result, total: count ?? 0, page, pageSize };
}

export async function createPassenger({ fullName, email, password, username, phone, nic }, admin) {
  if (!fullName || !email || !password) {
    throw Object.assign(new Error('full_name, email, and password are required'), { statusCode: 400 });
  }

  const passwordHash = await hashPassword(password);

  const { data, error } = await supabase
    .from('users')
    .insert({
      full_name:     fullName.trim(),
      email:         email.trim().toLowerCase(),
      password_hash: passwordHash,
      username:      username?.trim() || null,
      phone:         phone?.trim() || null,
      nic:           nic?.trim() || null,
      is_active:     true,
    })
    .select(USER_SELECT)
    .single();

  if (error) {
    if (error.code === '23505') {
      throw Object.assign(new Error('Email or username already exists'), { statusCode: 409 });
    }
    throw error;
  }

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'CREATE', entity: 'Passenger', entityId: data.id,
    details: `Created passenger account: ${fullName} (${email})`,
  });

  return data;
}

export async function setPassengerStatus(userId, active, admin) {
  const { data, error } = await supabase
    .from('users').update({ is_active: active }).eq('id', userId)
    .select(USER_SELECT).single();
  if (error) throw error;

  const action = active ? 'UPDATE' : 'SUSPEND';
  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action, entity: 'Passenger', entityId: userId,
    details: `Passenger ${active ? 'activated' : 'suspended'}: ${data.full_name}`,
  });

  return data;
}

export async function deletePassenger(userId, admin) {
  const { data: user } = await supabase.from('users').select('full_name, email').eq('id', userId).single();
  await supabase.from('users').delete().eq('id', userId);

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'DELETE', entity: 'Passenger', entityId: userId,
    details: `Deleted passenger account: ${user?.full_name} (${user?.email})`,
  });
}

export async function getPassengerById(userId) {
  const { data, error } = await supabase
    .from('users')
    .select(`${USER_SELECT}, trips ( id, status, fare_lkr, boarded_at )`)
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data;
}
