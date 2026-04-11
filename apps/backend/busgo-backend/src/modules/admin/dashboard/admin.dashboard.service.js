import { supabase } from '../../../config/supabase.js';

export async function getDashboardStats() {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  const [
    { count: activeBuses },
    { count: standbyBuses },
    { count: inRepairBuses },
    { count: totalBuses },
    { count: passengersToday },
    { count: pendingAlerts },
    { count: newAlerts },
    { count: pendingDrivers },
    { count: totalPassengers },
  ] = await Promise.all([
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'active'),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'standby'),
    supabase.from('buses').select('*', { count: 'exact', head: true }).eq('status', 'in_repair'),
    supabase.from('buses').select('*', { count: 'exact', head: true }),
    supabase.from('trips').select('user_id', { count: 'exact', head: true })
      .gte('boarded_at', `${today}T00:00:00Z`)
      .lte('boarded_at', `${today}T23:59:59Z`),
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true })
      .in('status', ['sent', 'acknowledged']),
    supabase.from('emergency_alerts').select('*', { count: 'exact', head: true })
      .eq('status', 'sent'),
    supabase.from('drivers').select('*', { count: 'exact', head: true })
      .eq('status', 'pending'),
    supabase.from('users').select('*', { count: 'exact', head: true }),
  ]);

  return {
    activeBuses:     activeBuses ?? 0,
    standbyBuses:    standbyBuses ?? 0,
    inRepairBuses:   inRepairBuses ?? 0,
    totalFleet:      totalBuses ?? 0,
    passengersToday: passengersToday ?? 0,
    totalPassengers: totalPassengers ?? 0,
    pendingAlerts:   pendingAlerts ?? 0,
    newAlerts:       newAlerts ?? 0,
    pendingDrivers:  pendingDrivers ?? 0,
  };
}

export async function getLiveMapBuses() {
  const { data, error } = await supabase
    .from('buses')
    .select(`
      id, bus_number, registration, status, current_lat, current_lng,
      heading, speed_kmh, crowd_level, last_location_update,
      driver_name,
      bus_routes ( route_number, route_name ),
      drivers   ( id, full_name, rating )
    `)
    .not('current_lat', 'is', null)
    .not('current_lng', 'is', null);

  if (error) throw error;
  return data ?? [];
}
