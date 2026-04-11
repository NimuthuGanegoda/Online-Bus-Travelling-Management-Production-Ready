import { v4 as uuidv4 } from 'uuid';
import { supabase } from '../../config/supabase.js';
import { CONSTANTS } from '../../config/constants.js';

/**
 * Fetch the current QR card for a user.
 * Regenerates the QR token if it has expired (TTL: 30 seconds).
 *
 * @param {string} userId
 * @returns {{ qr_token: string, qr_expires_at: string, user_id: string }}
 */
export async function getMyQrCard(userId) {
  const { data: user, error } = await supabase
    .from('users')
    .select('id, full_name, username, membership_type, qr_token, qr_expires_at, created_at')
    .eq('id', userId)
    .single();

  if (error) throw error;

  const now = new Date();
  const expiresAt = new Date(user.qr_expires_at);

  if (expiresAt <= now) {
    // Regenerate token
    const newToken = uuidv4();
    const newExpiry = new Date(now.getTime() + CONSTANTS.QR_TOKEN_EXPIRES_MS).toISOString();

    const { data: updated, error: updateErr } = await supabase
      .from('users')
      .update({ qr_token: newToken, qr_expires_at: newExpiry })
      .eq('id', userId)
      .select('qr_token, qr_expires_at')
      .single();

    if (updateErr) throw updateErr;

    return {
      user_id: user.id,
      full_name: user.full_name,
      username: user.username,
      membership_type: user.membership_type,
      member_since: user.created_at,
      qr_token: updated.qr_token,
      qr_expires_at: updated.qr_expires_at,
    };
  }

  return {
    user_id: user.id,
    full_name: user.full_name,
    username: user.username,
    membership_type: user.membership_type,
    member_since: user.created_at,
    qr_token: user.qr_token,
    qr_expires_at: user.qr_expires_at,
  };
}

/**
 * Process a QR scan-exit event:
 *  1. Find the ongoing trip for this user.
 *  2. Mark it as completed with alighted_at = now.
 *  3. Create a "rate your trip" notification.
 *
 * @param {string} userId
 * @param {{ alighting_stop_id?: string, fare_lkr?: number }} dto
 * @returns {{ trip_id: string, message: string }}
 */
export async function scanExit(userId, dto) {
  // Find the most recent ongoing trip
  const { data: trip, error: tripError } = await supabase
    .from('trips')
    .select('id, bus_id, route_id')
    .eq('user_id', userId)
    .eq('status', 'ongoing')
    .order('boarded_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (tripError) throw tripError;

  if (!trip) {
    const err = new Error('No ongoing trip found for this user');
    err.statusCode = 404;
    err.code = 'NO_ONGOING_TRIP';
    throw err;
  }

  const now = new Date().toISOString();

  const { error: updateErr } = await supabase
    .from('trips')
    .update({
      status: 'completed',
      alighted_at: now,
      alighting_stop_id: dto.alighting_stop_id || null,
      fare_lkr: dto.fare_lkr || null,
    })
    .eq('id', trip.id);

  if (updateErr) throw updateErr;

  // Create a rating-prompt notification
  await supabase.from('notifications').insert({
    user_id: userId,
    category: 'trip',
    title: 'How was your trip?',
    body: 'Please rate your recent bus journey.',
    meta: { trip_id: trip.id, bus_id: trip.bus_id },
  });

  return { trip_id: trip.id, message: 'Exit scanned. Please rate your trip.' };
}
