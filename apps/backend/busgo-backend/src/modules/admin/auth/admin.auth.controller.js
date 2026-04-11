import { adminLogin, adminLogout, adminRefresh } from './admin.auth.service.js';
import { sendSuccess, sendError } from '../../../utils/response.utils.js';

export async function login(req, res, next) {
  try {
    const result = await adminLogin(req.body.email, req.body.password, req.ip);
    sendSuccess(res, result, 'Admin login successful');
  } catch (err) {
    err.statusCode ? sendError(res, err.message, err.statusCode) : next(err);
  }
}

export async function logout(req, res, next) {
  try {
    await adminLogout(req.admin.id, req.body.refresh_token, req.ip);
    sendSuccess(res, null, 'Logged out successfully');
  } catch (err) {
    next(err);
  }
}

export async function refresh(req, res, next) {
  try {
    const tokens = await adminRefresh(req.body.refresh_token);
    sendSuccess(res, tokens, 'Tokens refreshed');
  } catch (err) {
    err.statusCode ? sendError(res, err.message, err.statusCode) : next(err);
  }
}

export async function me(req, res) {
  sendSuccess(res, req.admin, 'Admin profile');
}
