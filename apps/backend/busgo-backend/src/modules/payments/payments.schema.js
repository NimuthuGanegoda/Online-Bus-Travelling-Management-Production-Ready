import Joi from 'joi';

export const createPaymentSchema = Joi.object({
  payment_method:   Joi.string().valid('credit_card', 'debit_card').required(),
  card_holder_name: Joi.string().trim().min(2).max(100).required(),
  card_number:      Joi.string().pattern(/^\d{16}$/).required().messages({
    'string.pattern.base': 'Card number must be exactly 16 digits',
  }),
  expiry_date: Joi.string().pattern(/^(0[1-9]|1[0-2])\/\d{2}$/).required().messages({
    'string.pattern.base': 'Expiry date must be in MM/YY format',
  }),
  cvv: Joi.string().pattern(/^\d{3,4}$/).required().messages({
    'string.pattern.base': 'CVV must be 3 or 4 digits',
  }),
  amount_lkr: Joi.number().positive().required(),
});
