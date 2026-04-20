import { supabase } from '../../config/supabase.js';

/**
 * Simulate a payment and persist a masked record.
 * Card details are NEVER stored — only last 4 digits are kept.
 */
export async function createPayment(userId, dto) {
  const { payment_method, card_holder_name, card_number, amount_lkr } = dto;

  // Mask card — keep only last 4 digits
  const masked_card = `****${card_number.slice(-4)}`;

  // Simulate: fail ~10 % of the time so the UI can demo both states
  const status = Math.random() < 0.1 ? 'failed' : 'success';

  const { data, error } = await supabase
    .from('payments')
    .insert({
      user_id: userId,
      payment_method,
      card_holder_name: card_holder_name.trim(),
      masked_card,
      amount_lkr,
      status,
    })
    .select('id, payment_method, card_holder_name, masked_card, amount_lkr, status, created_at')
    .single();

  if (error) throw error;
  return data;
}

/**
 * Return the authenticated user's payment history.
 */
export async function listMyPayments(userId) {
  const { data, error } = await supabase
    .from('payments')
    .select('id, payment_method, card_holder_name, masked_card, amount_lkr, status, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data;
}
