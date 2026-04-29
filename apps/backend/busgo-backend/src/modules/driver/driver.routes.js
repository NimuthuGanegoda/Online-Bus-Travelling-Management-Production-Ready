import { Router } from 'express';
import { verifyDriver } from '../../middleware/driverAuth.middleware.js';
import * as ctrl from './driver.controller.js';

const router = Router();

// ── Public (no auth) ──────────────────────────────────────────
// POST /api/driver/auth/login
router.post('/auth/login',    ctrl.login);

// POST /api/driver/auth/register
router.post('/auth/register', ctrl.register);

// ── Password recovery (FR-28 / FR-29) — public, no auth ───────
router.post('/auth/forgot-password/request', ctrl.forgotPasswordRequest);
router.post('/auth/forgot-password/verify',  ctrl.forgotPasswordVerify);
router.post('/auth/forgot-password/reset',   ctrl.forgotPasswordReset);

// ── Protected (driver JWT required) ──────────────────────────
router.use(verifyDriver);

// GET  /api/driver/me
router.get('/me',             ctrl.getMe);

// GET  /api/driver/route
router.get('/route',          ctrl.getRoute);

// GET  /api/driver/ratings  — recent passenger ratings (FR-36)
router.get('/ratings',        ctrl.getMyRatings);

// PATCH /api/driver/location
router.patch('/location',     ctrl.updateLocation);

// PATCH /api/driver/passengers
router.patch('/passengers',   ctrl.updatePassengers);

// POST /api/driver/emergency
router.post('/emergency',     ctrl.createAlert);

export default router;
