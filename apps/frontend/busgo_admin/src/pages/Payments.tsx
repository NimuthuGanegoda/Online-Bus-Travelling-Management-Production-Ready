import { useState, useEffect, useCallback } from 'react';
import { CreditCard, Wallet, CheckCircle, XCircle } from 'lucide-react';
import { fetchPayments, type Payment } from '../services/payments.service';
import './Payments.css';

const PAGE_SIZE = 15;

export default function Payments() {
  const [payments, setPayments]     = useState<Payment[]>([]);
  const [total, setTotal]           = useState(0);
  const [page, setPage]             = useState(1);
  const [statusFilter, setStatus]   = useState('');
  const [loading, setLoading]       = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetchPayments({
        page,
        page_size: PAGE_SIZE,
        status: statusFilter || undefined,
      });
      setPayments(res.payments);
      setTotal(res.total);
    } catch {
      // keep previous state on error
    } finally {
      setLoading(false);
    }
  }, [page, statusFilter]);

  useEffect(() => { load(); }, [load]);

  // Derived stats from current page (real totals need a separate API; this is demo-friendly)
  const successCount = payments.filter((p) => p.status === 'success').length;
  const failedCount  = payments.filter((p) => p.status === 'failed').length;
  const totalAmount  = payments
    .filter((p) => p.status === 'success')
    .reduce((sum, p) => sum + p.amount_lkr, 0);

  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));

  return (
    <div className="payments-page">
      {/* Header */}
      <div className="payments-header">
        <div>
          <h1>Payments</h1>
          <p>View all passenger payment records</p>
        </div>
        <div className="payments-filters">
          <select
            value={statusFilter}
            onChange={(e) => { setStatus(e.target.value); setPage(1); }}
          >
            <option value="">All Statuses</option>
            <option value="success">Success</option>
            <option value="failed">Failed</option>
          </select>
        </div>
      </div>

      {/* Stats */}
      <div className="payments-stats">
        <div className="stat-card">
          <div className="stat-icon blue"><CreditCard size={20} /></div>
          <div>
            <div className="stat-value">{total}</div>
            <div className="stat-label">Total Payments</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon green"><CheckCircle size={20} /></div>
          <div>
            <div className="stat-value">{successCount}</div>
            <div className="stat-label">Successful (this page)</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon red"><XCircle size={20} /></div>
          <div>
            <div className="stat-value">{failedCount}</div>
            <div className="stat-label">Failed (this page)</div>
          </div>
        </div>
        <div className="stat-card">
          <div className="stat-icon blue"><Wallet size={20} /></div>
          <div>
            <div className="stat-value">LKR {totalAmount.toFixed(2)}</div>
            <div className="stat-label">Revenue (this page)</div>
          </div>
        </div>
      </div>

      {/* Table */}
      <div className="payments-table-wrap">
        {loading ? (
          <div className="empty-state">Loading…</div>
        ) : payments.length === 0 ? (
          <div className="empty-state">No payment records found.</div>
        ) : (
          <table className="payments-table">
            <thead>
              <tr>
                <th>User</th>
                <th>Method</th>
                <th>Card</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Date</th>
              </tr>
            </thead>
            <tbody>
              {payments.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div className="user-cell">
                      <span className="user-name">{p.users?.full_name ?? '—'}</span>
                      <span className="user-email">{p.users?.email ?? ''}</span>
                    </div>
                  </td>
                  <td>
                    <span className={`method-badge ${p.payment_method === 'credit_card' ? 'credit' : 'debit'}`}>
                      {p.payment_method === 'credit_card' ? <CreditCard size={11} /> : <Wallet size={11} />}
                      {p.payment_method === 'credit_card' ? 'Credit' : 'Debit'}
                    </span>
                  </td>
                  <td style={{ fontFamily: 'monospace' }}>{p.masked_card}</td>
                  <td className="amount-cell">LKR {Number(p.amount_lkr).toFixed(2)}</td>
                  <td>
                    <span className={`status-badge ${p.status}`}>
                      {p.status === 'success' ? 'Success' : 'Failed'}
                    </span>
                  </td>
                  <td>{new Date(p.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}

        {/* Pagination */}
        {!loading && total > PAGE_SIZE && (
          <div className="pagination">
            <span>Page {page} of {totalPages}</span>
            <button disabled={page === 1} onClick={() => setPage((p) => p - 1)}>← Prev</button>
            <button disabled={page === totalPages} onClick={() => setPage((p) => p + 1)}>Next →</button>
          </div>
        )}
      </div>
    </div>
  );
}
