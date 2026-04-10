import { Router } from 'express';
import { verifyAdmin, requireRole } from '../../../middleware/adminAuth.middleware.js';
import { validate } from '../../../middleware/validate.middleware.js';
import { createAdminSchema, updateAdminSchema } from './admin.admins.schema.js';
import * as ctrl from './admin.admins.controller.js';

const router = Router();
router.use(verifyAdmin);

// All admin-management actions require super_admin
const superOnly = requireRole('super_admin');

// GET  /api/admin/admins
router.get('/',                     ctrl.list);
router.get('/:id',                  ctrl.getOne);
router.post('/',     superOnly, validate(createAdminSchema), ctrl.create);
router.patch('/:id', superOnly, validate(updateAdminSchema), ctrl.update);
router.patch('/:id/toggle-status',  superOnly, ctrl.toggleStatus);
router.delete('/:id',               superOnly, ctrl.remove);

export default router;
