import { supabase } from '../../../config/supabase.js';

/**
 * Return all payments for admin view, joined with user info.
 */
export async function listAllPayments({ page = 1, page_size = 20, status } = {}) {
  const offset = (page - 1) * page_size;

  let query = supabase
    .from('payments')
    .select(
      `id, payment_method, card_holder_name, masked_card, amount_lkr, status, created_at,
       users ( id, full_name, email )`,
      { count: 'exact' },
    )
    .order('created_at', { ascending: false })
    .range(offset, offset + page_size - 1);

  if (status) query = query.eq('status', status);

  const { data, error, count } = await query;
  if (error) throw error;

  return { payments: data, total: count };
}
