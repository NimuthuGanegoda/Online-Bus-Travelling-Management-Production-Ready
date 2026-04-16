import { supabase } from '../../config/supabase.js';
import { hashPassword, comparePassword } from '../../utils/password.utils.js';
import { signDriverAccessToken } from '../../utils/jwt.utils.js';
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
