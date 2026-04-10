import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.buses.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/buses          — list all buses (filterable)
router.get('/',            ctrl.list);

// POST /api/admin/buses          — register a new bus
router.post('/',           ctrl.register);

// GET  /api/admin/buses/stats    — fleet totals
router.get('/stats',       ctrl.stats);

// GET  /api/admin/buses/:id      — single bus detail
router.get('/:id',         ctrl.getOne);

// PATCH /api/admin/buses/:id             — update driver / route / registration
router.patch('/:id',       ctrl.updateAssignment);

// PATCH /api/admin/buses/:id/status      — recall / repair / standby / activate
router.patch('/:id/status', ctrl.updateStatus);

export default router;
