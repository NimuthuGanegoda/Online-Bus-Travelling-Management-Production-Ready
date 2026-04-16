import { Router } from 'express';
import { verifyDriver } from '../../middleware/driverAuth.middleware.js';
import * as ctrl from './driver.controller.js';

const router = Router();

// ── Public (no auth) ──────────────────────────────────────────
// POST /api/driver/auth/login
router.post('/auth/login',    ctrl.login);

// POST /api/driver/auth/register
router.post('/auth/register', ctrl.register);

// ── Protected (driver JWT required) ──────────────────────────
router.use(verifyDriver);

// GET  /api/driver/me
router.get('/me',             ctrl.getMe);

// GET  /api/driver/route
router.get('/route',          ctrl.getRoute);

// PATCH /api/driver/location
router.patch('/location',     ctrl.updateLocation);

// PATCH /api/driver/passengers
router.patch('/passengers',   ctrl.updatePassengers);

// POST /api/driver/emergency
router.post('/emergency',     ctrl.createAlert);

export default router;
