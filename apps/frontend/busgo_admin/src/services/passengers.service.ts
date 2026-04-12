import api from './api';
import type { Passenger } from '../types';
import { mapPassenger } from './mappers';

export async function fetchPassengers(params?: {
  status?: string;
  search?: string;
  page?: number;
}): Promise<Passenger[]> {
  const { data: res } = await api.get('/passengers', { params });
  return (res.data ?? []).map(mapPassenger);
}

export async function suspendPassenger(id: string): Promise<void> {
  await api.patch(`/passengers/${id}/suspend`);
}

export async function activatePassenger(id: string): Promise<void> {
  await api.patch(`/passengers/${id}/activate`);
}

export async function deletePassenger(id: string): Promise<void> {
  await api.delete(`/passengers/${id}`);
}

export async function createPassenger(payload: {
  full_name: string;
  email: string;
  password: string;
  username?: string;
  phone?: string;
  nic?: string;
}): Promise<Passenger> {
  const { data: res } = await api.post('/passengers', payload);
  return mapPassenger(res.data);
}
