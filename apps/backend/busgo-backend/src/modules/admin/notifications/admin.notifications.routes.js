import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.notifications.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/notifications?unread_only=true&page=&page_size=
router.get('/',              ctrl.list);

// PATCH /api/admin/notifications/read-all
router.patch('/read-all',    ctrl.readAll);

// PATCH /api/admin/notifications/:id/read
router.patch('/:id/read',   ctrl.readOne);

// DELETE /api/admin/notifications/:id
router.delete('/:id',        ctrl.remove);

export default router;
