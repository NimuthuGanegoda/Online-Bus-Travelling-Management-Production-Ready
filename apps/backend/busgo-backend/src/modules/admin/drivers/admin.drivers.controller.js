import * as svc from './admin.drivers.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { status, route_id, search, pending } = req.query;
    const data = await svc.listDrivers({
      status, routeId: route_id, search, pendingOnly: pending === 'true',
    });
    sendSuccess(res, data, 'Drivers list');
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getDriverById(req.params.id);
    sendSuccess(res, data, 'Driver detail');
  } catch (err) { next(err); }
}

export async function create(req, res, next) {
  try {
    const data = await svc.createDriver(req.body, req.admin);
    sendSuccess(res, data, 'Driver created', 201);
  } catch (err) { next(err); }
}

export async function update(req, res, next) {
  try {
    const data = await svc.updateDriver(req.params.id, req.body, req.admin);
    sendSuccess(res, data, 'Driver updated');
  } catch (err) { next(err); }
}

export async function approve(req, res, next) {
  try {
    const data = await svc.approveDriver(req.params.id, req.admin);
    sendSuccess(res, data, 'Driver approved');
  } catch (err) { next(err); }
}

export async function reject(req, res, next) {
  try {
    await svc.rejectDriver(req.params.id, req.admin);
    sendSuccess(res, null, 'Driver application rejected');
  } catch (err) { next(err); }
}

export async function setStatus(req, res, next) {
  try {
    const data = await svc.setDriverStatus(req.params.id, req.body.status, req.admin);
    sendSuccess(res, data, 'Driver status updated');
  } catch (err) { next(err); }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteDriver(req.params.id, req.admin);
    sendSuccess(res, null, 'Driver deleted');
  } catch (err) { next(err); }
}
