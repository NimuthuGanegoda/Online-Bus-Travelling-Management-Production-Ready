import api from './api';
import type { Bus, EmergencyAlert, Notification } from '../types';
import { mapBus, mapEmergency, mapNotification } from './mappers';

export interface DashboardStats {
  activeBuses: number;
  activeBusesChange: string;
  passengersToday: number;
  passengersChange: string;
  pendingAlerts: number;
  alertsNote: string;
  standbyBuses: number;
  standbyNote: string;
  pendingDrivers: number;
  totalFleet: number;
}

export async function fetchDashboardStats(): Promise<DashboardStats> {
  const { data: res } = await api.get('/dashboard/stats');
  const d = res.data;
  return {
    activeBuses:       d.activeBuses    ?? 0,
    activeBusesChange: `${d.totalFleet ?? 0} total fleet`,
    passengersToday:   d.passengersToday ?? 0,
    passengersChange:  'Today',
    pendingAlerts:     d.pendingAlerts  ?? 0,
    alertsNote:        d.pendingAlerts > 0 ? 'Needs attention' : 'All clear',
    standbyBuses:      d.standbyBuses  ?? 0,
    standbyNote:       'Ready to deploy',
    pendingDrivers:    d.pendingDrivers ?? 0,
    totalFleet:        d.totalFleet     ?? 0,
  };
}

export async function fetchLiveMapBuses(): Promise<Bus[]> {
  const { data: res } = await api.get('/dashboard/live-map');
  return (res.data ?? []).map(mapBus);
}

export async function fetchDashboardEmergencies(): Promise<EmergencyAlert[]> {
  const { data: res } = await api.get('/emergency?page_size=10');
  return (res.data ?? [])
    .filter((a: any) => a.status !== 'resolved')
    .map(mapEmergency);
}

export async function fetchNotifications(): Promise<Notification[]> {
  const { data: res } = await api.get('/notifications?page_size=20');
  return (res.data ?? []).map(mapNotification);
}

export async function markNotificationRead(id: string): Promise<void> {
  await api.patch(`/notifications/${id}/read`);
}

export async function markAllNotificationsRead(): Promise<void> {
  await api.patch('/notifications/read-all');
}

export async function deleteNotification(id: string): Promise<void> {
  await api.delete(`/notifications/${id}`);
}
