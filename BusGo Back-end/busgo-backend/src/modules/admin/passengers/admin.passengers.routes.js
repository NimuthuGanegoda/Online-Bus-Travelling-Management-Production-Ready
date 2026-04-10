import { Router } from 'express';
import { verifyAdmin, requireRole } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.passengers.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/passengers              — list (status, search, page, page_size)
router.get('/',              ctrl.list);

// POST /api/admin/passengers              — create passenger account
router.post('/',
  requireRole('super_admin', 'admin'),
  ctrl.create,
);

// GET  /api/admin/passengers/:id          — detail with trip history
router.get('/:id',           ctrl.getOne);

// PATCH /api/admin/passengers/:id/suspend
router.patch('/:id/suspend',
  requireRole('super_admin', 'admin'),
  ctrl.suspend,
);

// PATCH /api/admin/passengers/:id/activate
router.patch('/:id/activate',
  requireRole('super_admin', 'admin'),
  ctrl.activate,
);

// DELETE /api/admin/passengers/:id
router.delete('/:id',
  requireRole('super_admin'),
  ctrl.remove,
);

export default router;
