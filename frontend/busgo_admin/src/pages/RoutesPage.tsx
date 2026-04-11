import { useState, useEffect } from 'react';
import { Plus, Pencil, Trash2, ToggleLeft, ToggleRight, X, CheckCircle, Route, MapPin } from 'lucide-react';
import {
  fetchAdminRoutes, createRoute, updateRoute, toggleRouteStatus, deleteRoute,
  type Route as RouteType,
} from '../services/routes.service';
import StopsPanel from '../components/StopsPanel';
import './RoutesPage.css';

const BLANK_FORM = { route_number: '', route_name: '', origin: '', destination: '', color: '#1565C0' };

export default function RoutesPage() {
  const [routes, setRoutes] = useState<RouteType[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [editRoute, setEditRoute] = useState<RouteType | null>(null);
  const [form, setForm] = useState(BLANK_FORM);
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<RouteType | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [searchQ, setSearchQ] = useState('');
  const [stopsRoute, setStopsRoute] = useState<RouteType | null>(null);

  useEffect(() => {
    load();
  }, []);

  async function load() {
    try {
      const data = await fetchAdminRoutes(true);
      setRoutes(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  };

  const openAdd = () => {
    setEditRoute(null);
    setForm(BLANK_FORM);
    setFormError(null);
    setShowModal(true);
  };

  const openEdit = (r: RouteType) => {
    setEditRoute(r);
    setForm({
      route_number: r.route_number,
      route_name:   r.route_name,
      origin:       r.origin,
      destination:  r.destination,
      color:        r.color,
    });
    setFormError(null);
    setShowModal(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFormLoading(true);
    try {
      if (editRoute) {
        const updated = await updateRoute(editRoute.id, form);
        setRoutes((prev) => prev.map((r) => (r.id === editRoute.id ? updated : r)));
        showToast(`Route ${updated.route_number} updated`);
      } else {
        const created = await createRoute(form);
        setRoutes((prev) => [...prev, created]);
        showToast(`Route ${created.route_number} created`);
      }
      setShowModal(false);
    } catch (err: any) {
      setFormError(err?.response?.data?.message ?? err?.message ?? 'Failed to save route');
    } finally {
      setFormLoading(false);
    }
  };

  const handleToggle = async (r: RouteType) => {
    try {
      const updated = await toggleRouteStatus(r.id);
      setRoutes((prev) => prev.map((x) => (x.id === r.id ? updated : x)));
      showToast(`Route ${updated.route_number} ${updated.is_active ? 'activated' : 'deactivated'}`);
    } catch (err: any) {
      showToast(err?.response?.data?.message ?? 'Failed to toggle status');
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleteLoading(true);
    try {
      await deleteRoute(deleteTarget.id);
      setRoutes((prev) => prev.filter((r) => r.id !== deleteTarget.id));
      showToast(`Route ${deleteTarget.route_number} deleted`);
      setDeleteTarget(null);
    } catch (err: any) {
      showToast(err?.response?.data?.message ?? 'Failed to delete route');
      setDeleteTarget(null);
    } finally {
      setDeleteLoading(false);
    }
  };

  const filtered = routes.filter((r) => {
    if (!searchQ) return true;
    const q = searchQ.toLowerCase();
    return (
      r.route_number.toLowerCase().includes(q) ||
      r.route_name.toLowerCase().includes(q) ||
      r.origin.toLowerCase().includes(q) ||
      r.destination.toLowerCase().includes(q)
    );
  });

  const active   = routes.filter((r) => r.is_active).length;
  const inactive = routes.length - active;

  if (loading) {
    return (
      <div className="routes-page" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh', fontSize: '14px', color: '#6b7280' }}>
        Loading routes…
      </div>
    );
  }

  return (
    <div className="routes-page">
      {/* Toast */}
      {toast && (
        <div className="routes-toast">
          <CheckCircle size={16} />
          <span>{toast}</span>
          <button onClick={() => setToast(null)}><X size={14} /></button>
        </div>
      )}

      {/* Delete Confirm */}
      {deleteTarget && (
        <div className="routes-modal-overlay" onClick={() => setDeleteTarget(null)}>
          <div className="routes-modal routes-modal--confirm" onClick={(e) => e.stopPropagation()}>
            <div className="routes-modal-header">
              <h3>Delete Route</h3>
              <button className="routes-modal-close" onClick={() => setDeleteTarget(null)}><X size={20} /></button>
            </div>
            <div className="routes-modal-body">
              <p style={{ color: '#374151', marginBottom: '16px' }}>
                Are you sure you want to delete <strong>Route {deleteTarget.route_number} — {deleteTarget.route_name}</strong>?
                This cannot be undone.
              </p>
              <div className="routes-modal-actions">
                <button className="routes-modal-btn cancel" onClick={() => setDeleteTarget(null)}>Cancel</button>
                <button className="routes-modal-btn delete" onClick={handleDelete} disabled={deleteLoading}>
                  {deleteLoading ? 'Deleting…' : 'Delete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add / Edit Modal */}
      {showModal && (
        <div className="routes-modal-overlay" onClick={() => setShowModal(false)}>
          <div className="routes-modal" onClick={(e) => e.stopPropagation()}>
            <div className="routes-modal-header">
              <h3>{editRoute ? `Edit Route ${editRoute.route_number}` : 'Add New Route'}</h3>
              <button className="routes-modal-close" onClick={() => setShowModal(false)}><X size={20} /></button>
            </div>
            <form className="routes-modal-body" onSubmit={handleSubmit}>
              <div className="routes-form-row">
                <div className="routes-modal-field">
                  <label>Route Number <span className="req">*</span></label>
                  <input
                    type="text"
                    placeholder="e.g. 138"
                    className="routes-modal-input"
                    value={form.route_number}
                    onChange={(e) => setForm((f) => ({ ...f, route_number: e.target.value }))}
                    required
                  />
                </div>
                <div className="routes-modal-field">
                  <label>Color</label>
                  <div className="routes-color-row">
                    <input
                      type="color"
                      className="routes-color-picker"
                      value={form.color}
                      onChange={(e) => setForm((f) => ({ ...f, color: e.target.value }))}
                    />
                    <input
                      type="text"
                      className="routes-modal-input"
                      value={form.color}
                      onChange={(e) => setForm((f) => ({ ...f, color: e.target.value }))}
                      placeholder="#1565C0"
                    />
                  </div>
                </div>
              </div>

              <div className="routes-modal-field">
                <label>Route Name <span className="req">*</span></label>
                <input
                  type="text"
                  placeholder="e.g. Colombo — Kandy Express"
                  className="routes-modal-input"
                  value={form.route_name}
                  onChange={(e) => setForm((f) => ({ ...f, route_name: e.target.value }))}
                  required
                />
              </div>

              <div className="routes-form-row">
                <div className="routes-modal-field">
                  <label>Origin <span className="req">*</span></label>
                  <input
                    type="text"
                    placeholder="Starting point"
                    className="routes-modal-input"
                    value={form.origin}
                    onChange={(e) => setForm((f) => ({ ...f, origin: e.target.value }))}
                    required
                  />
                </div>
                <div className="routes-modal-field">
                  <label>Destination <span className="req">*</span></label>
                  <input
                    type="text"
                    placeholder="End point"
                    className="routes-modal-input"
                    value={form.destination}
                    onChange={(e) => setForm((f) => ({ ...f, destination: e.target.value }))}
                    required
                  />
                </div>
              </div>

              {formError && (
                <p className="routes-form-error">{formError}</p>
              )}

              <div className="routes-modal-actions">
                <button type="button" className="routes-modal-btn cancel" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="routes-modal-btn save" disabled={formLoading}>
                  {formLoading ? 'Saving…' : editRoute ? 'Save Changes' : 'Create Route'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Header */}
      <div className="routes-header">
        <div>
          <h1>Route Management</h1>
          <p className="routes-subtitle">{routes.length} routes total · {active} active · {inactive} inactive</p>
        </div>
        <button className="routes-btn-primary" onClick={openAdd}>
          <Plus size={16} /> Add Route
        </button>
      </div>

      {/* Search */}
      <div className="routes-toolbar">
        <input
          type="text"
          placeholder="Search by number, name, origin or destination…"
          className="routes-search"
          value={searchQ}
          onChange={(e) => setSearchQ(e.target.value)}
        />
      </div>

      {/* Bus Stops Side Panel */}
      {stopsRoute && (
        <StopsPanel route={stopsRoute} onClose={() => setStopsRoute(null)} />
      )}

      {/* Table */}
      <div className="routes-table-wrap">
        <table className="routes-table">
          <thead>
            <tr>
              <th>ROUTE</th>
              <th>NAME</th>
              <th>ORIGIN</th>
              <th>DESTINATION</th>
              <th>COLOR</th>
              <th>STATUS</th>
              <th>ACTIONS</th>
            </tr>
          </thead>
          <tbody>
            {filtered.length === 0 ? (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', color: '#9ca3af', padding: '40px' }}>
                  No routes found
                </td>
              </tr>
            ) : (
              filtered.map((r) => (
                <tr key={r.id}>
                  <td>
                    <div className="route-number-cell">
                      <Route size={14} style={{ color: r.color }} />
                      <span className="route-number-badge" style={{ borderColor: r.color, color: r.color }}>
                        {r.route_number}
                      </span>
                    </div>
                  </td>
                  <td className="route-name-cell">{r.route_name}</td>
                  <td>{r.origin}</td>
                  <td>{r.destination}</td>
                  <td>
                    <div className="route-color-cell">
                      <span className="route-color-swatch" style={{ background: r.color }} />
                      <span>{r.color}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`route-status-badge ${r.is_active ? 'active' : 'inactive'}`}>
                      {r.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td>
                    <div className="routes-action-btns">
                      <button className="routes-action-btn blue" onClick={() => openEdit(r)}>
                        <Pencil size={14} /> Edit
                      </button>
                      <button className="routes-action-btn purple" onClick={() => setStopsRoute(r)}>
                        <MapPin size={14} /> Bus Stops
                      </button>
                      <button
                        className={`routes-action-btn ${r.is_active ? 'orange' : 'green'}`}
                        onClick={() => handleToggle(r)}
                        title={r.is_active ? 'Deactivate' : 'Activate'}
                      >
                        {r.is_active
                          ? <><ToggleLeft size={14} /> Deactivate</>
                          : <><ToggleRight size={14} /> Activate</>}
                      </button>
                      <button className="routes-action-btn red" onClick={() => setDeleteTarget(r)}>
                        <Trash2 size={14} /> Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
