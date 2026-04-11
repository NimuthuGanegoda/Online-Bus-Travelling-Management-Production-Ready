import { supabase } from '../../../config/supabase.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

const ALERT_SELECT = `
  id, alert_type, priority, description,
  latitude, longitude, status, police_notified,
  created_at, updated_at,
  users   ( id, full_name, email, phone ),
  buses   ( id, bus_number, registration,
            bus_routes ( route_number, route_name ) ),
  trips   ( id )
`;

export async function listAlerts({ status, type, priority, search, page = 1, pageSize = 50 }) {
  const from = (page - 1) * pageSize;
  const to   = from + pageSize - 1;

  let query = supabase.from('emergency_alerts')
    .select(ALERT_SELECT, { count: 'exact' });

  if (status)   query = query.eq('status', status);
  if (type)     query = query.eq('alert_type', type.toLowerCase());
  if (priority) query = query.eq('priority', priority);

  const { data, count, error } = await query
    .order('created_at', { ascending: false })
    .range(from, to);
  if (error) throw error;

  let result = data ?? [];
  if (search) {
    const q = search.toLowerCase();
    result = result.filter((a) =>
      a.description?.toLowerCase().includes(q) ||
      a.buses?.bus_number?.toLowerCase().includes(q) ||
      a.buses?.bus_routes?.route_number?.toLowerCase().includes(q) ||
      a.users?.full_name?.toLowerCase().includes(q)
    );
  }

  return { data: result, total: count ?? 0, page, pageSize };
}

export async function getAlertById(id) {
  const { data, error } = await supabase
    .from('emergency_alerts').select(ALERT_SELECT).eq('id', id).single();
  if (error) throw error;
  return data;
}

export async function getAlertStats() {
  const [total, sent, acknowledged, resolved] = await Promise.all([
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true }),
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true }).eq('status', 'sent'),
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true }).eq('status', 'acknowledged'),
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true }).eq('status', 'resolved'),
  ]);
  return {
    total:        total.count        ?? 0,
    new:          sent.count         ?? 0,
    responded:    acknowledged.count ?? 0,
    resolved:     resolved.count     ?? 0,
  };
}

export async function updateAlertStatus(id, status, admin) {
  const validStatuses = ['sent', 'acknowledged', 'resolved'];
  if (!validStatuses.includes(status)) {
    throw Object.assign(new Error(`Invalid status: ${status}`), { statusCode: 400 });
  }

  const { data, error } = await supabase
    .from('emergency_alerts')
    .update({ status })
    .eq('id', id)
    .select(ALERT_SELECT)
    .single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'RESOLVE', entity: 'EmergencyAlert', entityId: id,
    details: `Alert status updated to: ${status} for bus ${data.buses?.bus_number ?? 'unknown'}`,
  });

  // Notify admin panel
  await supabase.from('admin_notifications').insert({
    type: 'emergency',
    title: `Alert ${status === 'resolved' ? 'Resolved' : 'Updated'}`,
    message: `Emergency alert #${id.slice(-6)} marked as ${status}`,
  });

  return data;
}

export async function updatePoliceNotified(id, policeNotified, admin) {
  const { data, error } = await supabase
    .from('emergency_alerts')
    .update({ police_notified: policeNotified })
    .eq('id', id)
    .select(ALERT_SELECT)
    .single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'UPDATE', entity: 'EmergencyAlert', entityId: id,
    details: `Police notified set to: ${policeNotified}`,
  });

  return data;
}

export async function deployStandbyBus(alertId, standbyBusId, admin) {
  // Mark the standby bus as active
  const { data: bus } = await supabase
    .from('buses')
    .update({ bus_status: 'active' })
    .eq('id', standbyBusId)
    .select('id, bus_number, registration')
    .single();

  // Update alert to acknowledged
  const { data: alert, error } = await supabase
    .from('emergency_alerts')
    .update({ status: 'acknowledged' })
    .eq('id', alertId)
    .select(ALERT_SELECT)
    .single();
  if (error) throw error;

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'DEPLOY', entity: 'EmergencyAlert', entityId: alertId,
    details: `Deployed standby bus ${bus?.bus_number ?? standbyBusId} to emergency ${alertId}`,
  });

  await supabase.from('admin_notifications').insert({
    type: 'emergency',
    title: 'Standby Bus Deployed',
    message: `Bus ${bus?.bus_number} deployed to emergency alert #${alertId.slice(-6)}`,
  });

  return { alert, deployed_bus: bus };
}
