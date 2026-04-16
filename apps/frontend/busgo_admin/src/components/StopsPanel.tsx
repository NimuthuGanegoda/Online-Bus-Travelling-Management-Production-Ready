import { useState, useEffect, useCallback } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMapEvents, CircleMarker, Tooltip } from 'react-leaflet';
import { X, Plus, Trash2, MapPin, ChevronUp, ChevronDown, Map, Keyboard } from 'lucide-react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  fetchRouteStops, addStop, removeStop, reorderStop,
  type BusStop,
} from '../services/stops.service';
import type { Route } from '../services/routes.service';
import './StopsPanel.css';

// Fix Leaflet default marker icon broken by Vite's asset pipeline
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl:       'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl:     'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

interface Props {
  route: Route;
  onClose: () => void;
}

type InputMode = 'manual' | 'map';

// Inner component that captures map clicks
function MapClickHandler({
  onPick,
}: {
  onPick: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onPick(+e.latlng.lat.toFixed(6), +e.latlng.lng.toFixed(6));
    },
  });
  return null;
}

export default function StopsPanel({ route, onClose }: Props) {
  const [stops, setStops]       = useState<BusStop[]>([]);
  const [loading, setLoading]   = useState(true);
  const [showAdd, setShowAdd]   = useState(false);
  const [inputMode, setInputMode] = useState<InputMode>('manual');

  // Form state
  const [stopName, setStopName] = useState('');
  const [latStr, setLatStr]     = useState('');
  const [lngStr, setLngStr]     = useState('');
  const [pinned, setPinned]     = useState<[number, number] | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [saving, setSaving]     = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchRouteStops(route.id);
      setStops(data.sort((a, b) => a.stop_order - b.stop_order));
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [route.id]);

  useEffect(() => { load(); }, [load]);

  const handleMapPick = (lat: number, lng: number) => {
    setPinned([lat, lng]);
    setLatStr(String(lat));
    setLngStr(String(lng));
  };

  const resetForm = () => {
    setStopName('');
    setLatStr('');
    setLngStr('');
    setPinned(null);
    setFormError(null);
    setInputMode('manual');
    setShowAdd(false);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);

    if (!stopName.trim())           { setFormError('Stop name is required'); return; }
    if (isNaN(lat) || isNaN(lng))   { setFormError('Valid coordinates are required'); return; }
    if (lat < -90  || lat > 90)     { setFormError('Latitude must be between -90 and 90'); return; }
    if (lng < -180 || lng > 180)    { setFormError('Longitude must be between -180 and 180'); return; }

    setFormError(null);
    setSaving(true);
    try {
      const created = await addStop({
        route_id:  route.id,
        stop_name: stopName.trim(),
        latitude:  lat,
        longitude: lng,
      });
      setStops((prev) => [...prev, created].sort((a, b) => a.stop_order - b.stop_order));
      resetForm();
    } catch (err: any) {
      setFormError(err?.response?.data?.message ?? err?.message ?? 'Failed to add stop');
    } finally {
      setSaving(false);
    }
  };

  const handleMove = async (index: number, direction: 'up' | 'down') => {
    const swapIdx = direction === 'up' ? index - 1 : index + 1;
    if (swapIdx < 0 || swapIdx >= stops.length) return;

    const a = stops[index];
    const b = stops[swapIdx];

    // Optimistic update
    const updated = [...stops];
    updated[index] = { ...a, stop_order: b.stop_order };
    updated[swapIdx] = { ...b, stop_order: a.stop_order };
    updated.sort((x, y) => x.stop_order - y.stop_order);
    setStops(updated);

    try {
      await Promise.all([
        reorderStop(a.junction_id, b.stop_order),
        reorderStop(b.junction_id, a.stop_order),
      ]);
    } catch {
      // Roll back on failure
      setStops(stops);
    }
  };

  const handleRemove = async (junctionId: string, name: string) => {
    if (!confirm(`Remove "${name}" from this route?`)) return;
    try {
      await removeStop(junctionId);
      setStops((prev) => prev.filter((s) => s.junction_id !== junctionId));
    } catch (err: any) {
      alert(err?.response?.data?.message ?? 'Failed to remove stop');
    }
  };

  // Centre map on existing stops or default to Colombo
  const mapCenter: [number, number] =
    stops.length > 0
      ? [stops[0].latitude, stops[0].longitude]
      : [6.9271, 79.8612];

  return (
    <div className="stops-overlay" onClick={onClose}>
      <div className="stops-panel" onClick={(e) => e.stopPropagation()}>

        {/* ── Header ── */}
        <div className="stops-panel-header">
          <div className="stops-panel-title">
            <MapPin size={18} style={{ color: route.color }} />
            <div>
              <div className="stops-panel-route">Route {route.route_number}</div>
              <div className="stops-panel-name">{route.route_name} — Bus Stops</div>
            </div>
          </div>
          <div className="stops-panel-header-actions">
            {!showAdd && (
              <button className="stops-add-btn" onClick={() => setShowAdd(true)}>
                <Plus size={15} /> Add Stop
              </button>
            )}
            <button className="stops-close-btn" onClick={onClose}><X size={20} /></button>
          </div>
        </div>

        {/* ── Add Stop Form ── */}
        {showAdd && (
          <div className="stops-add-form">
            <div className="stops-input-tabs">
              <button
                type="button"
                className={`stops-input-tab ${inputMode === 'manual' ? 'active' : ''}`}
                onClick={() => setInputMode('manual')}
              >
                <Keyboard size={14} /> Enter Manually
              </button>
              <button
                type="button"
                className={`stops-input-tab ${inputMode === 'map' ? 'active' : ''}`}
                onClick={() => setInputMode('map')}
              >
                <Map size={14} /> Pick on Map
              </button>
            </div>

            <form onSubmit={handleSave}>
              <div className="stops-form-field">
                <label>Stop Name <span className="req">*</span></label>
                <input
                  type="text"
                  className="stops-input"
                  placeholder="e.g. Pettah Bus Stand"
                  value={stopName}
                  onChange={(e) => setStopName(e.target.value)}
                  required
                />
              </div>

              {inputMode === 'manual' ? (
                <div className="stops-coords-row">
                  <div className="stops-form-field">
                    <label>Latitude <span className="req">*</span></label>
                    <input
                      type="number"
                      step="any"
                      className="stops-input"
                      placeholder="6.9271"
                      value={latStr}
                      onChange={(e) => setLatStr(e.target.value)}
                    />
                  </div>
                  <div className="stops-form-field">
                    <label>Longitude <span className="req">*</span></label>
                    <input
                      type="number"
                      step="any"
                      className="stops-input"
                      placeholder="79.8612"
                      value={lngStr}
                      onChange={(e) => setLngStr(e.target.value)}
                    />
                  </div>
                </div>
              ) : (
                <div className="stops-map-area">
                  <p className="stops-map-hint">
                    Click anywhere on the map to pin the stop location, then fill in the name above.
                  </p>
                  <div className="stops-map-container">
                    <MapContainer
                      center={mapCenter}
                      zoom={13}
                      style={{ height: '100%', width: '100%' }}
                    >
                      <TileLayer
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        attribution="© OpenStreetMap contributors"
                      />
                      <MapClickHandler onPick={handleMapPick} />

                      {/* Existing stops */}
                      {stops.map((s) => (
                        <CircleMarker
                          key={s.junction_id}
                          center={[s.latitude, s.longitude]}
                          radius={7}
                          pathOptions={{ color: route.color, fillColor: route.color, fillOpacity: 0.85 }}
                        >
                          <Tooltip permanent={false}>{s.stop_order}. {s.stop_name}</Tooltip>
                        </CircleMarker>
                      ))}

                      {/* New pin */}
                      {pinned && (
                        <Marker position={pinned}>
                          <Popup>New stop location</Popup>
                        </Marker>
                      )}
                    </MapContainer>
                  </div>
                  {pinned && (
                    <div className="stops-map-coords">
                      <MapPin size={13} />
                      {pinned[0]}, {pinned[1]}
                    </div>
                  )}
                </div>
              )}

              {formError && <p className="stops-form-error">{formError}</p>}

              <div className="stops-form-actions">
                <button type="button" className="stops-form-btn cancel" onClick={resetForm}>
                  Cancel
                </button>
                <button type="submit" className="stops-form-btn save" disabled={saving}>
                  {saving ? 'Saving…' : 'Add Stop'}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* ── Stop List ── */}
        <div className="stops-list-area">
          {loading ? (
            <div className="stops-empty">Loading stops…</div>
          ) : stops.length === 0 ? (
            <div className="stops-empty">
              <MapPin size={32} style={{ opacity: 0.2, marginBottom: 8 }} />
              <div>No stops added yet</div>
              <div style={{ fontSize: 12, color: '#9ca3af', marginTop: 4 }}>
                Click "Add Stop" to add the first stop
              </div>
            </div>
          ) : (
            <div className="stops-list">
              {stops.map((stop, idx) => (
                <div key={stop.junction_id} className="stop-item">
                  <div className="stop-order-badge" style={{ background: route.color }}>
                    {idx + 1}
                  </div>
                  <div className="stop-reorder-btns">
                    <button
                      className="stop-reorder-btn"
                      onClick={() => handleMove(idx, 'up')}
                      disabled={idx === 0}
                      title="Move up"
                    >
                      <ChevronUp size={13} />
                    </button>
                    <button
                      className="stop-reorder-btn"
                      onClick={() => handleMove(idx, 'down')}
                      disabled={idx === stops.length - 1}
                      title="Move down"
                    >
                      <ChevronDown size={13} />
                    </button>
                  </div>
                  <div className="stop-info">
                    <div className="stop-name">{stop.stop_name}</div>
                    <div className="stop-coords">
                      {stop.latitude.toFixed(5)}, {stop.longitude.toFixed(5)}
                    </div>
                  </div>
                  <button
                    className="stop-remove-btn"
                    onClick={() => handleRemove(stop.junction_id, stop.stop_name)}
                    title="Remove from route"
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="stops-panel-footer">
          {stops.length} stop{stops.length !== 1 ? 's' : ''} on this route
        </div>
      </div>
    </div>
  );
}
