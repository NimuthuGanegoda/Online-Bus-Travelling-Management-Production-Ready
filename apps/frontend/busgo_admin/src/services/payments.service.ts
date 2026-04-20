import api from './api';

export interface Payment {
  id: string;
  payment_method: 'credit_card' | 'debit_card';
  card_holder_name: string;
  masked_card: string;
  amount_lkr: number;
  status: 'success' | 'failed';
  created_at: string;
  users: {
    id: string;
    full_name: string;
    email: string;
  } | null;
}

export async function fetchPayments(params?: {
  page?: number;
  page_size?: number;
  status?: string;
}): Promise<{ payments: Payment[]; total: number }> {
  const { data } = await api.get('/payments', { params });
  return {
    payments: data.data as Payment[],
    total: data.pagination?.total ?? 0,
  };
}
