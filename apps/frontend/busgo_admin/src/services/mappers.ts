import type { Bus, Driver, EmergencyAlert, Passenger, Admin, Notification, AuditLog } from '../types';

// ── Bus ───────────────────────────────────────────────────────
const busStatusMap: Record<string, Bus['status']> = {
  active:    'Active',
  breakdown: 'Breakdown',
  standby:   'Standby',
  in_repair: 'In Repair',
  recalled:  'Standby',
  inactive:  'Standby',
};

const crowdToPassengers: Record<string, number> = {
  low: 15, medium: 30, high: 42, full: 50,
};

export function mapBus(b: any): Bus {
  const status = busStatusMap[b.status ?? b.bus_status] ?? 'Active';
  const passengers = b.passenger_count ?? crowdToPassengers[b.crowd_level] ?? 0;
  const capacity = b.capacity ?? 50;

  return {
    _uuid:        b.id,                  // real UUID for API calls
    id:           b.bus_number ?? b.id,  // display ID shown in table
    routeId:      b.bus_routes?.id ?? b.route_id ?? undefined,
    routeColor:   b.bus_routes?.color ?? undefined,
    driverId:     b.drivers?.id ?? b.driver_id ?? undefined,
    registration: b.registration ?? '—',
    route:        Number(b.bus_routes?.route_number ?? b.route_number ?? 0),
    driver:       b.drivers?.full_name ?? b.driver_name ?? '—',
    passengers,
    capacity,
    status,
    speed:        b.speed_kmh ?? 0,
    lat:          b.current_lat ?? undefined,
    lng:          b.current_lng ?? undefined,
    nextStop:     b.next_stop ?? undefined,
    eta:          b.eta_minutes ?? undefined,
    lastUpdated:  b.last_location_update
      ? new Date(b.last_location_update).toLocaleTimeString('en-LK', { hour: '2-digit', minute: '2-digit' })
      : undefined,
  };
}

// ── Emergency ─────────────────────────────────────────────────
const alertTypeMap: Record<string, EmergencyAlert['type']> = {
  medical:    'MEDICAL',
  criminal:   'CRIMINAL',
  breakdown:  'BREAKDOWN',
  harassment: 'ACCIDENT',
  accident:   'ACCIDENT',
  other:      'ACCIDENT',
};

const alertStatusMap: Record<string, EmergencyAlert['status']> = {
  pending:      'NEW',
  acknowledged: 'RESPONDED',
  resolved:     'RESOLVED',
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1)   return 'Just now';
  if (mins < 60)  return `${mins} min ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24)   return `${hrs} hour${hrs > 1 ? 's' : ''} ago`;
  return new Date(dateStr).toLocaleDateString();
}

export function mapEmergency(a: any): EmergencyAlert {
  const busNumber = a.buses?.bus_number ?? a.bus_id ?? '—';
  const routeNumber = Number(a.buses?.bus_routes?.route_number ?? a.route_number ?? 0);
  // Driver name: prefer linked drivers row (driver app), fall back to denormalised bus field
  const driverName = a.drivers?.full_name ?? a.buses?.driver_name ?? a.driver_name ?? '—';

  return {
    id:       a.id,
    priority: (a.priority as EmergencyAlert['priority']) ?? 'P3',
    type:     alertTypeMap[a.alert_type] ?? 'ACCIDENT',
    title:    a.description ?? a.alert_type ?? 'Emergency',
    busId:    busNumber ? `Bus #${busNumber}` : '—',
    driver:   driverName,
    location: a.location ?? (a.latitude ? `${Number(a.latitude).toFixed(4)}, ${Number(a.longitude).toFixed(4)}` : 'Unknown'),
    route:    routeNumber,
    time:     a.created_at
      ? new Date(a.created_at).toLocaleTimeString('en-LK', { hour: '2-digit', minute: '2-digit' })
      : '—',
    timeAgo:  a.created_at ? timeAgo(a.created_at) : '—',
    status:   alertStatusMap[a.status] ?? 'NEW',
    gps:      a.latitude && a.longitude
      ? { lat: Number(a.latitude), lng: Number(a.longitude) }
      : undefined,
    policeNotified: a.police_notified ?? false,
  };
}

// ── Driver ────────────────────────────────────────────────────
const driverStatusMap: Record<string, Driver['status']> = {
  active:   'Active',
  inactive: 'Inactive',
  pending:  'Pending',
};

export function mapDriver(d: any): Driver & { _uuid: string } {
  return {
    _uuid:         d.id,                // real UUID for API calls
    id:            d.driver_code ?? d.id, // display ID shown in table
    name:          d.full_name,
    rating:        Number(d.rating ?? 0),
    email:         d.email,
    phone:         d.phone ?? '—',
    route:         d.bus_routes?.route_number ? Number(d.bus_routes.route_number) : null,
    routeId:       d.bus_routes?.id ?? d.route_id ?? undefined,
    status:        driverStatusMap[d.status] ?? 'Inactive',
    pendingReview: d.pending_review ?? false,
  };
}

// ── Passenger ─────────────────────────────────────────────────
export function mapPassenger(p: any): Passenger {
  const statusRaw = p.status ?? (p.is_active ? 'active' : 'suspended');
  const statusMap: Record<string, Passenger['status']> = {
    active:    'Active',
    suspended: 'Suspended',
    inactive:  'Inactive',
  };

  return {
    id:             p.id,
    name:           p.full_name,
    email:          p.email,
    phone:          p.phone ?? '—',
    nic:            p.nic ?? '—',
    status:         statusMap[statusRaw] ?? 'Active',
    tripsToday:     p.trips_today ?? 0,
    totalTrips:     p.total_trips ?? (p.trips?.length ?? 0),
    registeredDate: p.created_at ? p.created_at.slice(0, 10) : '—',
  };
}

// ── Admin ─────────────────────────────────────────────────────
const roleMap: Record<string, Admin['role']> = {
  super_admin: 'Super Admin',
  admin:       'Admin',
  moderator:   'Moderator',
};

export function mapAdmin(a: any): Admin {
  return {
    id:        a.id,
    name:      a.full_name,
    email:     a.email,
    phone:     a.phone ?? '—',
    role:      roleMap[a.role] ?? 'Moderator',
    status:    a.status === 'active' ? 'Active' : 'Inactive',
    lastLogin: a.last_login
      ? new Date(a.last_login).toLocaleString('en-LK', {
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit',
        })
      : 'Never',
  };
}

// ── Notification ─────────────────────────────────────────────
export function mapNotification(n: any): Notification {
  return {
    id:      n.id,
    type:    n.type as Notification['type'],
    title:   n.title,
    message: n.message ?? '',
    time:    n.created_at ? timeAgo(n.created_at) : '—',
    read:    n.is_read ?? false,
  };
}

// ── AuditLog ─────────────────────────────────────────────────
export function mapAuditLog(l: any): AuditLog {
  return {
    id:        l.id,
    timestamp: l.created_at
      ? new Date(l.created_at).toLocaleString('en-LK', {
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit', second: '2-digit',
        })
      : '—',
    admin:     l.admin_email ?? '—',
    action:    l.action as AuditLog['action'],
    entity:    l.entity ?? '—',
    entityId:  l.entity_id ?? '—',
    details:   l.details ?? '—',
    ipAddress: l.ip_address ?? '—',
  };
}
