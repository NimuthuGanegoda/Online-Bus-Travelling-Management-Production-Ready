import * as svc from './admin.notifications.service.js';
import { sendSuccess, buildPagination } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const { unread_only, page = 1, page_size = 50 } = req.query;
    const result = await svc.getNotifications(req.admin.id, {
      unreadOnly: unread_only === 'true',
      page: Number(page),
      pageSize: Number(page_size),
    });
    sendSuccess(res, result.data, 'Notifications', 200,
      buildPagination(result.total, result.page, result.pageSize));
  } catch (err) { next(err); }
}

export async function readOne(req, res, next) {
  try {
    const data = await svc.markOneRead(req.admin.id, req.params.id);
    sendSuccess(res, data, 'Notification marked as read');
  } catch (err) { next(err); }
}

export async function readAll(req, res, next) {
  try {
    await svc.markAllRead(req.admin.id);
    sendSuccess(res, null, 'All notifications marked as read');
  } catch (err) { next(err); }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteNotification(req.admin.id, req.params.id);
    sendSuccess(res, null, 'Notification deleted');
  } catch (err) { next(err); }
}
