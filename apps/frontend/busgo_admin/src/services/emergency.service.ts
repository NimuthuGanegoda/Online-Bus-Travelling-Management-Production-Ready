import api from './api';
import type { EmergencyAlert } from '../types';
import { mapEmergency } from './mappers';

export async function fetchEmergencies(params?: {
  status?: string;
  type?: string;
  priority?: string;
  page?: number;
  page_size?: number;
}): Promise<EmergencyAlert[]> {
  const { data: res } = await api.get('/emergency', { params });
  return (res.data ?? []).map(mapEmergency);
}

export async function updateEmergencyStatus(id: string, status: 'acknowledged' | 'resolved'): Promise<EmergencyAlert> {
  const { data: res } = await api.patch(`/emergency/${id}/status`, { status });
  return mapEmergency(res.data);
}

export async function deployBusToEmergency(alertId: string, busId?: string): Promise<EmergencyAlert> {
  const { data: res } = await api.post(`/emergency/${alertId}/deploy-bus`, { bus_id: busId });
  return mapEmergency(res.data);
}

export async function setPoliceNotified(alertId: string, notified: boolean): Promise<EmergencyAlert> {
  const { data: res } = await api.patch(`/emergency/${alertId}/police`, { police_notified: notified });
  return mapEmergency(res.data);
}
