import { Router } from 'express';
import { authLimiter } from '../../../middleware/rateLimiter.middleware.js';
import { validate } from '../../../middleware/validate.middleware.js';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import { adminLoginSchema, adminRefreshSchema } from './admin.auth.schema.js';
import * as ctrl from './admin.auth.controller.js';

const router = Router();

// POST /api/admin/auth/login
router.post('/login',   authLimiter, validate(adminLoginSchema),   ctrl.login);

// POST /api/admin/auth/refresh
router.post('/refresh', validate(adminRefreshSchema), ctrl.refresh);

// Protected
router.use(verifyAdmin);

// POST /api/admin/auth/logout
router.post('/logout', ctrl.logout);

// GET  /api/admin/auth/me
router.get('/me', ctrl.me);

export default router;
