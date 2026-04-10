import { getDashboardStats, getLiveMapBuses } from './admin.dashboard.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function stats(req, res, next) {
  try {
    const data = await getDashboardStats();
    sendSuccess(res, data, 'Dashboard stats');
  } catch (err) {
    next(err);
  }
}

export async function liveMap(req, res, next) {
  try {
    const data = await getLiveMapBuses();
    sendSuccess(res, data, 'Live map buses');
  } catch (err) {
    next(err);
  }
}
