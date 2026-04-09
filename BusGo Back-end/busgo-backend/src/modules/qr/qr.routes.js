import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import * as controller from './qr.controller.js';

const router = Router();
router.use(authenticate);

router.get('/my-card',   controller.getMyQrCard);
router.post('/scan-exit', controller.scanExit);

export default router;
