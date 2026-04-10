import * as svc from './admin.passengers.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';
import { buildPagination } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { status, search, page = 1, page_size = 20 } = req.query;
    const result = await svc.listPassengers({
      status, search,
      page: Number(page), pageSize: Number(page_size),
    });
    sendSuccess(res, result.data, 'Passengers', 200,
      buildPagination(result.total, result.page, result.pageSize));
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getPassengerById(req.params.id);
    sendSuccess(res, data, 'Passenger detail');
  } catch (err) { next(err); }
}

export async function create(req, res, next) {
  try {
    const { full_name, email, password, username, phone, nic } = req.body;
    const data = await svc.createPassenger(
      { fullName: full_name, email, password, username, phone, nic },
      req.admin,
    );
    sendSuccess(res, data, 'Passenger created', 201);
  } catch (err) { next(err); }
}

export async function suspend(req, res, next) {
  try {
    const data = await svc.setPassengerStatus(req.params.id, false, req.admin);
    sendSuccess(res, data, 'Passenger suspended');
  } catch (err) { next(err); }
}

export async function activate(req, res, next) {
  try {
    const data = await svc.setPassengerStatus(req.params.id, true, req.admin);
    sendSuccess(res, data, 'Passenger activated');
  } catch (err) { next(err); }
}

export async function remove(req, res, next) {
  try {
    await svc.deletePassenger(req.params.id, req.admin);
    sendSuccess(res, null, 'Passenger deleted');
  } catch (err) { next(err); }
}
