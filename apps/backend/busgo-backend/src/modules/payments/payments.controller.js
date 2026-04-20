import * as paymentsService from './payments.service.js';
import { sendSuccess, sendError } from '../../utils/response.utils.js';

export async function createPayment(req, res, next) {
  try {
    const payment = await paymentsService.createPayment(req.user.id, req.body);
    return sendSuccess(res, payment, `Payment ${payment.status}`, 201);
  } catch (err) {
    if (err.statusCode) return sendError(res, err.message, err.statusCode, err.code);
    next(err);
  }
}

export async function listMyPayments(req, res, next) {
  try {
    const payments = await paymentsService.listMyPayments(req.user.id);
    return sendSuccess(res, payments, 'Payments fetched');
  } catch (err) {
    next(err);
  }
}
