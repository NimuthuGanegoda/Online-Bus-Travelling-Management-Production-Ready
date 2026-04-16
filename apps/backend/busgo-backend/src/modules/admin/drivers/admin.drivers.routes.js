import { Router } from 'express';
import { verifyAdmin, requireRole } from '../../../middleware/adminAuth.middleware.js';
import { validate } from '../../../middleware/validate.middleware.js';
import { createDriverSchema, updateDriverSchema } from './admin.drivers.schema.js';
import * as ctrl from './admin.drivers.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/drivers              — list (filterable: status, route_id, search, pending=true)
router.get('/',                    ctrl.list);

// GET  /api/admin/drivers/:id          — single driver
router.get('/:id',                 ctrl.getOne);

// POST /api/admin/drivers              — create (admin+)
router.post('/',
  requireRole('super_admin', 'admin'),
  validate(createDriverSchema),
  ctrl.create,
);

// PATCH /api/admin/drivers/:id         — edit details
router.patch('/:id',
  requireRole('super_admin', 'admin'),
  validate(updateDriverSchema),
  ctrl.update,
);

// PATCH /api/admin/drivers/:id/approve — approve pending driver
router.patch('/:id/approve',
  requireRole('super_admin', 'admin'),
  ctrl.approve,
);

// PATCH /api/admin/drivers/:id/reject  — reject pending driver
router.patch('/:id/reject',
  requireRole('super_admin', 'admin'),
  ctrl.reject,
);

// PATCH /api/admin/drivers/:id/status  — activate / deactivate
router.patch('/:id/status',
  requireRole('super_admin', 'admin'),
  ctrl.setStatus,
);

// DELETE /api/admin/drivers/:id        — super_admin only
router.delete('/:id',
  requireRole('super_admin'),
  ctrl.remove,
);

export default router;
