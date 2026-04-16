import api from './api';
import type { Bus, StandbyBus } from '../types';
import { mapBus } from './mappers';

export interface FleetStats {
  total: number;
  active: number;
  standby: number;
  in_repair: number;
  breakdown: number;
}

export async function fetchAllBuses(params?: { status?: string; search?: string }): Promise<Bus[]> {
  const { data: res } = await api.get('/buses', { params });
  return (res.data ?? []).map(mapBus);
}

export async function fetchStandbyBuses(): Promise<StandbyBus[]> {
  const { data: res } = await api.get('/buses', { params: { status: 'standby' } });
  return (res.data ?? []).map((b: any) => ({
    _uuid: b.id,
    id: b.bus_number ?? b.id,
    registration: b.registration ?? '—',
  }));
}

export async function fetchFleetStats(): Promise<FleetStats> {
  const { data: res } = await api.get('/buses/stats');
  return res.data;
}

export async function updateBusStatus(busId: string, status: string): Promise<Bus> {
  const { data: res } = await api.patch(`/buses/${busId}/status`, { status });
  return mapBus(res.data);
}

export async function updateBusAssignment(
  busId: string,
  payload: { driverId?: string | null; routeId?: string | null; registration?: string },
): Promise<Bus> {
  const { data: res } = await api.patch(`/buses/${busId}`, payload);
  return mapBus(res.data);
}

export interface RegisterBusPayload {
  bus_number: string;
  route_id: string;
  registration?: string;
  driver_name: string;
  driver_phone?: string;
}

export async function registerBus(payload: RegisterBusPayload): Promise<Bus> {
  const { data: res } = await api.post('/buses', payload);
  return mapBus(res.data);
}

export async function fetchRoutes(): Promise<{ id: string; route_number: string; route_name: string }[]> {
  const { data: res } = await api.get('/routes', { params: { all: 'true' } });
  return (res.data ?? []).filter((r: any) => r.is_active !== false);
}
