import { z } from 'zod';

// Validates POST /api/payments. Uses Zod to match the rest of the codebase
// (the shared validate.middleware.js calls schema.safeParse).
export const createPaymentSchema = z.object({
  payment_method: z.enum(['credit_card', 'debit_card'], {
    errorMap: () => ({
      message: 'payment_method must be credit_card or debit_card',
    }),
  }),
  card_holder_name: z.string().trim().min(2).max(100),
  card_number: z
    .string()
    .regex(/^\d{16}$/, 'Card number must be exactly 16 digits'),
  expiry_date: z
    .string()
    .regex(/^(0[1-9]|1[0-2])\/\d{2}$/, 'Expiry date must be in MM/YY format'),
  cvv: z.string().regex(/^\d{3,4}$/, 'CVV must be 3 or 4 digits'),
  amount_lkr: z.coerce.number().positive(),
});
