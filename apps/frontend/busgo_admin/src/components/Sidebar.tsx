import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard, Map, AlertTriangle, Bus, Users, FileText, LogOut, Route,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import './Sidebar.css';

const navItems = [
  { label: 'OVERVIEW', items: [
    { to: '/admin/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  ]},
  { label: 'OPERATIONS', items: [
    { to: '/admin/fleet-map',   icon: Map,           label: 'Fleet Map' },
    { to: '/admin/emergencies', icon: AlertTriangle,  label: 'Emergencies' },
    { to: '/admin/fleet',       icon: Bus,            label: 'Fleet Mgmt' },
    { to: '/admin/routes',      icon: Route,          label: 'Routes' },
  ]},
  { label: 'ADMIN', items: [
    { to: '/admin/users',       icon: Users,          label: 'Users' },
    { to: '/admin/audit-logs',  icon: FileText,       label: 'Audit Logs' },
  ]},
];

export default function Sidebar() {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/admin/login');
  };

  const initials = admin?.full_name
    ? admin.full_name.split(' ').map((w) => w[0]).join('').toUpperCase().slice(0, 2)
    : 'A';

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <img src="/busgo-logo.jpeg" alt="BUSGO" className="sidebar-logo-img" />
        <div>
          <div className="sidebar-logo-title">BUSGO</div>
          <div className="sidebar-logo-subtitle">AXIS ADMIN</div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((section) => (
          <div key={section.label} className="sidebar-section">
            <div className="sidebar-section-label">{section.label}</div>
            {section.items.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}
              >
                <item.icon size={20} />
                <span>{item.label}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      <div className="sidebar-user">
        <div className="sidebar-user-avatar">{initials}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div className="sidebar-user-name">{admin?.full_name ?? 'Admin'}</div>
          <div className="sidebar-user-status">
            <span className="status-dot online"></span> Online
          </div>
        </div>
        <button
          onClick={handleLogout}
          title="Logout"
          style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#9ca3af', padding: '4px' }}
        >
          <LogOut size={16} />
        </button>
      </div>
    </aside>
  );
}
