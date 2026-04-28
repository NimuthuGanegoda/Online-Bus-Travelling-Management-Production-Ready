import * as service from './scanner.service.js';
import { sendSuccess, sendError } from '../../utils/response.utils.js';

/**
 * POST /api/scanner/scan
 * Driver scans a passenger QR card. Returns whether the passenger
 * boarded or alighted, plus a short verifying message.
 */
export async function scan(req, res, next) {
  try {
    const result = await service.recordScan(req.driver.id, req.body);
    return sendSuccess(res, result, result.message);
  } catch (err) {
    if (err.statusCode) return sendError(res, err.message, err.statusCode, err.code);
    next(err);
  }
}
