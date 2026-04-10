import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.dashboard.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET /api/admin/dashboard/stats
router.get('/stats',    ctrl.stats);

// GET /api/admin/dashboard/live-map
router.get('/live-map', ctrl.liveMap);

export default router;
