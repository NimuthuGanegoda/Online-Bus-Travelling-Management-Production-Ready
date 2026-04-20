import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as controller from './admin.payments.controller.js';

const router = Router();
router.use(verifyAdmin);

router.get('/', controller.listAllPayments);

export default router;
