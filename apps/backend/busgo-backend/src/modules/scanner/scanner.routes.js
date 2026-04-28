import { Router } from 'express';
import { verifyDriver } from '../../middleware/driverAuth.middleware.js';
import { validate } from '../../middleware/validate.middleware.js';
import { scanSchema } from './scanner.schema.js';
import * as ctrl from './scanner.controller.js';

const router = Router();

/**
 * Scanner endpoints — all require a valid driver JWT.
 *
 * Login (FR-37 to FR-41) is handled by the existing driver auth flow:
 *   POST /api/driver/auth/login
 *   POST /api/driver/auth/register
 * The scanner app should hit those for sign-in, then call /api/scanner/scan
 * with the driver access token attached.
 */
router.use(verifyDriver);

// POST /api/scanner/scan  — record a passenger boarding/alighting (FR-43)
router.post('/scan', validate(scanSchema), ctrl.scan);

export default router;
