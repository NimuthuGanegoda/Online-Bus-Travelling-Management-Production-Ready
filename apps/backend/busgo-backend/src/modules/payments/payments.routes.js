import { Router } from 'express';
import { authenticate } from '../../middleware/auth.middleware.js';
import { validate } from '../../middleware/validate.middleware.js';
import { createPaymentSchema } from './payments.schema.js';
import * as controller from './payments.controller.js';

const router = Router();
router.use(authenticate);

router.get('/',  controller.listMyPayments);
router.post('/', validate(createPaymentSchema), controller.createPayment);

export default router;
