import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.routes.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/routes          — list all routes (?all=true includes inactive)
router.get('/',            ctrl.list);

// POST /api/admin/routes          — create new route
router.post('/',           ctrl.create);

// GET  /api/admin/routes/:id      — single route detail
router.get('/:id',         ctrl.getOne);

// PATCH /api/admin/routes/:id             — update route fields
router.patch('/:id',       ctrl.update);

// PATCH /api/admin/routes/:id/toggle      — activate / deactivate
router.patch('/:id/toggle', ctrl.toggleStatus);

// DELETE /api/admin/routes/:id    — hard delete (only if no buses assigned)
router.delete('/:id',      ctrl.remove);

export default router;
