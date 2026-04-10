import { supabase } from '../../../config/supabase.js';

export async function getNotifications(adminId, { unreadOnly = false, page = 1, pageSize = 50 } = {}) {
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  let query = supabase
    .from('admin_notifications')
    .select('*', { count: 'exact' })
    .eq('admin_id', adminId);

  if (unreadOnly) query = query.eq('is_read', false);

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(from, to);

  if (error) throw error;
  return { data: data ?? [], total: count ?? 0, page, pageSize };
}

export async function markOneRead(adminId, notifId) {
  const { data, error } = await supabase
    .from('admin_notifications')
    .update({ is_read: true })
    .eq('id', notifId)
    .eq('admin_id', adminId)
    .select()
    .single();

  if (error) throw error;
  if (!data) throw Object.assign(new Error('Notification not found'), { status: 404 });
  return data;
}

export async function markAllRead(adminId) {
  const { error } = await supabase
    .from('admin_notifications')
    .update({ is_read: true })
    .eq('admin_id', adminId)
    .eq('is_read', false);

  if (error) throw error;
}

export async function deleteNotification(adminId, notifId) {
  const { data, error } = await supabase
    .from('admin_notifications')
    .delete()
    .eq('id', notifId)
    .eq('admin_id', adminId)
    .select()
    .single();

  if (error) throw error;
  if (!data) throw Object.assign(new Error('Notification not found'), { status: 404 });
}
