import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import api, { tokenStore } from '../services/api';

interface AdminInfo {
  id: string;
  full_name: string;
  email: string;
  role: string;
}

interface AuthState {
  admin: AdminInfo | null;
  isAuthenticated: boolean;
}

interface AuthContextValue extends AuthState {
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function loadAdmin(): AdminInfo | null {
  try {
    const s = localStorage.getItem('admin_info');
    return s ? JSON.parse(s) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<AdminInfo | null>(() => {
    if (!tokenStore.getAccess()) return null;
    return loadAdmin();
  });

  const login = useCallback(async (email: string, password: string) => {
    const { data: res } = await api.post('auth/login', { email, password });
    const { access_token, refresh_token, admin: adminData } = res.data;
    tokenStore.setTokens(access_token, refresh_token);
    localStorage.setItem('admin_info', JSON.stringify(adminData));
    setAdmin(adminData);
  }, []);

  const logout = useCallback(async () => {
    try {
      await api.post('auth/logout', {
        refresh_token: tokenStore.getRefresh(),
      });
    } catch {
      // ignore
    }
    tokenStore.clear();
    setAdmin(null);
  }, []);

  return (
    <AuthContext.Provider value={{ admin, isAuthenticated: !!admin, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
