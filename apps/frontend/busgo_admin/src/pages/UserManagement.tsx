import { useState, useEffect, useCallback } from 'react';
import {
  Plus, Download, Search, Pencil, Power, Trash2, Check, X,
  UserPlus, Shield, Users, Eye, EyeOff,
} from 'lucide-react';
import { fetchDrivers, approveDriver, rejectDriver, setDriverStatus, deleteDriver, createDriver, updateDriver } from '../services/drivers.service';
import { fetchPassengers, suspendPassenger, activatePassenger, deletePassenger, createPassenger } from '../services/passengers.service';
import { fetchAdmins, toggleAdminStatus, deleteAdmin, createAdmin, updateAdmin } from '../services/admins.service';
import { fetchAdminRoutes, type Route } from '../services/routes.service';
import type { Driver, Passenger, Admin } from '../types';
import './UserManagement.css';

type Tab = 'passengers' | 'drivers' | 'admins';

const BLANK_DRIVER    = { full_name: '', email: '', phone: '', route_id: '' };
const BLANK_ADMIN     = { full_name: '', email: '', phone: '', password: '', role: 'admin' as const };
const BLANK_PASSENGER = { full_name: '', email: '', password: '', username: '', phone: '', nic: '' };

export default function UserManagement() {
  const [activeTab, setActiveTab] = useState<Tab>('drivers');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  const [routeFilter, setRouteFilter] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [currentPage, setCurrentPage] = useState(1);

  const [driversList, setDriversList] = useState<Driver[]>([]);
  const [passengersList, setPassengersList] = useState<Passenger[]>([]);
  const [adminsList, setAdminsList] = useState<Admin[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // ── Modal state ──────────────────────────────────────────────
  const [modalType, setModalType] = useState<'add-driver' | 'edit-driver' | 'add-admin' | 'edit-admin' | 'add-passenger' | null>(null);
  const [editTarget, setEditTarget] = useState<Driver | Admin | null>(null);
  const [driverForm, setDriverForm]       = useState(BLANK_DRIVER);
  const [adminForm, setAdminForm]         = useState(BLANK_ADMIN);
  const [passengerForm, setPassengerForm] = useState(BLANK_PASSENGER);
  const [showPassword, setShowPassword] = useState(false);
  const [formLoading, setFormLoading] = useState(false);
  const [formError, setFormError]   = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<{ type: Tab; id: string; name: string } | null>(null);

  const loadAll = useCallback(() => {
    setLoading(true);
    Promise.all([fetchDrivers(), fetchPassengers(), fetchAdmins(), fetchAdminRoutes(false)])
      .then(([d, p, a, r]) => {
        setDriversList(d);
        setPassengersList(p);
        setAdminsList(a);
        setRoutes(r);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => { loadAll(); }, [loadAll]);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3500);
  };

  // ── Modal openers ──────────────────────────────────────────────
  const openAddDriver = () => {
    setDriverForm(BLANK_DRIVER);
    setFormError(null);
    setModalType('add-driver');
  };

  const openEditDriver = (d: Driver) => {
    setEditTarget(d);
    setDriverForm({
      full_name: d.name,
      email:     d.email ?? '',
      phone:     d.phone === '—' ? '' : (d.phone ?? ''),
      route_id:  d.routeId ?? '',
    });
    setFormError(null);
    setModalType('edit-driver');
  };

  const openAddPassenger = () => {
    setPassengerForm(BLANK_PASSENGER);
    setShowPassword(false);
    setFormError(null);
    setModalType('add-passenger');
  };

  const openAddAdmin = () => {
    setAdminForm(BLANK_ADMIN);
    setShowPassword(false);
    setFormError(null);
    setModalType('add-admin');
  };

  const openEditAdmin = (a: Admin) => {
    setEditTarget(a);
    setAdminForm({
      full_name: a.name,
      email:     a.email,
      phone:     a.phone === '—' ? '' : (a.phone ?? ''),
      password:  '',
      role:      (a.role === 'Super Admin' ? 'super_admin' : a.role === 'Admin' ? 'admin' : 'moderator') as any,
    });
    setShowPassword(false);
    setFormError(null);
    setModalType('edit-admin');
  };

  const closeModal = () => { setModalType(null); setEditTarget(null); };

  // ── Form submits ──────────────────────────────────────────────
  const handleDriverSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFormLoading(true);
    try {
      const payload = {
        full_name: driverForm.full_name.trim(),
        email:     driverForm.email.trim(),
        phone:     driverForm.phone.trim() || undefined,
        route_id:  driverForm.route_id || null,
      };

      if (modalType === 'edit-driver' && editTarget) {
        const uuid = (editTarget as Driver)._uuid ?? editTarget.id;
        const updated = await updateDriver(uuid, payload);
        setDriversList((prev) => prev.map((d) => (d._uuid ?? d.id) === uuid ? updated : d));
        showToast(`Driver ${updated.name} updated`);
      } else {
        const created = await createDriver(payload);
        setDriversList((prev) => [...prev, created]);
        showToast(`Driver ${created.name} added`);
      }
      closeModal();
    } catch (err: any) {
      setFormError(err?.response?.data?.message ?? err?.message ?? 'Failed to save driver');
    } finally {
      setFormLoading(false);
    }
  };

  const handleAdminSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFormLoading(true);
    try {
      if (modalType === 'edit-admin' && editTarget) {
        const updated = await updateAdmin(editTarget.id, {
          full_name: adminForm.full_name.trim(),
          phone:     adminForm.phone.trim() || undefined,
          role:      adminForm.role,
        });
        setAdminsList((prev) => prev.map((a) => a.id === editTarget.id ? updated : a));
        showToast(`Admin ${updated.name} updated`);
      } else {
        const created = await createAdmin({
          full_name: adminForm.full_name.trim(),
          email:     adminForm.email.trim(),
          phone:     adminForm.phone.trim() || undefined,
          password:  adminForm.password,
          role:      adminForm.role,
        });
        setAdminsList((prev) => [...prev, created]);
        showToast(`Admin ${created.name} created`);
      }
      closeModal();
    } catch (err: any) {
      setFormError(err?.response?.data?.message ?? err?.message ?? 'Failed to save admin');
    } finally {
      setFormLoading(false);
    }
  };

  const handlePassengerSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    setFormLoading(true);
    try {
      const created = await createPassenger({
        full_name: passengerForm.full_name.trim(),
        email:     passengerForm.email.trim(),
        password:  passengerForm.password,
        username:  passengerForm.username.trim() || undefined,
        phone:     passengerForm.phone.trim() || undefined,
        nic:       passengerForm.nic.trim() || undefined,
      });
      setPassengersList((prev) => [...prev, created]);
      showToast(`Passenger ${created.name} created`);
      closeModal();
    } catch (err: any) {
      setFormError(err?.response?.data?.message ?? err?.message ?? 'Failed to create passenger');
    } finally {
      setFormLoading(false);
    }
  };

  // ── Driver actions ────────────────────────────────────────────
  const handleApproveDriver = async (uuid: string) => {
    try {
      const updated = await approveDriver(uuid);
      setDriversList((prev) => prev.map((d) => (d._uuid ?? d.id) === uuid ? updated : d));
      showToast('Driver approved successfully');
    } catch { showToast('Failed to approve driver'); }
  };
  const handleRejectDriver = async (uuid: string) => {
    try {
      await rejectDriver(uuid);
      setDriversList((prev) => prev.filter((d) => (d._uuid ?? d.id) !== uuid));
      showToast('Driver application rejected');
    } catch { showToast('Failed to reject driver'); }
  };
  const handleDeactivateDriver = async (uuid: string) => {
    try {
      const updated = await setDriverStatus(uuid, 'inactive');
      setDriversList((prev) => prev.map((d) => (d._uuid ?? d.id) === uuid ? updated : d));
      showToast('Driver deactivated');
    } catch { showToast('Failed to deactivate driver'); }
  };
  const handleActivateDriver = async (uuid: string) => {
    try {
      const updated = await setDriverStatus(uuid, 'active');
      setDriversList((prev) => prev.map((d) => (d._uuid ?? d.id) === uuid ? updated : d));
      showToast('Driver activated');
    } catch { showToast('Failed to activate driver'); }
  };
  const handleDeleteDriver = async (uuid: string) => {
    try {
      await deleteDriver(uuid);
      setDriversList((prev) => prev.filter((d) => (d._uuid ?? d.id) !== uuid));
      showToast('Driver deleted');
    } catch { showToast('Failed to delete driver'); }
  };

  // ── Passenger actions ──────────────────────────────────────────
  const handleSuspendPassenger = async (id: string) => {
    try {
      await suspendPassenger(id);
      setPassengersList((prev) => prev.map((p) => p.id === id ? { ...p, status: 'Suspended' as const } : p));
      showToast('Passenger suspended');
    } catch { showToast('Failed to suspend passenger'); }
  };
  const handleActivatePassenger = async (id: string) => {
    try {
      await activatePassenger(id);
      setPassengersList((prev) => prev.map((p) => p.id === id ? { ...p, status: 'Active' as const } : p));
      showToast('Passenger activated');
    } catch { showToast('Failed to activate passenger'); }
  };
  const handleDeletePassenger = async (id: string) => {
    try {
      await deletePassenger(id);
      setPassengersList((prev) => prev.filter((p) => p.id !== id));
      showToast('Passenger deleted');
    } catch { showToast('Failed to delete passenger'); }
  };

  // ── Admin actions ──────────────────────────────────────────────
  const handleToggleAdmin = async (id: string) => {
    try {
      const updated = await toggleAdminStatus(id);
      setAdminsList((prev) => prev.map((a) => a.id === id ? updated : a));
      showToast(`Admin ${updated.status === 'Active' ? 'activated' : 'deactivated'}`);
    } catch { showToast('Failed to update admin status'); }
  };
  const handleDeleteAdmin = async (id: string) => {
    try {
      await deleteAdmin(id);
      setAdminsList((prev) => prev.filter((a) => a.id !== id));
      showToast('Admin removed');
    } catch { showToast('Failed to delete admin'); }
  };

  // ── Delete confirm handler ─────────────────────────────────────
  const handleDeleteConfirm = async () => {
    if (!deleteConfirm) return;
    const { type, id } = deleteConfirm;
    setDeleteConfirm(null);
    if (type === 'drivers')    await handleDeleteDriver(id);
    if (type === 'passengers') await handleDeletePassenger(id);
    if (type === 'admins')     await handleDeleteAdmin(id);
  };

  const pendingCount = driversList.filter((d) => d.status === 'Pending').length;

  const filteredDrivers = driversList.filter((d) => {
    if (statusFilter !== 'all' && d.status !== statusFilter) return false;
    if (searchQuery && !d.name.toLowerCase().includes(searchQuery.toLowerCase()) && !d.id.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });
  const filteredPassengers = passengersList.filter((p) => {
    if (statusFilter !== 'all' && p.status !== statusFilter) return false;
    if (searchQuery && !p.name.toLowerCase().includes(searchQuery.toLowerCase()) && !p.id.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });
  const filteredAdmins = adminsList.filter((a) => {
    if (statusFilter !== 'all' && a.status !== statusFilter) return false;
    if (searchQuery && !a.name.toLowerCase().includes(searchQuery.toLowerCase()) && !a.id.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    return true;
  });

  const getStatusOptions = () => {
    if (activeTab === 'passengers') return ['Active', 'Suspended', 'Inactive'];
    if (activeTab === 'admins') return ['Active', 'Inactive'];
    return ['Active', 'Inactive', 'Pending'];
  };
  const getTotalLabel = () => {
    if (activeTab === 'passengers') return `${filteredPassengers.length} of ${passengersList.length} passengers`;
    if (activeTab === 'admins') return `${filteredAdmins.length} of ${adminsList.length} admins`;
    return `${filteredDrivers.length} of ${driversList.length} drivers`;
  };

  if (loading) {
    return <div className="users-page" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '60vh', fontSize: '14px', color: '#6b7280' }}>Loading users…</div>;
  }

  return (
    <div className="users-page">
      {/* Toast */}
      {toast && (
        <div className="users-toast">
          <Check size={16} />
          <span>{toast}</span>
          <button onClick={() => setToast(null)}><X size={14} /></button>
        </div>
      )}

      {/* Delete Confirm Dialog */}
      {deleteConfirm && (
        <div className="um-modal-overlay" onClick={() => setDeleteConfirm(null)}>
          <div className="um-modal um-modal--sm" onClick={(e) => e.stopPropagation()}>
            <div className="um-modal-header">
              <h3>Confirm Delete</h3>
              <button className="um-modal-close" onClick={() => setDeleteConfirm(null)}><X size={20} /></button>
            </div>
            <div className="um-modal-body">
              <p style={{ color: '#374151', marginBottom: '20px' }}>
                Delete <strong>{deleteConfirm.name}</strong>? This cannot be undone.
              </p>
              <div className="um-modal-actions">
                <button className="um-modal-btn cancel" onClick={() => setDeleteConfirm(null)}>Cancel</button>
                <button className="um-modal-btn delete" onClick={handleDeleteConfirm}>Delete</button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add / Edit Driver Modal */}
      {(modalType === 'add-driver' || modalType === 'edit-driver') && (
        <div className="um-modal-overlay" onClick={closeModal}>
          <div className="um-modal" onClick={(e) => e.stopPropagation()}>
            <div className="um-modal-header">
              <h3>{modalType === 'edit-driver' ? 'Edit Driver' : 'Add New Driver'}</h3>
              <button className="um-modal-close" onClick={closeModal}><X size={20} /></button>
            </div>
            <form className="um-modal-body" onSubmit={handleDriverSubmit}>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Full Name <span className="req">*</span></label>
                  <input type="text" className="um-input" placeholder="Full name" required
                    value={driverForm.full_name}
                    onChange={(e) => setDriverForm((f) => ({ ...f, full_name: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Email <span className="req">*</span></label>
                  <input type="email" className="um-input" placeholder="driver@example.com" required
                    disabled={modalType === 'edit-driver'}
                    value={driverForm.email}
                    onChange={(e) => setDriverForm((f) => ({ ...f, email: e.target.value }))} />
                </div>
              </div>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Phone</label>
                  <input type="tel" className="um-input" placeholder="+94 71 234 5678"
                    value={driverForm.phone}
                    onChange={(e) => setDriverForm((f) => ({ ...f, phone: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Assign Route</label>
                  <select className="um-input" value={driverForm.route_id}
                    onChange={(e) => setDriverForm((f) => ({ ...f, route_id: e.target.value }))}>
                    <option value="">Unassigned</option>
                    {routes.map((r) => (
                      <option key={r.id} value={r.id}>Route {r.route_number} — {r.route_name}</option>
                    ))}
                  </select>
                </div>
              </div>
              {formError && <p className="um-form-error">{formError}</p>}
              <div className="um-modal-actions">
                <button type="button" className="um-modal-btn cancel" onClick={closeModal}>Cancel</button>
                <button type="submit" className="um-modal-btn save" disabled={formLoading}>
                  {formLoading ? 'Saving…' : modalType === 'edit-driver' ? 'Save Changes' : 'Add Driver'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add / Edit Admin Modal */}
      {(modalType === 'add-admin' || modalType === 'edit-admin') && (
        <div className="um-modal-overlay" onClick={closeModal}>
          <div className="um-modal" onClick={(e) => e.stopPropagation()}>
            <div className="um-modal-header">
              <h3>{modalType === 'edit-admin' ? 'Edit Admin' : 'Add New Admin'}</h3>
              <button className="um-modal-close" onClick={closeModal}><X size={20} /></button>
            </div>
            <form className="um-modal-body" onSubmit={handleAdminSubmit}>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Full Name <span className="req">*</span></label>
                  <input type="text" className="um-input" placeholder="Full name" required
                    value={adminForm.full_name}
                    onChange={(e) => setAdminForm((f) => ({ ...f, full_name: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Email {modalType === 'add-admin' && <span className="req">*</span>}</label>
                  <input type="email" className="um-input" placeholder="admin@busgo.lk"
                    required={modalType === 'add-admin'}
                    disabled={modalType === 'edit-admin'}
                    value={adminForm.email}
                    onChange={(e) => setAdminForm((f) => ({ ...f, email: e.target.value }))} />
                </div>
              </div>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Phone</label>
                  <input type="tel" className="um-input" placeholder="+94 71 234 5678"
                    value={adminForm.phone}
                    onChange={(e) => setAdminForm((f) => ({ ...f, phone: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Role <span className="req">*</span></label>
                  <select className="um-input" value={adminForm.role}
                    onChange={(e) => setAdminForm((f) => ({ ...f, role: e.target.value as any }))}>
                    <option value="moderator">Moderator</option>
                    <option value="admin">Admin</option>
                    <option value="super_admin">Super Admin</option>
                  </select>
                </div>
              </div>
              {modalType === 'add-admin' && (
                <div className="um-field">
                  <label>Password <span className="req">*</span></label>
                  <div className="um-password-wrap">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      className="um-input"
                      placeholder="Min 8 characters"
                      required
                      minLength={8}
                      value={adminForm.password}
                      onChange={(e) => setAdminForm((f) => ({ ...f, password: e.target.value }))}
                    />
                    <button type="button" className="um-password-eye" onClick={() => setShowPassword((v) => !v)}>
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
              )}
              {formError && <p className="um-form-error">{formError}</p>}
              <div className="um-modal-actions">
                <button type="button" className="um-modal-btn cancel" onClick={closeModal}>Cancel</button>
                <button type="submit" className="um-modal-btn save" disabled={formLoading}>
                  {formLoading ? 'Saving…' : modalType === 'edit-admin' ? 'Save Changes' : 'Add Admin'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Add Passenger Modal */}
      {modalType === 'add-passenger' && (
        <div className="um-modal-overlay" onClick={closeModal}>
          <div className="um-modal" onClick={(e) => e.stopPropagation()}>
            <div className="um-modal-header">
              <h3>Add New Passenger</h3>
              <button className="um-modal-close" onClick={closeModal}><X size={20} /></button>
            </div>
            <form className="um-modal-body" onSubmit={handlePassengerSubmit}>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Full Name <span className="req">*</span></label>
                  <input type="text" className="um-input" placeholder="Full name" required
                    value={passengerForm.full_name}
                    onChange={(e) => setPassengerForm((f) => ({ ...f, full_name: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Email <span className="req">*</span></label>
                  <input type="email" className="um-input" placeholder="passenger@example.com" required
                    value={passengerForm.email}
                    onChange={(e) => setPassengerForm((f) => ({ ...f, email: e.target.value }))} />
                </div>
              </div>
              <div className="um-form-row">
                <div className="um-field">
                  <label>Username</label>
                  <input type="text" className="um-input" placeholder="Optional username"
                    value={passengerForm.username}
                    onChange={(e) => setPassengerForm((f) => ({ ...f, username: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Phone</label>
                  <input type="tel" className="um-input" placeholder="+94 71 234 5678"
                    value={passengerForm.phone}
                    onChange={(e) => setPassengerForm((f) => ({ ...f, phone: e.target.value }))} />
                </div>
              </div>
              <div className="um-form-row">
                <div className="um-field">
                  <label>NIC</label>
                  <input type="text" className="um-input" placeholder="National ID number"
                    value={passengerForm.nic}
                    onChange={(e) => setPassengerForm((f) => ({ ...f, nic: e.target.value }))} />
                </div>
                <div className="um-field">
                  <label>Password <span className="req">*</span></label>
                  <div className="um-password-wrap">
                    <input
                      type={showPassword ? 'text' : 'password'}
                      className="um-input"
                      placeholder="Min 8 characters"
                      required
                      minLength={8}
                      value={passengerForm.password}
                      onChange={(e) => setPassengerForm((f) => ({ ...f, password: e.target.value }))}
                    />
                    <button type="button" className="um-password-eye" onClick={() => setShowPassword((v) => !v)}>
                      {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>
              </div>
              {formError && <p className="um-form-error">{formError}</p>}
              <div className="um-modal-actions">
                <button type="button" className="um-modal-btn cancel" onClick={closeModal}>Cancel</button>
                <button type="submit" className="um-modal-btn save" disabled={formLoading}>
                  {formLoading ? 'Creating…' : 'Add Passenger'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── Page Header ── */}
      <div className="users-header">
        <h1>User Management</h1>
        <div className="users-header-actions">
          {activeTab === 'drivers' && (
            <button className="users-btn primary" onClick={openAddDriver}>
              <Plus size={16} /> Add Driver
            </button>
          )}
          {activeTab === 'admins' && (
            <button className="users-btn primary" onClick={openAddAdmin}>
              <Plus size={16} /> Add Admin
            </button>
          )}
          {activeTab === 'passengers' && (
            <button className="users-btn primary" onClick={openAddPassenger}>
              <Plus size={16} /> Add Passenger
            </button>
          )}
          <button className="users-btn outline">
            <Download size={16} /> Export
          </button>
        </div>
      </div>

      {/* ── Tabs ── */}
      <div className="users-tabs">
        <button
          className={`users-tab ${activeTab === 'passengers' ? 'active' : ''}`}
          onClick={() => { setActiveTab('passengers'); setSearchQuery(''); setStatusFilter('all'); }}
        >
          <Users size={16} /> Passengers
          <span className="tab-count">{passengersList.length}</span>
        </button>
        <button
          className={`users-tab ${activeTab === 'drivers' ? 'active' : ''}`}
          onClick={() => { setActiveTab('drivers'); setSearchQuery(''); setStatusFilter('all'); }}
        >
          <UserPlus size={16} /> Drivers
          {pendingCount > 0 && <span className="tab-badge">{pendingCount}</span>}
        </button>
        <button
          className={`users-tab ${activeTab === 'admins' ? 'active' : ''}`}
          onClick={() => { setActiveTab('admins'); setSearchQuery(''); setStatusFilter('all'); }}
        >
          <Shield size={16} /> Admins
          <span className="tab-count">{adminsList.length}</span>
        </button>
      </div>

      {/* ── Filters ── */}
      <div className="users-filters">
        <div className="users-search-wrap">
          <Search size={16} className="search-icon" />
          <input
            type="text"
            placeholder={`Search ${activeTab} by name or ID...`}
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="users-search"
          />
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="users-filter">
          <option value="all">Status: All</option>
          {getStatusOptions().map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        {activeTab === 'drivers' && (
          <>
            <select value={routeFilter} onChange={(e) => setRouteFilter(e.target.value)} className="users-filter">
              <option value="all">Route</option>
              {routes.map((r) => (
                <option key={r.id} value={r.route_number}>Route {r.route_number}</option>
              ))}
            </select>
            <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="users-filter">
              <option value="name">Sort: Name</option>
              <option value="id">Sort: ID</option>
              <option value="rating">Sort: Rating</option>
            </select>
          </>
        )}
        <span className="users-showing">Showing {getTotalLabel()}</span>
      </div>

      {/* ── DRIVERS TABLE ── */}
      {activeTab === 'drivers' && (
        <div className="users-table-wrap">
          <table className="users-table">
            <thead>
              <tr>
                <th>ID</th><th>NAME</th><th>EMAIL</th><th>PHONE</th>
                <th>ROUTE</th><th>STATUS</th><th>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {filteredDrivers.map((driver) => (
                <tr key={driver.id}>
                  <td className="driver-id">{driver.id}</td>
                  <td>
                    <div className="driver-name-cell">
                      <span className="driver-name">{driver.name}</span>
                      {driver.pendingReview
                        ? <span className="driver-pending-label">Pending Review</span>
                        : <span className="driver-rating">Rating: {driver.rating}</span>}
                    </div>
                  </td>
                  <td className="driver-email">{driver.email}</td>
                  <td>{driver.phone}</td>
                  <td>
                    {(() => {
                      const routeNum = driver.route
                        ?? (driver.routeId ? routes.find((r) => r.id === driver.routeId)?.route_number : null);
                      return routeNum
                        ? <span className="route-num">{routeNum}</span>
                        : <span className="unassigned">Unassigned</span>;
                    })()}
                  </td>
                  <td>
                    <span className={`user-status-badge ${driver.status.toLowerCase()}`}>
                      <span className="status-dot-sm"></span>{driver.status}
                    </span>
                  </td>
                  <td>
                    <div className="user-action-btns">
                      {driver.status === 'Pending' ? (
                        <>
                          <button className="user-action-btn green" onClick={() => handleApproveDriver(driver._uuid ?? driver.id)}>
                            <Check size={14} /> Approve
                          </button>
                          <button className="user-action-btn red-outline" onClick={() => handleRejectDriver(driver._uuid ?? driver.id)}>
                            <X size={14} /> Reject
                          </button>
                        </>
                      ) : (
                        <>
                          <button className="user-action-btn blue" onClick={() => openEditDriver(driver)}>
                            <Pencil size={14} /> Edit
                          </button>
                          {driver.status === 'Active'
                            ? <button className="user-action-btn gray" onClick={() => handleDeactivateDriver(driver._uuid ?? driver.id)}><Power size={14} /> Deactivate</button>
                            : <button className="user-action-btn green" onClick={() => handleActivateDriver(driver._uuid ?? driver.id)}><Check size={14} /> Activate</button>}
                          <button className="user-action-btn red" onClick={() => setDeleteConfirm({ type: 'drivers', id: driver._uuid ?? driver.id, name: driver.name })}>
                            <Trash2 size={14} /> Delete
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filteredDrivers.length === 0 && (
                <tr><td colSpan={7} className="empty-row">No drivers found</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* ── PASSENGERS TABLE ── */}
      {activeTab === 'passengers' && (
        <div className="users-table-wrap">
          <table className="users-table">
            <thead>
              <tr>
                <th>ID</th><th>NAME</th><th>EMAIL</th><th>PHONE</th>
                <th>NIC</th><th>TRIPS</th><th>STATUS</th><th>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {filteredPassengers.map((psg) => (
                <tr key={psg.id}>
                  <td className="driver-id">{psg.id}</td>
                  <td>
                    <div className="driver-name-cell">
                      <span className="driver-name">{psg.name}</span>
                      <span className="driver-rating">Since {psg.registeredDate}</span>
                    </div>
                  </td>
                  <td className="driver-email">{psg.email}</td>
                  <td>{psg.phone}</td>
                  <td><span className="nic-badge">{psg.nic}</span></td>
                  <td>
                    <div className="trips-cell">
                      <span className="trips-today">{psg.tripsToday} today</span>
                      <span className="trips-total">{psg.totalTrips} total</span>
                    </div>
                  </td>
                  <td>
                    <span className={`user-status-badge ${psg.status.toLowerCase()}`}>
                      <span className="status-dot-sm"></span>{psg.status}
                    </span>
                  </td>
                  <td>
                    <div className="user-action-btns">
                      {psg.status === 'Active'
                        ? <button className="user-action-btn gray" onClick={() => handleSuspendPassenger(psg.id)}><Power size={14} /> Suspend</button>
                        : <button className="user-action-btn green" onClick={() => handleActivatePassenger(psg.id)}><Check size={14} /> Activate</button>}
                      <button className="user-action-btn red" onClick={() => setDeleteConfirm({ type: 'passengers', id: psg.id, name: psg.name })}>
                        <Trash2 size={14} /> Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
              {filteredPassengers.length === 0 && (
                <tr><td colSpan={8} className="empty-row">No passengers found</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* ── ADMINS TABLE ── */}
      {activeTab === 'admins' && (
        <div className="users-table-wrap">
          <table className="users-table">
            <thead>
              <tr>
                <th>ID</th><th>NAME</th><th>EMAIL</th><th>PHONE</th>
                <th>ROLE</th><th>LAST LOGIN</th><th>STATUS</th><th>ACTIONS</th>
              </tr>
            </thead>
            <tbody>
              {filteredAdmins.map((admin) => (
                <tr key={admin.id}>
                  <td className="driver-id">{admin.id}</td>
                  <td><span className="driver-name">{admin.name}</span></td>
                  <td className="driver-email">{admin.email}</td>
                  <td>{admin.phone}</td>
                  <td>
                    <span className={`role-badge role-${admin.role.toLowerCase().replace(' ', '-')}`}>
                      {admin.role}
                    </span>
                  </td>
                  <td className="last-login">{admin.lastLogin}</td>
                  <td>
                    <span className={`user-status-badge ${admin.status.toLowerCase()}`}>
                      <span className="status-dot-sm"></span>{admin.status}
                    </span>
                  </td>
                  <td>
                    <div className="user-action-btns">
                      <button className="user-action-btn blue" onClick={() => openEditAdmin(admin)}>
                        <Pencil size={14} /> Edit
                      </button>
                      {admin.status === 'Active'
                        ? <button className="user-action-btn gray" onClick={() => handleToggleAdmin(admin.id)}><Power size={14} /> Deactivate</button>
                        : <button className="user-action-btn green" onClick={() => handleToggleAdmin(admin.id)}><Check size={14} /> Activate</button>}
                      {admin.role !== 'Super Admin' && (
                        <button className="user-action-btn red" onClick={() => setDeleteConfirm({ type: 'admins', id: admin.id, name: admin.name })}>
                          <Trash2 size={14} /> Delete
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {filteredAdmins.length === 0 && (
                <tr><td colSpan={8} className="empty-row">No admins found</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      <div className="users-pagination">
        <span className="pagination-info">Showing {getTotalLabel()}</span>
        <div className="pagination-controls">
          <button className="page-btn" disabled={currentPage === 1} onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}>&larr;</button>
          {[1, 2, 3].map((p) => (
            <button key={p} className={`page-btn ${p === currentPage ? 'active' : ''}`} onClick={() => setCurrentPage(p)}>{p}</button>
          ))}
          <button className="page-btn" onClick={() => setCurrentPage((p) => p + 1)}>&rarr;</button>
        </div>
      </div>
    </div>
  );
}
