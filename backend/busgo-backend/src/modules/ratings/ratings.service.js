import { supabase } from '../../config/supabase.js';

/**
 * Return all ratings submitted by the authenticated user.
 *
 * @param {string} userId
 * @returns {Array<object>}
 */
export async function getMyRatings(userId) {
  const { data, error } = await supabase
    .from('ratings')
    .select(`
      id, stars, tags, comment, created_at,
      trips ( id, boarded_at, bus_routes ( route_number, route_name ) ),
      buses ( id, bus_number, driver_name )
    `)
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}

/**
 * Submit a rating for a completed trip (one rating per trip enforced by DB unique constraint).
 *
 * @param {string} userId
 * @param {{ trip_id, bus_id, stars, tags, comment? }} dto
 * @returns {object} Created rating
 */
export async function createRating(userId, dto) {
  // Verify the trip belongs to the user and is completed
  const { data: trip } = await supabase
    .from('trips')
    .select('id, status')
    .eq('id', dto.trip_id)
    .eq('user_id', userId)
    .maybeSingle();

  if (!trip) {
    const err = new Error('Trip not found');
    err.statusCode = 404;
    err.code = 'TRIP_NOT_FOUND';
    throw err;
  }

  if (trip.status !== 'completed') {
    const err = new Error('You can only rate completed trips');
    err.statusCode = 409;
    err.code = 'TRIP_NOT_COMPLETED';
    throw err;
  }

  const { data, error } = await supabase
    .from('ratings')
    .insert({
      trip_id: dto.trip_id,
      user_id: userId,
      bus_id: dto.bus_id,
      stars: dto.stars,
      tags: dto.tags || [],
      comment: dto.comment || null,
    })
    .select()
    .single();

  if (error) {
    // Unique constraint violation — already rated
    if (error.code === '23505') {
      const err = new Error('You have already rated this trip');
      err.statusCode = 409;
      err.code = 'RATING_EXISTS';
      throw err;
    }
    throw error;
  }

  return data;
}

/**
 * Compute aggregate rating statistics for a bus.
 *
 * @param {string} busId
 * @returns {{ bus_id, total_ratings, average_stars, star_breakdown }}
 */
export async function getBusRatingStats(busId) {
  const { data, error } = await supabase
    .from('ratings')
    .select('stars')
    .eq('bus_id', busId);

  if (error) throw error;

  const total = data.length;
  const avg = total > 0
    ? +(data.reduce((s, r) => s + r.stars, 0) / total).toFixed(2)
    : null;

  const breakdown = { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 };
  data.forEach((r) => { breakdown[r.stars] = (breakdown[r.stars] || 0) + 1; });

  return { bus_id: busId, total_ratings: total, average_stars: avg, star_breakdown: breakdown };
}
