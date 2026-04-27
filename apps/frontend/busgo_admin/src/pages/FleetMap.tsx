import { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Polyline, CircleMarker, Tooltip, useMap } from 'react-leaflet';
import L from 'leaflet';
import { useLocation } from 'react-router-dom';
import { RefreshCw, Crosshair, Bus, User, X, Phone, Mail, Star, AlertCircle } from 'lucide-react';
import { fetchAllBuses, fetchStandbyBuses, updateBusStatus } from '../services/buses.service';
import { fetchAdminRoutes } from '../services/routes.service';
import { fetchRouteStops, type BusStop } from '../services/stops.service';
import { fetchRoadPolyline } from '../services/routing.service';
import { fetchDriverById } from '../services/drivers.service';
import type { Bus as BusType, Driver, StandbyBus } from '../types';
import './FleetMap.css';

// Colombo Fort — fallback when a bus has no GPS fix yet
const COLOMBO_DEFAULT = { lat: 6.9271, lng: 79.8612 };

const FALLBACK_COLORS = ['#1565C0', '#2E7D32', '#7B1FA2', '#E65100', '#00838F', '#AD1457', '#F57F17'];

interface RouteLayer {
  routeId: string;
  routeNumber: number;
  color: string;
  stops: BusStop[];
  polyline: [number, number][];
}

function withFallbackCoords(bus: BusType): BusType & { lat: number; lng: number } {
  return {
    ...bus,
    lat: bus.lat ?? COLOMBO_DEFAULT.lat,
    lng: bus.lng ?? COLOMBO_DEFAULT.lng,
  };
}

function MapFlyTo({ bus }: { bus: BusType | null }) {
  const map = useMap();
  useEffect(() => {
    if (bus?.lat && bus?.lng) {
      map.flyTo([bus.lat, bus.lng], 15, { duration: 1.2 });
    }
  }, [bus, map]);
  return null;
}

function createBusIcon(passengers: number, capacity: number, status: string, selected: boolean) {
  const ratio = passengers / capacity;
  let color = '#4caf50';
  if (status === 'Breakdown') color = '#e74c3c';
  else if (ratio > 0.8) color = '#e74c3c';
  else if (ratio > 0.5) color = '#f59e0b';

  const size = selected ? 40 : 32;
  const border = selected ? '3px solid #FFD700' : '3px solid #fff';

  return L.divIcon({
    className: 'custom-bus-marker',
    html: `<div style="background:${color};width:${size}px;height:${size}px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-size:11px;font-weight:700;border:${border};box-shadow:0 2px 8px rgba(0,0,0,0.35);">${passengers}</div>`,
    iconSize: [size, size],
    iconAnchor: [size / 2, size / 2],
  });
}

