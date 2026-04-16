import * as svc from './admin.admins.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { status, search } = req.query;
    const data = await svc.listAdmins({ status, search });
    sendSuccess(res, data, 'Admins list');
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getAdminById(req.params.id);
    sendSuccess(res, data, 'Admin detail');
  } catch (err) { next(err); }
}

export async function create(req, res, next) {
  try {
    const data = await svc.createAdmin(req.body, req.admin);
    sendSuccess(res, data, 'Admin created', 201);
  } catch (err) { next(err); }
}

export async function update(req, res, next) {
  try {
    const data = await svc.updateAdmin(req.params.id, req.body, req.admin);
    sendSuccess(res, data, 'Admin updated');
  } catch (err) { next(err); }
}

export async function toggleStatus(req, res, next) {
  try {
    const data = await svc.toggleAdminStatus(req.params.id, req.admin);
    sendSuccess(res, data, 'Admin status toggled');
  } catch (err) { next(err); }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteAdmin(req.params.id, req.admin);
    sendSuccess(res, null, 'Admin deleted');
  } catch (err) { next(err); }
}
