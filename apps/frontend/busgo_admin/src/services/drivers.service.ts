import api from './api';
import type { Driver } from '../types';
import { mapDriver } from './mappers';

export async function fetchDrivers(params?: { status?: string; search?: string }): Promise<Driver[]> {
  const { data: res } = await api.get('/drivers', { params });
  return (res.data ?? []).map(mapDriver);
}

export async function approveDriver(id: string): Promise<Driver> {
  const { data: res } = await api.patch(`/drivers/${id}/approve`);
  return mapDriver(res.data);
}

export async function rejectDriver(id: string): Promise<void> {
  await api.patch(`/drivers/${id}/reject`);
}

export async function setDriverStatus(id: string, status: 'active' | 'inactive'): Promise<Driver> {
  const { data: res } = await api.patch(`/drivers/${id}/status`, { status });
  return mapDriver(res.data);
}

export async function deleteDriver(id: string): Promise<void> {
  await api.delete(`/drivers/${id}`);
}

export async function createDriver(payload: {
  full_name: string;
  email: string;
  phone?: string;
  route_id?: string | null;
}): Promise<Driver> {
  const { data: res } = await api.post('/drivers', payload);
  return mapDriver(res.data);
}

export async function updateDriver(
  id: string,
  payload: { full_name?: string; email?: string; phone?: string; route_id?: string | null },
): Promise<Driver> {
  const { data: res } = await api.patch(`/drivers/${id}`, payload);
  return mapDriver(res.data);
}
