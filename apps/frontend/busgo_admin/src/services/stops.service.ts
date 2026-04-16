import api from './api';

export interface BusStop {
  junction_id: string;
  stop_order:  number;
  id:          string;
  stop_name:   string;
  latitude:    number;
  longitude:   number;
}

export interface AllStop {
  id:        string;
  stop_name: string;
  latitude:  number;
  longitude: number;
}

export async function fetchRouteStops(routeId: string): Promise<BusStop[]> {
  const { data: res } = await api.get('/stops', { params: { route_id: routeId } });
  return res.data ?? [];
}

export async function fetchAllStops(): Promise<AllStop[]> {
  const { data: res } = await api.get('/stops/all');
  return res.data ?? [];
}

export async function addStop(payload: {
  route_id:   string;
  stop_name:  string;
  latitude:   number;
  longitude:  number;
  stop_order?: number;
}): Promise<BusStop> {
  const { data: res } = await api.post('/stops', payload);
  return res.data;
}

export async function removeStop(junctionId: string): Promise<void> {
  await api.delete(`/stops/${junctionId}`);
}

export async function reorderStop(junctionId: string, stop_order: number): Promise<void> {
  await api.patch(`/stops/${junctionId}/order`, { stop_order });
}
