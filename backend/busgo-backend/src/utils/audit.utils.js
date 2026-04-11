import { supabase } from '../config/supabase.js';
import { logger } from './logger.js';

/**
 * Write a row to admin_audit_logs.
 * Fire-and-forget — never throws, never blocks the response.
 *
 * @param {{
 *   adminId:    string | null,
 *   adminEmail: string,
 *   action:     'LOGIN'|'LOGOUT'|'CREATE'|'UPDATE'|'DELETE'|'RESOLVE'|'DEPLOY'|'APPROVE'|'REJECT'|'SUSPEND',
 *   entity:     string,
 *   entityId?:  string,
 *   details?:   string,
 *   ip?:        string,
 * }} opts
 */
export async function createAuditLog({ adminId, adminEmail, action, entity, entityId, details, ip }) {
  try {
    await supabase.from('admin_audit_logs').insert({
      admin_id:    adminId   ?? null,
      admin_email: adminEmail,
      action,
      entity,
      entity_id:   entityId  ?? null,
      details:     details   ?? null,
      ip_address:  ip        ?? null,
    });
  } catch (err) {
    logger.warn(`Audit log write failed: ${err.message}`);
  }
}
