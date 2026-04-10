import { supabase } from '../../../config/supabase.js';

export async function listAuditLogs({ action, entity, adminEmail, search, page = 1, pageSize = 50 }) {
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  let query = supabase
    .from('admin_audit_logs')
    .select('*', { count: 'exact' });

  if (action)     query = query.eq('action', action);
  if (entity)     query = query.eq('entity', entity);
  if (adminEmail) query = query.ilike('admin_email', `%${adminEmail}%`);

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(from, to);
  if (error) throw error;

  let result = data ?? [];
  if (search) {
    const q = search.toLowerCase();
    result = result.filter((l) =>
      l.admin_email?.toLowerCase().includes(q) ||
      l.details?.toLowerCase().includes(q) ||
      l.entity?.toLowerCase().includes(q) ||
      l.entity_id?.toLowerCase().includes(q)
    );
  }

  return { data: result, total: count ?? 0, page, pageSize };
}