export default function FleetMap() {
  const location = useLocation();
  const trackBusId = (location.state as any)?.trackBusId as string | undefined;

  const [allBuses, setAllBuses] = useState<BusType[]>([]);
  const [selectedBus, setSelectedBus] = useState<BusType | null>(null);
  const [routeLayers, setRouteLayers] = useState<RouteLayer[]>([]);
  const [loadingBuses, setLoadingBuses] = useState(true);
  const [busesError, setBusesError] = useState<string | null>(null);
  const [loadingRoutes, setLoadingRoutes] = useState(false);
  const [statusFilter, setStatusFilter] = useState('all');
  const [crowdFilter, setCrowdFilter] = useState('all');
  const [driverModal, setDriverModal] = useState<Driver | null>(null);
  const [driverLoading, setDriverLoading] = useState(false);
  const [driverError, setDriverError] = useState<string | null>(null);
  const [driverModalMessage, setDriverModalMessage] =
    useState<{ name: string; message: string } | null>(null);

  // Deploy Standby modal
  const [deployOpen, setDeployOpen] = useState(false);
  const [standbyBuses, setStandbyBuses] = useState<StandbyBus[]>([]);
  const [deployLoading, setDeployLoading] = useState(false);
  const [deployingId, setDeployingId] = useState<string | null>(null);
  const [deployError, setDeployError] = useState<string | null>(null);

  // Load buses and all routes in parallel, then build road polylines for every route
  useEffect(() => {
    setLoadingBuses(true);
    setLoadingRoutes(true);
    setBusesError(null);

    Promise.all([fetchAllBuses(), fetchAdminRoutes(true)])
      .then(async ([buses, routes]) => {
        const normalised = buses.map(withFallbackCoords);
        setAllBuses(normalised);
        setLoadingBuses(false);

        // Auto-select from Track button or default to first bus
        const target = trackBusId
          ? normalised.find((b) => b.id === trackBusId) ?? normalised[0]
          : normalised[0];
        if (target) setSelectedBus(target);

        // Build a layer for EVERY route (not just ones with buses)
        const layers = await Promise.all(
          routes.map(async (route, idx) => {
            const color = route.color ?? FALLBACK_COLORS[idx % FALLBACK_COLORS.length];
            try {
              const stops = (await fetchRouteStops(route.id)).sort(
                (a, b) => a.stop_order - b.stop_order,
              );
              const polyline = stops.length >= 2 ? await fetchRoadPolyline(stops) : [];
              return {
                routeId: route.id,
                routeNumber: Number(route.route_number),
                color,
                stops,
                polyline,
              } as RouteLayer;
            } catch {
              return {
                routeId: route.id,
                routeNumber: Number(route.route_number),
                color,
                stops: [],
                polyline: [],
              } as RouteLayer;
            }
          }),
        );

        setRouteLayers(layers);
        setLoadingRoutes(false);
      })
      .catch((err) => {
        console.error(err);
        setBusesError(
          err?.response?.data?.message ??
            'Failed to load fleet data. Check your network and that the backend is running.',
        );
        setLoadingBuses(false);
        setLoadingRoutes(false);
      });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const getCrowdLevel = (bus: BusType) => {
    const ratio = bus.passengers / bus.capacity;
    if (ratio > 0.8) return 'high';
    if (ratio > 0.5) return 'moderate';
    return 'low';
  };

  const filteredBuses = allBuses.filter((bus) => {
    if (statusFilter !== 'all' && bus.status !== statusFilter) return false;
    if (crowdFilter !== 'all' && getCrowdLevel(bus) !== crowdFilter) return false;
    return true;
  });

  const handleViewDriver = async () => {
    if (!selectedBus) return;
    setDriverError(null);

    // Fallback: bus has no linked driver record (just a denormalised driver_name).
    if (!selectedBus.driverId) {
      setDriverModalMessage({
        name: selectedBus.driver,
        message:
          'No driver profile linked to this bus yet. ' +
          'Assign a driver from the Fleet Management → Edit form to see full details.',
      });
      return;
    }
    setDriverLoading(true);
    try {
      const driver = await fetchDriverById(selectedBus.driverId);
      setDriverModal(driver);
    } catch (err: any) {
      setDriverError(err?.response?.data?.message ?? 'Failed to load driver profile');
    } finally {
      setDriverLoading(false);
    }
  };

  const handleOpenDeploy = async () => {
    setDeployOpen(true);
    setDeployError(null);
    setDeployLoading(true);
    try {
      const list = await fetchStandbyBuses();
      setStandbyBuses(list);
    } catch (err: any) {
      setDeployError(err?.response?.data?.message ?? 'Failed to load standby buses');
    } finally {
      setDeployLoading(false);
    }
  };

  const handleDeploy = async (busUuid: string) => {
    setDeployingId(busUuid);
    setDeployError(null);
    try {
      await updateBusStatus(busUuid, 'active');
      // Refresh the fleet so the deployed bus appears on the map
      const buses = await fetchAllBuses();
      setAllBuses(buses.map(withFallbackCoords));
      // Remove from standby list
      setStandbyBuses((prev) => prev.filter((b) => b._uuid !== busUuid));
    } catch (err: any) {
      setDeployError(err?.response?.data?.message ?? 'Failed to deploy bus');
    } finally {
      setDeployingId(null);
    }
  };

  // Colour for a given bus based on its route layer
  const routeColorFor = (bus: BusType) =>
    routeLayers.find((r) => r.routeId === bus.routeId)?.color ?? '#1565C0';

  const crowdPercent = selectedBus
    ? Math.round((selectedBus.passengers / selectedBus.capacity) * 100)
    : 0;
  const crowdLabel = selectedBus ? getCrowdLevel(selectedBus) : 'low';

  return (
    <div className="fleet-map-page">
      <div className="fleet-map-toolbar">
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="map-filter">
          <option value="all">All Status</option>
          <option value="Active">Active</option>
          <option value="Standby">Standby</option>
          <option value="In Repair">In Repair</option>
          <option value="Breakdown">Breakdown</option>
        </select>
        <select value={crowdFilter} onChange={(e) => setCrowdFilter(e.target.value)} className="map-filter">
          <option value="all">Crowd Level</option>
          <option value="low">Low</option>
          <option value="moderate">Moderate</option>
          <option value="high">High</option>
        </select>
        <div className="map-toolbar-right">
          {loadingRoutes && (
            <span style={{ fontSize: 12, color: '#6b7280', marginRight: 8 }}>Loading routes…</span>
          )}
          <button className="map-btn" onClick={() => window.location.reload()}>
            <RefreshCw size={16} /> Refresh
          </button>
          <button
            className="map-btn primary"
            onClick={() => {
              if (selectedBus) setSelectedBus({ ...selectedBus });
            }}
          >
            <Crosshair size={16} /> Center Map
          </button>
        </div>
      </div>

      <div className="fleet-map-content">
        <div className="fleet-map-container">
          <MapContainer
            center={[6.85, 79.95]}
            zoom={12}
            style={{ height: '100%', width: '100%' }}
            zoomControl={false}
          >
            <TileLayer
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              attribution='&copy; OpenStreetMap contributors'
            />
            <MapFlyTo bus={selectedBus} />

            {/* ── All route polylines (road-snapped, uniform style) ── */}
            {routeLayers.map((layer) =>
              layer.polyline.length >= 2 ? (
                <Polyline
                  key={layer.routeId}
                  positions={layer.polyline}
                  pathOptions={{
                    color: layer.color,
                    weight: 5,
                    opacity: 0.85,
                  }}
                />
              ) : null,
            )}

            {/* ── Stop markers for every route ── */}
            {routeLayers.map((layer) =>
              layer.stops.map((stop, idx) => (
                <CircleMarker
                  key={stop.junction_id}
                  center={[stop.latitude, stop.longitude]}
                  radius={idx === 0 || idx === layer.stops.length - 1 ? 8 : 4}
                  pathOptions={{
                    color: '#fff',
                    fillColor:
                      idx === 0
                        ? '#2E7D32'
                        : idx === layer.stops.length - 1
                        ? '#C62828'
                        : layer.color,
                    fillOpacity: 1,
                    weight: 2,
                  }}
                >
                  <Tooltip>
                    <strong>Route {layer.routeNumber}</strong><br />
                    {stop.stop_order}. {stop.stop_name}
                  </Tooltip>
                </CircleMarker>
              )),
            )}

            {/* ── Bus markers ── */}
            {filteredBuses.map((bus) => (
              <Marker
                key={bus.id}
                position={[bus.lat!, bus.lng!]}
                icon={createBusIcon(
                  bus.passengers,
                  bus.capacity,
                  bus.status,
                  selectedBus?.id === bus.id,
                )}
                eventHandlers={{ click: () => setSelectedBus(bus) }}
              >
                <Popup>
                  <strong>{bus.id}</strong> — Route {bus.route}<br />
                  Driver: {bus.driver}<br />
                  {bus.passengers}/{bus.capacity} passengers
                </Popup>
              </Marker>
            ))}
          </MapContainer>

          {/* Route colour legend */}
          {routeLayers.length > 0 && (
            <div className="map-crowd-legend" style={{ gap: 10 }}>
              <span className="legend-title">ROUTES</span>
              {routeLayers.map((r) => (
                <span key={r.routeId} className="legend-item">
                  <span className="legend-dot" style={{ background: r.color }} />
                  {r.routeNumber}
                </span>
              ))}
            </div>
          )}
        </div>

        <div className="bus-detail-panel">
          {loadingBuses ? (
            <div style={{ padding: '32px', textAlign: 'center', color: '#6b7280', fontSize: '13px' }}>
              Loading buses…
            </div>
          ) : busesError ? (
            <div style={{ padding: '24px', textAlign: 'center' }}>
              <AlertCircle size={28} color="#ef4444" style={{ marginBottom: 8 }} />
              <div style={{ color: '#ef4444', fontSize: 13, fontWeight: 600, marginBottom: 4 }}>
                Couldn't load fleet
              </div>
              <div style={{ color: '#6b7280', fontSize: 12, marginBottom: 12 }}>{busesError}</div>
              <button
                className="map-btn"
                onClick={() => window.location.reload()}
                style={{ margin: '0 auto' }}
              >
                <RefreshCw size={14} /> Retry
              </button>
            </div>
          ) : allBuses.length === 0 ? (
            <div style={{ padding: '24px', textAlign: 'center' }}>
              <Bus size={32} color="#9ca3af" style={{ marginBottom: 8 }} />
              <div style={{ color: '#374151', fontSize: 13, fontWeight: 600, marginBottom: 4 }}>
                No buses in the fleet yet
              </div>
              <div style={{ color: '#6b7280', fontSize: 12 }}>
                Register a bus from <strong>Fleet Management</strong> to see it here.
              </div>
            </div>
          ) : !selectedBus ? (
            <div style={{ padding: '32px', textAlign: 'center', color: '#6b7280', fontSize: '13px' }}>
              Click a bus marker to view details
            </div>
          ) : (
            <>
              <div className="bus-detail-header">
                <h2>{selectedBus.id} — Selected</h2>
                <p>Route {selectedBus.route} · Last updated {selectedBus.lastUpdated ?? '—'}</p>
              </div>

              <div className="bus-detail-rows">
                <div className="detail-row">
                  <span className="detail-label">BUS ID</span>
                  <span className="detail-value">{selectedBus.id}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">ROUTE</span>
                  <span className="detail-value" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <span style={{
                      width: 12, height: 12, borderRadius: 2,
                      background: routeColorFor(selectedBus), display: 'inline-block',
                    }} />
                    Route {selectedBus.route}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">DRIVER</span>
                  <span className="detail-value">{selectedBus.driver}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">SPEED</span>
                  <span className="detail-value">{selectedBus.speed ?? 0} km/h</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">STATUS</span>
                  <span className={`detail-status ${selectedBus.status.toLowerCase().replace(' ', '-')}`}>
                    <span className="status-indicator" />
                    {selectedBus.status}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">PASSENGERS</span>
                  <span className="detail-value">{selectedBus.passengers} / {selectedBus.capacity}</span>
                </div>
                <div className="passenger-bar-wrap">
                  <div className="passenger-bar">
                    <div className={`passenger-bar-fill ${crowdLabel}`} style={{ width: `${crowdPercent}%` }} />
                  </div>
                  <span className={`crowd-label ${crowdLabel}`}>
                    {crowdLabel.charAt(0).toUpperCase() + crowdLabel.slice(1)} — {crowdPercent}%
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">NEXT STOP</span>
                  <span className="detail-value bold">{selectedBus.nextStop || 'N/A'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-label">ETA</span>
                  <span className="detail-value bold">{selectedBus.eta ? `${selectedBus.eta} minutes` : 'N/A'}</span>
                </div>
              </div>
            </>
          )}

          <div className="bus-detail-actions">
            <button className="detail-action-btn primary" onClick={handleOpenDeploy}>
              <Bus size={16} /> Deploy Standby Bus
            </button>
            <button
              className="detail-action-btn secondary"
              onClick={handleViewDriver}
              disabled={driverLoading || !selectedBus}
            >
              <User size={16} />
              {driverLoading ? 'Loading…' : 'View Driver Profile'}
            </button>
            {driverError && (
              <p style={{ color: '#ef4444', fontSize: 12, margin: '4px 0 0' }}>{driverError}</p>
            )}
          </div>
        </div>
      </div>

      {/* ── No-driver fallback modal ── */}
      {driverModalMessage && (
        <div
          style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999,
          }}
          onClick={() => setDriverModalMessage(null)}
        >
          <div
            style={{
              background: '#fff', borderRadius: 16, width: 340, padding: 24,
              boxShadow: '0 20px 60px rgba(0,0,0,0.25)',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 8 }}>
              <User size={20} color="#1a6fa8" />
              <strong style={{ fontSize: 15, color: '#111827' }}>{driverModalMessage.name}</strong>
            </div>
            <p style={{ color: '#6b7280', fontSize: 13, lineHeight: 1.5, margin: '8px 0 16px' }}>
              {driverModalMessage.message}
            </p>
            <button
              className="map-btn primary"
              style={{ width: '100%' }}
              onClick={() => setDriverModalMessage(null)}
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* ── Deploy Standby Bus Modal ── */}
      {deployOpen && (
        <div
          style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999,
          }}
          onClick={() => setDeployOpen(false)}
        >
          <div
            style={{
              background: '#fff', borderRadius: 16, width: 380, maxHeight: '70vh',
              display: 'flex', flexDirection: 'column',
              boxShadow: '0 20px 60px rgba(0,0,0,0.25)', overflow: 'hidden',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <div style={{
              padding: '16px 20px', display: 'flex', alignItems: 'center',
              justifyContent: 'space-between', borderBottom: '1px solid #f3f4f6',
            }}>
              <strong style={{ fontSize: 15, color: '#111827' }}>Deploy Standby Bus</strong>
              <button
                onClick={() => setDeployOpen(false)}
                style={{
                  background: '#f3f4f6', border: 'none', borderRadius: 8,
                  padding: 4, cursor: 'pointer', display: 'flex',
                }}
              >
                <X size={16} />
              </button>
            </div>
            <div style={{ padding: 16, overflowY: 'auto', flex: 1 }}>
              {deployLoading ? (
                <div style={{ textAlign: 'center', color: '#6b7280', fontSize: 13, padding: 24 }}>
                  Loading standby buses…
                </div>
              ) : deployError ? (
                <div style={{ color: '#ef4444', fontSize: 13, padding: 12 }}>{deployError}</div>
              ) : standbyBuses.length === 0 ? (
                <div style={{ textAlign: 'center', padding: 24 }}>
                  <Bus size={28} color="#9ca3af" style={{ marginBottom: 8 }} />
                  <div style={{ color: '#374151', fontSize: 13, fontWeight: 600 }}>
                    No standby buses available
                  </div>
                  <div style={{ color: '#6b7280', fontSize: 12, marginTop: 4 }}>
                    Set a bus's status to <strong>Standby</strong> in Fleet Management first.
                  </div>
                </div>
              ) : (
                standbyBuses.map((b) => (
                  <div
                    key={b._uuid}
                    style={{
                      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                      padding: '10px 12px', border: '1px solid #e5e7eb', borderRadius: 10,
                      marginBottom: 8,
                    }}
                  >
                    <div>
                      <div style={{ fontSize: 13, fontWeight: 700, color: '#111827' }}>{b.id}</div>
                      <div style={{ fontSize: 11, color: '#6b7280' }}>{b.registration}</div>
                    </div>
                    <button
                      className="map-btn primary"
                      disabled={deployingId === b._uuid}
                      onClick={() => handleDeploy(b._uuid)}
                    >
                      {deployingId === b._uuid ? 'Deploying…' : 'Deploy'}
                    </button>
                  </div>
                ))
              )}
            </div>
          </div>
        </div>
      )}

      {/* ── Driver Profile Modal ── */}
      {driverModal && (
        <div
          style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9999,
          }}
          onClick={() => setDriverModal(null)}
        >
          <div
            style={{
              background: '#fff', borderRadius: 16, width: 360,
              boxShadow: '0 20px 60px rgba(0,0,0,0.25)', overflow: 'hidden',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div style={{ background: '#0f2942', padding: '20px 20px 16px', position: 'relative' }}>
              <button
                onClick={() => setDriverModal(null)}
                style={{
                  position: 'absolute', top: 14, right: 14,
                  background: 'rgba(255,255,255,0.15)', border: 'none', borderRadius: 8,
                  color: '#fff', cursor: 'pointer', padding: 4, display: 'flex',
                }}
              >
                <X size={18} />
              </button>
              <div style={{
                width: 56, height: 56, borderRadius: '50%', background: '#1a6fa8',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 22, fontWeight: 700, color: '#fff', marginBottom: 10,
              }}>
                {driverModal.name.charAt(0).toUpperCase()}
              </div>
              <div style={{ color: '#fff', fontSize: 17, fontWeight: 700 }}>{driverModal.name}</div>
              <div style={{ color: '#93c5fd', fontSize: 12, marginTop: 2 }}>
                {driverModal.id} · {driverModal.status}
              </div>
            </div>

            {/* Body */}
            <div style={{ padding: '16px 20px' }}>
              {[
                { icon: <Mail size={15} />, label: 'Email', value: driverModal.email },
                { icon: <Phone size={15} />, label: 'Phone', value: driverModal.phone },
                {
                  icon: <Star size={15} />, label: 'Rating',
                  value: `${driverModal.rating.toFixed(1)} / 5.0`,
                },
                {
                  icon: <Bus size={15} />, label: 'Assigned Route',
                  value: driverModal.route ? `Route ${driverModal.route}` : 'Unassigned',
                },
              ].map(({ icon, label, value }) => (
                <div key={label} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '10px 0', borderBottom: '1px solid #f3f4f6',
                }}>
                  <span style={{ color: '#6b7280' }}>{icon}</span>
                  <span style={{ color: '#9ca3af', fontSize: 12, width: 90 }}>{label}</span>
                  <span style={{ color: '#111827', fontSize: 13, fontWeight: 600 }}>{value}</span>
                </div>
              ))}

              {/* Status badge */}
              <div style={{ marginTop: 14, display: 'flex', justifyContent: 'center' }}>
                <span style={{
                  padding: '4px 14px', borderRadius: 20, fontSize: 12, fontWeight: 700,
                  background: driverModal.status === 'Active' ? '#dcfce7' : '#fee2e2',
                  color: driverModal.status === 'Active' ? '#15803d' : '#b91c1c',
                }}>
                  {driverModal.status}
                </span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
