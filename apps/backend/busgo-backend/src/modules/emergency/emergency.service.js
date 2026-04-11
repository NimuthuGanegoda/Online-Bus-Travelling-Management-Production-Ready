import { supabase } from '../../config/supabase.js';

/**
 * Return all emergency alerts submitted by the authenticated user.
 *
 * @param {string} userId
 * @returns {Array<object>}
 */
export async function getMyAlerts(userId) {
  const { data, error } = await supabase
    .from('emergency_alerts')
    .select('id, alert_type, description, latitude, longitude, status, created_at, updated_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

/**
 * Create a new emergency alert and send a notification to the user confirming receipt.
 *
 * @param {string} userId
 * @param {{ alert_type, description?, bus_id?, trip_id?, latitude?, longitude? }} dto
 * @returns {object} Created alert
 */
export async function createAlert(userId, dto) {
  const { data, error } = await supabase
    .from('emergency_alerts')
    .insert({
      user_id: userId,
      alert_type: dto.alert_type,
      description: dto.description || null,
      bus_id: dto.bus_id || null,
      trip_id: dto.trip_id || null,
      latitude: dto.latitude || null,
      longitude: dto.longitude || null,
      status: 'pending',
    })
    .select()
    .single();

  if (error) throw error;

  // Notify the user that the alert was received
  await supabase.from('notifications').insert({
    user_id: userId,
    category: 'emergency',
    title: '⚠️ Emergency Alert Sent',
    body: `Your ${dto.alert_type} emergency alert has been received and is being processed.`,
    meta: { alert_id: data.id, alert_type: dto.alert_type },
  });

  return data;
}

/**
 * Update the status of an emergency alert (admin/resolver action).
 *
 * @param {string} alertId
 * @param {string} userId  - Must own the alert OR be an admin (simplified: owner only here)
 * @param {'pending'|'acknowledged'|'resolved'} status
 * @returns {object} Updated alert
 */
export async function updateAlertStatus(alertId, userId, status) {
  const { data: existing } = await supabase
    .from('emergency_alerts')
    .select('id, user_id')
    .eq('id', alertId)
    .maybeSingle();

  if (!existing) {
    const err = new Error('Emergency alert not found');
    err.statusCode = 404;
    err.code = 'ALERT_NOT_FOUND';
    throw err;
  }

  // In production, replace this with an admin role check
  if (existing.user_id !== userId) {
    const err = new Error('Forbidden');
    err.statusCode = 403;
    err.code = 'FORBIDDEN';
    throw err;
  }

  const { data, error } = await supabase
    .from('emergency_alerts')
    .update({ status })
    .eq('id', alertId)
    .select()
    .single();

  if (error) throw error;
  return data;
}
