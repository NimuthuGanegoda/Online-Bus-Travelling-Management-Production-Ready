import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  MapPin, Bus, CheckCircle, Eye, Calendar, AlertTriangle,
  ShieldAlert, Siren, Wrench, Activity, Clock, Filter, ChevronRight, X,
} from 'lucide-react';
import { fetchEmergencies, updateEmergencyStatus, deployBusToEmergency } from '../services/emergency.service';
import type { EmergencyAlert } from '../types';
import './Emergencies.css';

const typeConfig: Record<string, { icon: React.ReactNode; color: string; bg: string }> = {
  MEDICAL: { icon: <Activity size={20} />, color: '#ef4444', bg: 'rgba(239, 68, 68, 0.1)' },
  ACCIDENT: { icon: <AlertTriangle size={20} />, color: '#f59e0b', bg: 'rgba(245, 158, 11, 0.1)' },
  CRIMINAL: { icon: <ShieldAlert size={20} />, color: '#8b5cf6', bg: 'rgba(139, 92, 246, 0.1)' },
  BREAKDOWN: { icon: <Wrench size={20} />, color: '#f97316', bg: 'rgba(249, 115, 22, 0.1)' },
};

const statusConfig: Record<string, { label: string; color: string; bg: string }> = {
  NEW: { label: 'New', color: '#ef4444', bg: 'rgba(239, 68, 68, 0.1)' },
  RESPONDED: { label: 'Responded', color: '#3b82f6', bg: 'rgba(59, 130, 246, 0.1)' },
  RESOLVED: { label: 'Resolved', color: '#6b7280', bg: 'rgba(107, 114, 128, 0.08)' },
};

