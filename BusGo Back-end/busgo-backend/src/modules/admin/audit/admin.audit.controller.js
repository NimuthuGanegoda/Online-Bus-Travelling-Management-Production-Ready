import { listAuditLogs } from './admin.audit.service.js';
import { sendSuccess, buildPagination } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { action, entity, admin_email, search, page = 1, page_size = 50 } = req.query;
    const result = await listAuditLogs({
      action, entity, adminEmail: admin_email, search,
      page: Number(page), pageSize: Number(page_size),
    });
    sendSuccess(res, result.data, 'Audit logs', 200,
      buildPagination(result.total, result.page, result.pageSize));
  } catch (err) { next(err); }
}
