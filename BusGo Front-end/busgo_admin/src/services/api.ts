import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:5000';

export const api = axios.create({
  baseURL: `${BASE_URL}/api/admin`,
  headers: { 'Content-Type': 'application/json' },
});

// ── Token storage helpers ────────────────────────────────────
export const tokenStore = {
  getAccess:  () => localStorage.getItem('admin_access_token'),
  getRefresh: () => localStorage.getItem('admin_refresh_token'),
  setTokens:  (access: string, refresh: string) => {
    localStorage.setItem('admin_access_token', access);
    localStorage.setItem('admin_refresh_token', refresh);
  },
  clear: () => {
    localStorage.removeItem('admin_access_token');
    localStorage.removeItem('admin_refresh_token');
    localStorage.removeItem('admin_info');
  },
};

// ── Request interceptor: attach access token ─────────────────
api.interceptors.request.use((config) => {
  const token = tokenStore.getAccess();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// ── Response interceptor: refresh on 401 ────────────────────
let _isRefreshing = false;
let _queue: Array<{ resolve: (t: string) => void; reject: (e: unknown) => void }> = [];

function processQueue(error: unknown, token: string | null) {
  _queue.forEach((p) => (error ? p.reject(error) : p.resolve(token!)));
  _queue = [];
}

api.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config;
    if (error.response?.status !== 401 || original._retry) {
      return Promise.reject(error);
    }

    if (_isRefreshing) {
      return new Promise((resolve, reject) => {
        _queue.push({
          resolve: (token) => {
            original.headers.Authorization = `Bearer ${token}`;
            resolve(api(original));
          },
          reject,
        });
      });
    }

    original._retry = true;
    _isRefreshing = true;

    try {
      const refreshToken = tokenStore.getRefresh();
      if (!refreshToken) throw new Error('No refresh token');

      // Use bare axios to avoid interceptor loop
      const { data } = await axios.post(`${BASE_URL}/api/admin/auth/refresh`, {
        refresh_token: refreshToken,
      });
      const newAccess: string = data.data.access_token;
      const newRefresh: string = data.data.refresh_token;

      tokenStore.setTokens(newAccess, newRefresh);
      processQueue(null, newAccess);

      original.headers.Authorization = `Bearer ${newAccess}`;
      return api(original);
    } catch (refreshError) {
      processQueue(refreshError, null);
      tokenStore.clear();
      window.location.href = '/admin/login';
      return Promise.reject(refreshError);
    } finally {
      _isRefreshing = false;
    }
  },
);

export default api;
