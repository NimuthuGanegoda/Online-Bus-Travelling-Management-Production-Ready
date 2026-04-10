import api from './api';
import type { AuditLog } from '../types';
import { mapAuditLog } from './mappers';

export interface AuditResult {
  data: AuditLog[];
  total: number;
  page: number;
  pageSize: number;
}

export async function fetchAuditLogs(params?: {
  action?: string;
  entity?: string;
  admin_email?: string;
  search?: string;
  page?: number;
  page_size?: number;
}): Promise<AuditResult> {
  const { data: res } = await api.get('/audit', { params });
  return {
    data:     (res.data ?? []).map(mapAuditLog),
    total:    res.pagination?.total    ?? 0,
    page:     res.pagination?.page     ?? 1,
    pageSize: res.pagination?.pageSize ?? 50,
  };
}
