import * as service from './admin.payments.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function listAllPayments(req, res, next) {
  try {
    const { page = 1, page_size = 20, status } = req.query;
    const result = await service.listAllPayments({
      page: Number(page),
      page_size: Number(page_size),
      status,
    });
    return sendSuccess(res, result.payments, 'Payments fetched', 200, {
      total: result.total,
      page: Number(page),
      page_size: Number(page_size),
    });
  } catch (err) {
    next(err);
  }
}
