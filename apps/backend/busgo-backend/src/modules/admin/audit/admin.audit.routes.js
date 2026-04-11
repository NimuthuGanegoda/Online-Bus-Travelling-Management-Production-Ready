import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import { list } from './admin.audit.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET /api/admin/audit?action=&entity=&admin_email=&search=&page=&page_size=
router.get('/', list);

export default router;
