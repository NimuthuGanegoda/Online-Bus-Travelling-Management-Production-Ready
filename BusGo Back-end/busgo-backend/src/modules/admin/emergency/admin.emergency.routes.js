import { Router } from 'express';
import { verifyAdmin, requireRole } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.emergency.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/emergency              — all alerts (filterable)
router.get('/',            ctrl.list);

// GET  /api/admin/emergency/stats        — summary counts
router.get('/stats',       ctrl.alertStats);

// GET  /api/admin/emergency/:id          — single alert detail
router.get('/:id',         ctrl.getOne);

// PATCH /api/admin/emergency/:id/status  — NEW→RESPONDED→RESOLVED
router.patch('/:id/status',
  requireRole('super_admin', 'admin'),
  ctrl.updateStatus,
);

// PATCH /api/admin/emergency/:id/police  — toggle police_notified
router.patch('/:id/police',
  requireRole('super_admin', 'admin'),
  ctrl.setPoliceNotified,
);

// POST /api/admin/emergency/:id/deploy-bus  — deploy standby bus
router.post('/:id/deploy-bus',
  requireRole('super_admin', 'admin'),
  ctrl.deployBus,
);

export default router;
