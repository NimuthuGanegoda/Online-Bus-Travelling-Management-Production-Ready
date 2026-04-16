import crypto from 'crypto';
import { supabase } from '../../../config/supabase.js';
import { env } from '../../../config/env.js';
import {
  signAdminAccessToken,
  signAdminRefreshToken,
  verifyAdminRefreshToken,
} from '../../../utils/jwt.utils.js';
import { comparePassword } from '../../../utils/password.utils.js';
import { createAuditLog } from '../../../utils/audit.utils.js';

function sha256(str) {
  return crypto.createHash('sha256').update(str).digest('hex');
}

async function issueAdminTokenPair(adminId) {
  const accessToken  = signAdminAccessToken({ id: adminId });
  const refreshToken = signAdminRefreshToken({ id: adminId });
  const tokenHash    = sha256(refreshToken);

  const expiresAt = new Date(Date.now() + env.JWT_REFRESH_EXPIRES_IN * 1000).toISOString();

  await supabase.from('admin_refresh_tokens').insert({
    admin_id:   adminId,
    token_hash: tokenHash,
    expires_at: expiresAt,
  });

  return { access_token: accessToken, refresh_token: refreshToken };
}

export async function adminLogin(email, password, ip) {
  const { data: admin, error } = await supabase
    .from('admins')
    .select('id, full_name, email, phone, role, status, password_hash')
    .eq('email', email.toLowerCase())
    .single();

  if (error || !admin) {
    throw Object.assign(new Error('Invalid email or password'), { statusCode: 401 });
  }

  if (admin.status !== 'active') {
    throw Object.assign(new Error('Account is inactive'), { statusCode: 403 });
  }

  const valid = await comparePassword(password, admin.password_hash);
  if (!valid) {
    throw Object.assign(new Error('Invalid email or password'), { statusCode: 401 });
  }

  // Update last_login
  await supabase.from('admins').update({ last_login: new Date().toISOString() }).eq('id', admin.id);

  const tokens = await issueAdminTokenPair(admin.id);

  createAuditLog({
    adminId: admin.id, adminEmail: admin.email,
    action: 'LOGIN', entity: 'AdminSession', entityId: admin.id,
    details: 'Admin login', ip,
  });

  const { password_hash: _, ...safeAdmin } = admin;
  return { ...tokens, admin: { ...safeAdmin, last_login: new Date().toISOString() } };
}

export async function adminLogout(adminId, rawRefreshToken, ip) {
  const tokenHash = sha256(rawRefreshToken ?? '');
  await supabase
    .from('admin_refresh_tokens')
    .delete()
    .eq('admin_id', adminId)
    .eq('token_hash', tokenHash);

  createAuditLog({
    adminId, adminEmail: '',
    action: 'LOGOUT', entity: 'AdminSession', entityId: adminId,
    details: 'Admin logout', ip,
  });
}

export async function adminRefresh(rawRefreshToken) {
  let decoded;
  try {
    decoded = verifyAdminRefreshToken(rawRefreshToken);
  } catch {
    throw Object.assign(new Error('Invalid or expired refresh token'), { statusCode: 401 });
  }

  const tokenHash = sha256(rawRefreshToken);
  const now = new Date().toISOString();

  const { data: stored } = await supabase
    .from('admin_refresh_tokens')
    .select('id')
    .eq('admin_id', decoded.id)
    .eq('token_hash', tokenHash)
    .gt('expires_at', now)
    .single();

  if (!stored) {
    throw Object.assign(new Error('Refresh token not recognized'), { statusCode: 401 });
  }

  // Rotate — delete old, issue new
  await supabase.from('admin_refresh_tokens').delete().eq('id', stored.id);

  return issueAdminTokenPair(decoded.id);
}
