import * as svc from './admin.emergency.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';
import { buildPagination } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { status, type, priority, search, page = 1, page_size = 50 } = req.query;
    const result = await svc.listAlerts({
      status, type, priority, search,
      page: Number(page), pageSize: Number(page_size),
    });
    sendSuccess(res, result.data, 'Emergency alerts', 200,
      buildPagination(result.total, result.page, result.pageSize));
  } catch (err) { next(err); }
}

export async function alertStats(req, res, next) {
  try {
    const data = await svc.getAlertStats();
    sendSuccess(res, data, 'Alert stats');
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getAlertById(req.params.id);
    sendSuccess(res, data, 'Alert detail');
  } catch (err) { next(err); }
}

export async function updateStatus(req, res, next) {
  try {
    const data = await svc.updateAlertStatus(req.params.id, req.body.status, req.admin);
    sendSuccess(res, data, 'Alert status updated');
  } catch (err) { next(err); }
}

export async function setPoliceNotified(req, res, next) {
  try {
    const data = await svc.updatePoliceNotified(
      req.params.id, req.body.police_notified, req.admin,
    );
    sendSuccess(res, data, 'Police notified flag updated');
  } catch (err) { next(err); }
}

export async function deployBus(req, res, next) {
  try {
    const data = await svc.deployStandbyBus(
      req.params.id, req.body.bus_id, req.admin,
    );
    sendSuccess(res, data, 'Standby bus deployed');
  } catch (err) { next(err); }
}
