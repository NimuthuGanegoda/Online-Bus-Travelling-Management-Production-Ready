import api from './api';

export interface Route {
  id: string;
  route_number: string;
  route_name: string;
  origin: string;
  destination: string;
  color: string;
  is_active: boolean;
  created_at: string;
}

export async function fetchAdminRoutes(includeInactive = true): Promise<Route[]> {
  const { data: res } = await api.get('/routes', {
    params: includeInactive ? { all: 'true' } : {},
  });
  return res.data ?? [];
}

export async function createRoute(payload: {
  route_number: string;
  route_name: string;
  origin: string;
  destination: string;
  color?: string;
}): Promise<Route> {
  const { data: res } = await api.post('/routes', payload);
  return res.data;
}

export async function updateRoute(
  id: string,
  payload: Partial<{
    route_number: string;
    route_name: string;
    origin: string;
    destination: string;
    color: string;
  }>,
): Promise<Route> {
  const { data: res } = await api.patch(`/routes/${id}`, payload);
  return res.data;
}

export async function toggleRouteStatus(id: string): Promise<Route> {
  const { data: res } = await api.patch(`/routes/${id}/toggle`);
  return res.data;
}

export async function deleteRoute(id: string): Promise<void> {
  await api.delete(`/routes/${id}`);
}
