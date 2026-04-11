import { useState, useRef, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';
import {
  Bus, Users, AlertTriangle, ParkingSquare,
  Bell, Calendar, AlertCircle, Settings, UserPlus, UserCheck, X,
} from 'lucide-react';
import {
  fetchDashboardStats, fetchLiveMapBuses, fetchDashboardEmergencies,
  fetchNotifications, markNotificationRead, markAllNotificationsRead, deleteNotification,
  type DashboardStats,
} from '../services/dashboard.service';
import type { Bus as BusType, EmergencyAlert, Notification } from '../types';
import './Dashboard.css';

const priorityColors: Record<string, string> = {
  MEDICAL: '#e74c3c', ACCIDENT: '#e67e22', CRIMINAL: '#8b5cf6', BREAKDOWN: '#e74c3c',
};
const priorityBg: Record<string, string> = {
  MEDICAL: '#fef2f2', ACCIDENT: '#fef9f0', CRIMINAL: '#f5f3ff', BREAKDOWN: '#fef2f2',
};

function createBusIcon(passengers: number, capacity: number, status: string) {
  const ratio = passengers / capacity;
  let color = '#4caf50';
  if (status === 'Breakdown') color = '#e74c3c';
  else if (ratio > 0.8) color = '#e74c3c';
  else if (ratio > 0.5) color = '#f59e0b';
  return L.divIcon({
    className: 'custom-bus-marker',
    html: `<div style="background:${color};width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-size:10px;font-weight:700;border:2px solid #fff;box-shadow:0 2px 6px rgba(0,0,0,0.3);">${passengers}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 14],
  });
}

const notifIcons: Record<string, React.ReactNode> = {
  emergency: <AlertCircle size={16} />,
  system:    <Settings size={16} />,
  driver:    <UserPlus size={16} />,
  passenger: <UserCheck size={16} />,
};
const notifColors: Record<string, string> = {
  emergency: '#ef4444', system: '#3b82f6', driver: '#f59e0b', passenger: '#8b5cf6',
};

const defaultStats: DashboardStats = {
  activeBuses: 0, activeBusesChange: '—',
  passengersToday: 0, passengersChange: '—',
  pendingAlerts: 0, alertsNote: '—',
  standbyBuses: 0, standbyNote: '—',
  pendingDrivers: 0, totalFleet: 0,
};

export default function Dashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState<DashboardStats>(defaultStats);
  const [buses, setBuses] = useState<BusType[]>([]);
  const [alerts, setAlerts] = useState<EmergencyAlert[]>([]);
  const [notifList, setNotifList] = useState<Notification[]>([]);
  const [showNotifications, setShowNotifications] = useState(false);
  const [loading, setLoading] = useState(true);
  const notifRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    Promise.all([
      fetchDashboardStats(),
      fetchLiveMapBuses(),
      fetchDashboardEmergencies(),
      fetchNotifications(),
    ]).then(([s, b, a, n]) => {
      setStats(s);
      setBuses(b.filter((bus) => bus.lat && bus.lng));
      setAlerts(a);
      setNotifList(n);
    }).catch(console.error).finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (notifRef.current && !notifRef.current.contains(e.target as Node)) {
        setShowNotifications(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const activeAlerts = alerts.filter((a) => a.status !== 'RESOLVED');
  const unreadCount = notifList.filter((n) => !n.read).length;

  const markAllRead = async () => {
    await markAllNotificationsRead().catch(console.error);
    setNotifList((prev) => prev.map((n) => ({ ...n, read: true })));
  };

  const markRead = async (id: string) => {
    await markNotificationRead(id).catch(console.error);
    setNotifList((prev) => prev.map((n) => (n.id === id ? { ...n, read: true } : n)));
  };

  const dismissNotif = async (id: string) => {
    await deleteNotification(id).catch(console.error);
    setNotifList((prev) => prev.filter((n) => n.id !== id));
  };

  const today = new Date().toLocaleDateString('en-LK', {
    year: 'numeric', month: 'long', day: 'numeric',
  });

  if (loading) {
    return <div className="dashboard" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh', fontSize: '14px', color: '#6b7280' }}>Loading dashboard…</div>;
  }

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1>Dashboard</h1>
        <div className="dashboard-header-actions">
          <div className="dashboard-date"><Calendar size={16} />{today}</div>
          <div className="notif-wrapper" ref={notifRef}>
            <button className="dashboard-notification-btn" onClick={() => setShowNotifications(!showNotifications)}>
              <Bell size={20} />
              {unreadCount > 0 && <span className="notification-dot">{unreadCount}</span>}
            </button>
            {showNotifications && (
              <div className="notif-dropdown">
                <div className="notif-dropdown-header">
                  <h3>Notifications</h3>
                  <button className="notif-mark-all" onClick={markAllRead}>Mark all read</button>
                </div>
                <div className="notif-dropdown-list">
                  {notifList.length === 0 && <div className="notif-empty">No notifications</div>}
                  {notifList.map((notif) => (
                    <div
                      key={notif.id}
                      className={`notif-item ${notif.read ? 'read' : 'unread'}`}
                      onClick={() => markRead(notif.id)}
                    >
                      <div className="notif-item-icon" style={{ color: notifColors[notif.type], background: `${notifColors[notif.type]}15` }}>
                        {notifIcons[notif.type]}
                      </div>
                      <div className="notif-item-content">
                        <div className="notif-item-title">{notif.title}</div>
                        <div className="notif-item-msg">{notif.message}</div>
                        <div className="notif-item-time">{notif.time}</div>
                      </div>
                      <button className="notif-dismiss" onClick={(e) => { e.stopPropagation(); dismissNotif(notif.id); }}>
                        <X size={14} />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon stat-icon-blue"><Bus size={24} /></div>
          <div className="stat-info">
            <div className="stat-value blue">{stats.activeBuses}</div>
            <div className="stat-label">Active Buses</div>
            <div className="stat-change blue">{stats.activeBusesChange}</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon stat-icon-indigo"><Users size={24} /></div>
          <div className="stat-info">
            <div className="stat-value indigo">{stats.passengersToday.toLocaleString()}</div>
            <div className="stat-label">Passengers Today</div>
            <div className="stat-change indigo">{stats.passengersChange}</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon stat-icon-red"><AlertTriangle size={24} /></div>
          <div className="stat-info">
            <div className="stat-value red">{stats.pendingAlerts}</div>
            <div className="stat-label">Pending Alerts</div>
            <div className="stat-change red">{stats.alertsNote}</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon stat-icon-purple"><ParkingSquare size={24} /></div>
          <div className="stat-info">
            <div className="stat-value purple">{stats.standbyBuses}</div>
            <div className="stat-label">Standby Buses</div>
            <div className="stat-change gray">{stats.standbyNote}</div>
          </div>
        </div>
      </div>

      <div className="dashboard-grid">
        <div className="dashboard-card map-card">
          <div className="card-header">
            <h2>Live Fleet Map</h2>
            <Link to="/admin/fleet-map" className="card-link">View Full Map &rarr;</Link>
          </div>
          <div className="dashboard-map-container">
            <MapContainer
              center={[6.85, 79.95]}
              zoom={11}
              style={{ height: '100%', width: '100%', borderRadius: '10px' }}
              zoomControl={false}
              scrollWheelZoom={false}
            >
              <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" attribution='&copy; OpenStreetMap contributors' />
              {buses.map((bus) => (
                <Marker key={bus.id} position={[bus.lat!, bus.lng!]} icon={createBusIcon(bus.passengers, bus.capacity, bus.status)}>
                  <Popup>
                    <strong>{bus.id}</strong><br />
                    Driver: {bus.driver}<br />
                    Route: {bus.route}<br />
                    Passengers: {bus.passengers}/{bus.capacity}
                  </Popup>
                </Marker>
              ))}
            </MapContainer>
            {buses.length === 0 && (
              <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%,-50%)', fontSize: '13px', color: '#6b7280', pointerEvents: 'none' }}>
                No buses with GPS data
              </div>
            )}
            <div className="map-legend">
              <span className="legend-item"><span className="legend-dot green"></span> Low</span>
              <span className="legend-item"><span className="legend-dot yellow"></span> Moderate</span>
              <span className="legend-item"><span className="legend-dot red"></span> High</span>
            </div>
          </div>
        </div>

        <div className="dashboard-card alerts-card">
          <div className="card-header">
            <h2>Emergency Alerts</h2>
            <Link to="/admin/emergencies" className="card-link">View All ({activeAlerts.length}) &rarr;</Link>
          </div>
          <div className="alert-list">
            {activeAlerts.length === 0 && (
              <div style={{ padding: '24px', textAlign: 'center', color: '#6b7280', fontSize: '13px' }}>No active alerts</div>
            )}
            {activeAlerts.slice(0, 3).map((alert) => (
              <div
                key={alert.id}
                className="alert-item"
                style={{ borderLeftColor: priorityColors[alert.type], background: priorityBg[alert.type] }}
                onClick={() => navigate('/admin/emergencies')}
              >
                <div className="alert-item-top">
                  <span className="alert-priority-badge" style={{ background: priorityColors[alert.type] }}>
                    {alert.priority} {alert.type}
                  </span>
                  <span className="alert-bus-id">{alert.busId}</span>
                  <span className={`alert-status-badge ${alert.status.toLowerCase()}`}>{alert.status}</span>
                </div>
                <div className="alert-item-details">
                  Driver: {alert.driver} &middot; {alert.location} &middot; {alert.time}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
