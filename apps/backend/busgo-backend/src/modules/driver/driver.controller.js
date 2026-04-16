import * as authSvc from './driver.auth.service.js';
import * as svc from './driver.service.js';
import { sendSuccess, sendError } from '../../utils/response.utils.js';

// ── Auth ──────────────────────────────────────────────────────

export async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return sendError(res, 'email and password are required', 400, 'VALIDATION_ERROR');
    }
    const result = await authSvc.loginDriver({ email, password });
    sendSuccess(res, result, 'Login successful');
  } catch (err) { next(err); }
}

export async function register(req, res, next) {
  try {
    const { full_name, email, phone, password } = req.body;
    if (!full_name || !email || !password) {
      return sendError(res, 'full_name, email and password are required', 400, 'VALIDATION_ERROR');
    }
    const result = await authSvc.registerDriver({ full_name, email, phone, password });
    sendSuccess(res, result, 'Registration submitted. Await admin approval.', 201);
  } catch (err) { next(err); }
}

// ── Profile & data ────────────────────────────────────────────

export async function getMe(req, res, next) {
  try {
    const data = await svc.getDriverMe(req.driver.id);
    sendSuccess(res, data, 'Driver profile');
  } catch (err) { next(err); }
}

export async function getRoute(req, res, next) {
  try {
    const data = await svc.getDriverRoute(req.driver.id);
    sendSuccess(res, data, 'Assigned route');
  } catch (err) { next(err); }
}

export async function updateLocation(req, res, next) {
  try {
    const { latitude, longitude, speed, heading } = req.body;
    if (latitude == null || longitude == null) {
      return sendError(res, 'latitude and longitude are required', 400, 'VALIDATION_ERROR');
    }
    const data = await svc.updateDriverLocation(req.driver.id, { latitude, longitude, speed, heading });
    sendSuccess(res, data, 'Location updated');
  } catch (err) { next(err); }
}

export async function updatePassengers(req, res, next) {
  try {
    const { crowd_level } = req.body;
    if (!crowd_level) {
      return sendError(res, 'crowd_level is required', 400, 'VALIDATION_ERROR');
    }
    const data = await svc.updatePassengerCount(req.driver.id, { crowd_level });
    sendSuccess(res, data, 'Passenger count updated');
  } catch (err) { next(err); }
}

export async function createAlert(req, res, next) {
  try {
    const { alert_type, description, latitude, longitude, priority } = req.body;
    if (!alert_type) {
      return sendError(res, 'alert_type is required', 400, 'VALIDATION_ERROR');
    }
    const data = await svc.createDriverAlert(req.driver.id, { alert_type, description, latitude, longitude, priority });
    sendSuccess(res, data, 'Emergency alert sent', 201);
  } catch (err) { next(err); }
}
