import { useState, useEffect } from 'react';
import { Download, Calendar } from 'lucide-react';
import { fetchAuditLogs } from '../services/audit.service';
import { exportToCSV } from '../services/csvExport';
import type { AuditLog } from '../types';
import './AuditLogs.css';

const actionStyles: Record<string, { bg: string; color: string; label: string }> = {
  RESOLVE:  { bg: '#ecfdf5', color: '#16a34a', label: '✓ RESOLVE' },
  UPDATE:   { bg: '#ebf3ff', color: '#1a6cf0', label: '→ UPDATE' },
  CREATE:   { bg: '#ecfdf5', color: '#16a34a', label: '+ CREATE' },
  DELETE:   { bg: '#fef2f2', color: '#e74c3c', label: '✕ DELETE' },
  LOGIN:    { bg: '#f3f0ff', color: '#7c3aed', label: '→ LOGIN' },
  LOGOUT:   { bg: '#f3f4f6', color: '#6b7280', label: '← LOGOUT' },
  APPROVE:  { bg: '#ecfdf5', color: '#16a34a', label: '✓ APPROVE' },
  REJECT:   { bg: '#fef2f2', color: '#e74c3c', label: '✕ REJECT' },
  DEPLOY:   { bg: '#fef9f0', color: '#d97706', label: '⚡ DEPLOY' },
  SUSPEND:  { bg: '#fff7ed', color: '#ea580c', label: '⊘ SUSPEND' },
};

const PAGE_SIZE = 50;

export default function AuditLogs() {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [adminFilter, setAdminFilter] = useState('all');
  const [actionFilter, setActionFilter] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    setLoading(true);
    fetchAuditLogs({
      action:      actionFilter !== 'all' ? actionFilter : undefined,
      admin_email: adminFilter  !== 'all' ? adminFilter  : undefined,
      page:        currentPage,
      page_size:   PAGE_SIZE,
    })
      .then((result) => {
        setLogs(result.data);
        setTotal(result.total);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [actionFilter, adminFilter, currentPage]);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  const [exporting, setExporting] = useState(false);

  // Fetch all matching logs (respecting filters + date range) and export to CSV.
  // Date filtering is applied client-side since the backend service only filters
  // by action/admin_email/entity/search.
  const handleExport = async () => {
    setExporting(true);
    try {
      const result = await fetchAuditLogs({
        action:      actionFilter !== 'all' ? actionFilter : undefined,
        admin_email: adminFilter  !== 'all' ? adminFilter  : undefined,
        page:        1,
        page_size:   10000, // grab everything matching the filters
      });

      let rows = result.data;
      if (fromDate) {
        const from = new Date(fromDate).getTime();
        rows = rows.filter((l) => new Date(l.timestamp).getTime() >= from);
      }
      if (toDate) {
        const to = new Date(toDate).getTime() + 86_400_000; // include end day
        rows = rows.filter((l) => new Date(l.timestamp).getTime() < to);
      }

      exportToCSV('busgo_audit_logs', rows, [
        ['Timestamp', 'timestamp'],
        ['Admin', 'admin'],
        ['Action', 'action'],
        ['Entity', 'entity'],
        ['Entity ID', 'entityId'],
        ['Details', 'details'],
        ['IP Address', 'ipAddress'],
      ]);
    } catch (err) {
      console.error(err);
      alert('Failed to export audit logs. Check your network.');
    } finally {
      setExporting(false);
    }
  };

  return (
    <div className="audit-page">
      <div className="audit-header">
        <h1>Audit Logs</h1>
        <div className="audit-filters">
          <div className="audit-date-filter">
            <Calendar size={14} />
            <span>From:</span>
            <input type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} className="audit-date-input" />
          </div>
          <div className="audit-date-filter">
            <Calendar size={14} />
            <span>To:</span>
            <input type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} className="audit-date-input" />
          </div>
          <select value={adminFilter} onChange={(e) => { setAdminFilter(e.target.value); setCurrentPage(1); }} className="audit-filter">
            <option value="all">Admin: All</option>
            <option value="admin@busgo.lk">admin@busgo.lk</option>
          </select>
          <select value={actionFilter} onChange={(e) => { setActionFilter(e.target.value); setCurrentPage(1); }} className="audit-filter">
            <option value="all">Action</option>
            <option value="RESOLVE">Resolve</option>
            <option value="UPDATE">Update</option>
            <option value="CREATE">Create</option>
            <option value="DELETE">Delete</option>
            <option value="LOGIN">Login</option>
            <option value="LOGOUT">Logout</option>
            <option value="APPROVE">Approve</option>
            <option value="REJECT">Reject</option>
            <option value="DEPLOY">Deploy</option>
            <option value="SUSPEND">Suspend</option>
          </select>
          <button className="audit-export-btn" onClick={handleExport} disabled={exporting}>
            <Download size={16} /> {exporting ? 'Exporting…' : 'Export CSV'}
          </button>
        </div>
      </div>

      <div className="audit-table-wrap">
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#6b7280', fontSize: '14px' }}>Loading logs…</div>
        ) : (
          <table className="audit-table">
            <thead>
              <tr>
                <th>TIMESTAMP</th>
                <th>ADMIN</th>
                <th>ACTION</th>
                <th>ENTITY</th>
                <th>ENTITY ID</th>
                <th>DETAILS</th>
                <th>IP ADDRESS</th>
              </tr>
            </thead>
            <tbody>
              {logs.length === 0 && (
                <tr><td colSpan={7} style={{ textAlign: 'center', padding: '24px', color: '#6b7280' }}>No logs found</td></tr>
              )}
              {logs.map((log) => {
                const style = actionStyles[log.action] ?? { bg: '#f3f4f6', color: '#6b7280', label: log.action };
                return (
                  <tr key={log.id}>
                    <td className="audit-timestamp">{log.timestamp}</td>
                    <td className="audit-admin">{log.admin}</td>
                    <td>
                      <span className="audit-action-badge" style={{ background: style.bg, color: style.color }}>
                        {style.label}
                      </span>
                    </td>
                    <td>{log.entity}</td>
                    <td className="audit-entity-id">{log.entityId}</td>
                    <td className="audit-details">{log.details}</td>
                    <td className="audit-ip">{log.ipAddress}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      <div className="audit-pagination">
        <span className="pagination-info">
          Showing {logs.length} of {total} log entries
        </span>
        <div className="pagination-controls">
          <button className="page-btn" disabled={currentPage === 1} onClick={() => setCurrentPage((p) => p - 1)}>←</button>
          {Array.from({ length: Math.min(3, totalPages) }, (_, i) => {
            const p = Math.max(1, currentPage - 1) + i;
            if (p > totalPages) return null;
            return (
              <button key={p} className={`page-btn ${p === currentPage ? 'active' : ''}`} onClick={() => setCurrentPage(p)}>
                {p}
              </button>
            );
          })}
          {totalPages > 3 && <span className="page-dots">...</span>}
          {totalPages > 3 && (
            <button className="page-btn" onClick={() => setCurrentPage(totalPages)}>{totalPages}</button>
          )}
          <button className="page-btn" disabled={currentPage === totalPages} onClick={() => setCurrentPage((p) => p + 1)}>→</button>
        </div>
      </div>
    </div>
  );
}
