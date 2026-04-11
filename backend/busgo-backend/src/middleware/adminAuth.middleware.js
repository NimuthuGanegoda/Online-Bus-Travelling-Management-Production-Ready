import { supabase } from '../config/supabase.js';
import { verifyAdminAccessToken } from '../utils/jwt.utils.js';
import { sendError } from '../utils/response.utils.js';

/**
 * verifyAdmin — reads Bearer token, verifies admin JWT audience,
 * fetches the admin row and attaches req.admin.
 */
export async function verifyAdmin(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return sendError(res, 'Admin authorization token required', 401, 'ADMIN_TOKEN_REQUIRED');
  }

  const token = authHeader.slice(7);

  let decoded;
  try {
    decoded = verifyAdminAccessToken(token);
  } catch {
    return sendError(res, 'Invalid or expired admin token', 401, 'ADMIN_TOKEN_INVALID');
  }

  const { data: admin, error } = await supabase
    .from('admins')
    .select('id, full_name, email, role, status')
    .eq('id', decoded.id)
    .single();

  if (error || !admin) {
    return sendError(res, 'Admin account not found', 401, 'ADMIN_NOT_FOUND');
  }

  if (admin.status !== 'active') {
    return sendError(res, 'Admin account is inactive', 403, 'ADMIN_INACTIVE');
  }

  req.admin = admin;
  next();
}

/**
 * requireRole(...roles) — middleware factory.
 * Must be used AFTER verifyAdmin.
 *
 * @param {...('super_admin'|'admin'|'moderator')} roles
 */
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.admin) {
      return sendError(res, 'Authentication required', 401, 'ADMIN_TOKEN_REQUIRED');
    }
    if (!roles.includes(req.admin.role)) {
      return sendError(res, 'Insufficient permissions', 403, 'ADMIN_FORBIDDEN');
    }
    next();
  };
}
