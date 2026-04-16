import { supabase } from '../config/supabase.js';
import { verifyDriverAccessToken } from '../utils/jwt.utils.js';
import { sendError } from '../utils/response.utils.js';

export async function verifyDriver(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return sendError(res, 'Driver authorization token required', 401, 'DRIVER_TOKEN_REQUIRED');
  }

  const token = authHeader.slice(7);

  let decoded;
  try {
    decoded = verifyDriverAccessToken(token);
  } catch {
    return sendError(res, 'Invalid or expired driver token', 401, 'DRIVER_TOKEN_INVALID');
  }

  const { data: driver, error } = await supabase
    .from('drivers')
    .select('id, driver_code, full_name, email, phone, rating, status, pending_review, route_id, bus_routes(id, route_number, route_name, color, origin, destination)')
    .eq('id', decoded.id)
    .single();

  if (error || !driver) {
    return sendError(res, 'Driver account not found', 401, 'DRIVER_NOT_FOUND');
  }

  if (driver.status === 'inactive') {
    return sendError(res, 'Driver account is inactive', 403, 'DRIVER_INACTIVE');
  }

  req.driver = driver;
  next();
}
