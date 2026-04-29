import { supabase } from '../../config/supabase.js';
import { hashPassword, comparePassword } from '../../utils/password.utils.js';
import { signDriverAccessToken, signResetToken, verifyResetToken } from '../../utils/jwt.utils.js';
import { generatePin, hashPin, verifyPin } from '../../utils/pin.utils.js';
import { logger } from '../../utils/logger.js';
import { CONSTANTS } from '../../config/constants.js';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';

/**
 * Issue a long-lived (7-day) driver access token.
 * Avoids the need for a separate driver_refresh_tokens table.
 */
function issueDriverToken(driverId, email) {
  return jwt.sign(
    { id: driverId, email },
    env.JWT_ACCESS_SECRET,
    { expiresIn: '7d', issuer: 'busgo-api', audience: 'busgo-driver' },
  );
}

/**
 * Login with email + password.
 * Default password is the driver_code (e.g. DRV-001) until the driver sets their own.
 */
export async function loginDriver({ email, password }) {
  // Accept email address OR driver_code (e.g. DRV-001) as the identifier
  const identifier = email.trim();
  const isEmail = identifier.includes('@');

  let query = supabase
    .from('drivers')
    .select('id, driver_code, full_name, email, phone, rating, status, pending_review, route_id, password_hash, bus_routes(id, route_number, route_name, color, origin, destination)');

  query = isEmail
    ? query.eq('email', identifier.toLowerCase())
    : query.ilike('driver_code', identifier);   // case-insensitive match e.g. drv-001 == DRV-001

  const { data: driver, error } = await query.maybeSingle();

  if (error || !driver) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  if (driver.status === 'inactive') {
    const err = new Error('Account is deactivated. Contact your administrator.');
    err.statusCode = 403;
    throw err;
  }

  // Verify password — use bcrypt hash if set, otherwise driver_code is the default password
  let valid = false;
  if (driver.password_hash) {
    valid = await comparePassword(password, driver.password_hash);
  } else {
    valid = (password === driver.driver_code);
  }

  if (!valid) {
    const err = new Error('Invalid email or password');
    err.statusCode = 401;
    throw err;
  }

  const access_token = issueDriverToken(driver.id, driver.email);
  const { password_hash: _, ...safeDriver } = driver;
  return { driver: safeDriver, access_token };
}

/**
 * Register a new driver (pending admin approval).
 */
export async function registerDriver({ full_name, email, phone, password }) {
  const { data: existing } = await supabase
    .from('drivers')
    .select('id')
    .eq('email', email.toLowerCase().trim())
    .maybeSingle();

  if (existing) {
    const err = new Error('Email already registered');
    err.statusCode = 409;
    throw err;
  }

  // Generate next driver_code
  const { data: allDrivers } = await supabase.from('drivers').select('driver_code');
  const nums = (allDrivers ?? [])
    .map((d) => parseInt(d.driver_code?.replace('DRV-', '') ?? '0', 10))
    .filter(Boolean);
  const next = nums.length ? Math.max(...nums) + 1 : 1;
  const driver_code = `DRV-${String(next).padStart(3, '0')}`;

  const password_hash = await hashPassword(password);

  const { data: driver, error } = await supabase
    .from('drivers')
    .insert({
      driver_code,
      full_name:      full_name.trim(),
      email:          email.toLowerCase().trim(),
      phone:          phone?.trim() || null,
      password_hash,
      status:         'pending',
      pending_review: true,
    })
    .select('id, driver_code, full_name, email, phone, rating, status, pending_review')
    .single();

  if (error) throw error;

  const access_token = issueDriverToken(driver.id, driver.email);
  return { driver, access_token };
}

// ═══════════════════════════════════════════════════════════════════
//  FR-28 / FR-29 — Driver password recovery (3-step PIN flow)
//  Same pattern as the user-side flow in modules/auth/auth.service.js
// ═══════════════════════════════════════════════════════════════════

/**
 * Step 1 — Send a 6-digit reset PIN to the driver. Always responds with
 * success so attackers can't probe which emails exist. PIN is logged to
 * the server console (replace with email service in production).
 */
export async function requestDriverPasswordReset(email) {
  const { data: driver } = await supabase
    .from('drivers')
    .select('id, full_name')
    .eq('email', email.toLowerCase().trim())
    .maybeSingle();

  if (!driver) return; // silent — prevent enumeration

  const pin       = generatePin();
  const pinHash   = await hashPin(pin);
  const expiresAt = new Date(Date.now() + CONSTANTS.RESET_PIN_EXPIRES_MS).toISOString();

  await supabase
    .from('drivers')
    .update({ reset_pin: pinHash, reset_pin_expires_at: expiresAt })
    .eq('id', driver.id);

  logger.info(`🔑 Driver reset PIN for ${email}: ${pin}  (expires ${expiresAt})`);
  console.log(`\n=================================`);
  console.log(`  BusGo DRIVER Password Reset PIN`);
  console.log(`  Email : ${email}`);
  console.log(`  PIN   : ${pin}`);
  console.log(`  Exp   : ${expiresAt}`);
  console.log(`=================================\n`);
}

/**
 * Step 2 — Verify the PIN. Returns a short-lived reset_token JWT
 * that the client uses to perform the actual password change.
 */
export async function verifyDriverResetPin(email, pin) {
  const { data: driver } = await supabase
    .from('drivers')
    .select('id, reset_pin, reset_pin_expires_at')
    .eq('email', email.toLowerCase().trim())
    .maybeSingle();

  if (!driver || !driver.reset_pin) {
    const err = new Error('Invalid or expired PIN');
    err.statusCode = 400;
    err.code = 'INVALID_PIN';
    throw err;
  }

  if (new Date(driver.reset_pin_expires_at) < new Date()) {
    const err = new Error('PIN has expired. Please request a new one.');
    err.statusCode = 400;
    err.code = 'PIN_EXPIRED';
    throw err;
  }

  const ok = await verifyPin(pin, driver.reset_pin);
  if (!ok) {
    const err = new Error('Invalid or expired PIN');
    err.statusCode = 400;
    err.code = 'INVALID_PIN';
    throw err;
  }

  return { reset_token: signResetToken({ id: driver.id, email }) };
}

/**
 * Step 3 — Verify reset_token, set new password, clear PIN fields.
 */
export async function resetDriverPassword({ reset_token, new_password }) {
  let decoded;
  try {
    decoded = verifyResetToken(reset_token);
  } catch {
    const err = new Error('Invalid or expired reset token');
    err.statusCode = 400;
    err.code = 'INVALID_RESET_TOKEN';
    throw err;
  }

  const password_hash = await hashPassword(new_password);
  const { error } = await supabase
    .from('drivers')
    .update({
      password_hash,
      reset_pin: null,
      reset_pin_expires_at: null,
    })
    .eq('id', decoded.id);

  if (error) throw error;
}
