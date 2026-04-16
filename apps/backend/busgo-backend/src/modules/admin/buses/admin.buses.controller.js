import * as svc from './admin.buses.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { status, route_id, search } = req.query;
    const data = await svc.getAllBuses({ status, routeId: route_id, search });
    sendSuccess(res, data, 'Fleet list');
  } catch (err) { next(err); }
}

export async function stats(req, res, next) {
  try {
    const data = await svc.getFleetStats();
    sendSuccess(res, data, 'Fleet stats');
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getBusById(req.params.id);
    sendSuccess(res, data, 'Bus detail');
  } catch (err) { next(err); }
}

export async function register(req, res, next) {
  try {
    const { bus_number, route_id, registration, driver_name, driver_phone } = req.body;
    const data = await svc.registerBus(
      { busNumber: bus_number, routeId: route_id, registration, driverName: driver_name, driverPhone: driver_phone },
      req.admin,
    );
    sendSuccess(res, data, 'Bus registered', 201);
  } catch (err) { next(err); }
}

export async function updateAssignment(req, res, next) {
  try {
    const data = await svc.updateBusAssignment(req.params.id, req.body, req.admin);
    sendSuccess(res, data, 'Bus updated');
  } catch (err) { next(err); }
}

export async function updateStatus(req, res, next) {
  try {
    const { status } = req.body;
    const data = await svc.updateBusStatus(req.params.id, status, req.admin);
    sendSuccess(res, data, `Bus status set to ${status}`);
  } catch (err) { next(err); }
}
