import api from './api';
import type { Admin } from '../types';
import { mapAdmin } from './mappers';

export async function fetchAdmins(params?: { search?: string; status?: string }): Promise<Admin[]> {
  const { data: res } = await api.get('/admins', { params });
  return (res.data ?? []).map(mapAdmin);
}

export async function toggleAdminStatus(id: string): Promise<Admin> {
  const { data: res } = await api.patch(`/admins/${id}/toggle-status`);
  return mapAdmin(res.data);
}

export async function deleteAdmin(id: string): Promise<void> {
  await api.delete(`/admins/${id}`);
}

export async function createAdmin(payload: {
  full_name: string;
  email: string;
  phone?: string;
  password: string;
  role: 'super_admin' | 'admin' | 'moderator';
}): Promise<Admin> {
  const { data: res } = await api.post('/admins', payload);
  return mapAdmin(res.data);
}

export async function updateAdmin(
  id: string,
  payload: { full_name?: string; phone?: string; role?: 'super_admin' | 'admin' | 'moderator' },
): Promise<Admin> {
  const { data: res } = await api.patch(`/admins/${id}`, payload);
  return mapAdmin(res.data);
}