export default function Emergencies() {
  const navigate = useNavigate();
  const [alerts, setAlerts] = useState<EmergencyAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('all');
  const [typeFilter, setTypeFilter] = useState('all');
  const [detailAlert, setDetailAlert] = useState<EmergencyAlert | null>(null);
  const [deployedMsg, setDeployedMsg] = useState<string | null>(null);

  useEffect(() => {
    const load = (initial = false) => {
      if (initial) setLoading(true);
      fetchEmergencies({ page_size: 100 })
        .then(setAlerts)
        .catch(console.error)
        .finally(() => { if (initial) setLoading(false); });
    };

    load(true);
    // Poll every 10 s so driver-submitted alerts appear without manual refresh
    const interval = setInterval(() => load(false), 10_000);
    return () => clearInterval(interval);
  }, []);

  const totalCount = alerts.length;
  const newCount = alerts.filter((a) => a.status === 'NEW').length;
  const respondedCount = alerts.filter((a) => a.status === 'RESPONDED').length;
  const resolvedCount = alerts.filter((a) => a.status === 'RESOLVED').length;

  const filtered = alerts.filter((a) => {
    if (statusFilter !== 'all' && a.status !== statusFilter) return false;
    if (typeFilter !== 'all' && a.type !== typeFilter) return false;
    return true;
  });

  const handleViewOnMap = (_alert: EmergencyAlert) => {
    navigate('/admin/fleet-map');
  };

  const handleDeployBus = async (alert: EmergencyAlert) => {
    try {
      const updated = await deployBusToEmergency(alert.id);
      setAlerts((prev) => prev.map((a) => (a.id === alert.id ? updated : a)));
      setDeployedMsg(`Standby bus deployed to ${alert.location} for ${alert.title}`);
      setTimeout(() => setDeployedMsg(null), 4000);
    } catch {
      setDeployedMsg('Failed to deploy bus. Please try again.');
      setTimeout(() => setDeployedMsg(null), 4000);
    }
  };

  const handleResolve = async (alert: EmergencyAlert) => {
    try {
      const updated = await updateEmergencyStatus(alert.id, 'resolved');
      setAlerts((prev) => prev.map((a) => (a.id === alert.id ? updated : a)));
    } catch (err) {
      console.error(err);
    }
  };

  const handleViewDetails = (alert: EmergencyAlert) => {
    setDetailAlert(alert);
  };

  if (loading) {
    return <div className="emergencies-page" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh', fontSize: '14px', color: '#6b7280' }}>Loading alerts…</div>;
  }

  return (
    <div className="emergencies-page">
      {/* Success toast */}
      {deployedMsg && (
        <div className="em-toast">
          <CheckCircle size={16} />
          <span>{deployedMsg}</span>
          <button onClick={() => setDeployedMsg(null)}><X size={14} /></button>
        </div>
      )}

      {/* Detail Modal */}
      {detailAlert && (
        <div className="em-modal-overlay" onClick={() => setDetailAlert(null)}>
          <div className="em-modal" onClick={(e) => e.stopPropagation()}>
            <div className="em-modal-header">
              <h3>Alert Details</h3>
              <button className="em-modal-close" onClick={() => setDetailAlert(null)}>
                <X size={20} />
              </button>
            </div>
            <div className="em-modal-body">
              <div className="em-modal-row">
                <span className="em-modal-label">Alert ID</span>
                <span>{detailAlert.id}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Type</span>
                <span style={{ color: typeConfig[detailAlert.type]?.color }}>{detailAlert.type}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Priority</span>
                <span>{detailAlert.priority}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Title</span>
                <span>{detailAlert.title}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Bus</span>
                <span>{detailAlert.busId}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Driver</span>
                <span>{detailAlert.driver}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Location</span>
                <span>{detailAlert.location}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Route</span>
                <span>Route {detailAlert.route}</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Time</span>
                <span>{detailAlert.time} ({detailAlert.timeAgo})</span>
              </div>
              <div className="em-modal-row">
                <span className="em-modal-label">Status</span>
                <span style={{ color: statusConfig[detailAlert.status]?.color, fontWeight: 600 }}>
                  {detailAlert.status}
                </span>
              </div>
              {detailAlert.gps && (
                <div className="em-modal-row">
                  <span className="em-modal-label">GPS</span>
                  <span>{detailAlert.gps.lat}, {detailAlert.gps.lng}</span>
                </div>
              )}
              {detailAlert.policeNotified && (
                <div className="em-modal-row">
                  <span className="em-modal-label">Police</span>
                  <span style={{ color: '#ef4444', fontWeight: 600 }}>Notified</span>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="em-header">
        <div className="em-header-left">
          <div className="em-header-icon">
            <Siren size={24} />
          </div>
          <div>
            <h1 className="em-title">Emergency Alerts</h1>
            <p className="em-subtitle">Monitor and respond to active incidents in real-time</p>
          </div>
        </div>
        <div className="em-header-right">
          <span className="em-live-badge">
            <span className="em-live-dot"></span>
            LIVE
          </span>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="em-stats">
        <div className="em-stat-card">
          <div className="em-stat-icon total"><AlertTriangle size={20} /></div>
          <div className="em-stat-info">
            <span className="em-stat-value">{totalCount}</span>
            <span className="em-stat-label">Total Alerts</span>
          </div>
        </div>
        <div className="em-stat-card">
          <div className="em-stat-icon critical"><Activity size={20} /></div>
          <div className="em-stat-info">
            <span className="em-stat-value">{newCount}</span>
            <span className="em-stat-label">Active / New</span>
          </div>
        </div>
        <div className="em-stat-card">
          <div className="em-stat-icon responded"><Clock size={20} /></div>
          <div className="em-stat-info">
            <span className="em-stat-value">{respondedCount}</span>
            <span className="em-stat-label">Responded</span>
          </div>
        </div>
        <div className="em-stat-card">
          <div className="em-stat-icon resolved"><CheckCircle size={20} /></div>
          <div className="em-stat-info">
            <span className="em-stat-value">{resolvedCount}</span>
            <span className="em-stat-label">Resolved</span>
          </div>
        </div>
      </div>

      {/* Filters Bar */}
      <div className="em-filters-bar">
        <div className="em-filters-left">
          <Filter size={16} className="em-filter-icon" />
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="em-filter-select"
          >
            <option value="all">All Status</option>
            <option value="NEW">New</option>
            <option value="RESPONDED">Responded</option>
            <option value="RESOLVED">Resolved</option>
          </select>
          <select
            value={typeFilter}
            onChange={(e) => setTypeFilter(e.target.value)}
            className="em-filter-select"
          >
            <option value="all">All Types</option>
            <option value="MEDICAL">Medical</option>
            <option value="ACCIDENT">Accident</option>
            <option value="CRIMINAL">Criminal</option>
            <option value="BREAKDOWN">Breakdown</option>
          </select>
        </div>
        <button className="em-today-btn">
          <Calendar size={15} />
          <span>Today</span>
        </button>
      </div>

      {/* Alert Cards */}
      <div className="em-alerts-list">
        {filtered.map((alert) => {
          const type = typeConfig[alert.type];
          const status = statusConfig[alert.status];
          return (
            <div
              key={alert.id}
              className={`em-alert-card ${alert.status.toLowerCase()}`}
              style={{ '--accent': type.color } as React.CSSProperties}
            >
              <div className="em-alert-main">
                <div
                  className="em-alert-type-icon"
                  style={{ color: type.color, background: type.bg }}
                >
                  {type.icon}
                </div>

                <div className="em-alert-content">
                  <div className="em-alert-row-top">
                    <span className="em-alert-id">{alert.id}</span>
                    <span
                      className="em-alert-priority"
                      style={{ color: type.color, background: type.bg }}
                    >
                      {alert.priority}
                    </span>
                    <span className="em-alert-type-label" style={{ color: type.color }}>
                      {alert.type}
                    </span>
                    <span
                      className="em-alert-status-badge"
                      style={{ color: status.color, background: status.bg }}
                    >
                      {status.label}
                    </span>
                  </div>

                  <h3 className="em-alert-title">{alert.title}</h3>

                  <div className="em-alert-meta">
                    <span className="em-alert-meta-item"><Bus size={13} /> {alert.busId}</span>
                    <span className="em-alert-meta-divider">|</span>
                    <span className="em-alert-meta-item">Driver: {alert.driver}</span>
                    <span className="em-alert-meta-divider">|</span>
                    <span className="em-alert-meta-item"><MapPin size={13} /> {alert.location}</span>
                    <span className="em-alert-meta-divider">|</span>
                    <span className="em-alert-meta-item">Route {alert.route}</span>
                  </div>

                  <div className="em-alert-actions">
                    <button className="em-action-btn primary" onClick={() => handleViewOnMap(alert)}>
                      <MapPin size={14} /> View on Map
                    </button>
                    {alert.status === 'NEW' && (alert.type === 'BREAKDOWN' ? (
                      <button className="em-action-btn warning" onClick={() => handleDeployBus(alert)}>
                        <Bus size={14} /> Deploy Standby
                      </button>
                    ) : alert.type !== 'CRIMINAL' ? (
                      <button className="em-action-btn warning" onClick={() => handleDeployBus(alert)}>
                        <Bus size={14} /> Deploy Bus
                      </button>
                    ) : null)}
                    {alert.status !== 'RESOLVED' && (
                      <button className="em-action-btn success" onClick={() => handleResolve(alert)}>
                        <CheckCircle size={14} /> Resolve
                      </button>
                    )}
                    {alert.status === 'RESOLVED' && (
                      <button className="em-action-btn secondary" onClick={() => handleViewDetails(alert)}>
                        <Eye size={14} /> View Details
                      </button>
                    )}
                  </div>
                </div>

                <div className="em-alert-aside">
                  <div className="em-alert-time">{alert.time}</div>
                  <div className="em-alert-timeago">{alert.timeAgo}</div>
                  {alert.gps && (
                    <div className="em-alert-gps">
                      {alert.gps.lat.toFixed(4)}, {alert.gps.lng.toFixed(4)}
                    </div>
                  )}
                  {alert.policeNotified && (
                    <span className="em-police-badge">
                      <Siren size={11} /> Police Notified
                    </span>
                  )}
                  <button className="em-details-arrow" onClick={() => handleViewDetails(alert)}>
                    <ChevronRight size={18} />
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
