import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';

import { env } from './config/env.js';
import { logger } from './utils/logger.js';
import { generalLimiter } from './middleware/rateLimiter.middleware.js';
import { errorHandler, notFoundHandler } from './middleware/error.middleware.js';

// Module routers
import authRoutes          from './modules/auth/auth.routes.js';
import usersRoutes         from './modules/users/users.routes.js';
import qrRoutes            from './modules/qr/qr.routes.js';
import busesRoutes         from './modules/buses/buses.routes.js';
import routesRoutes        from './modules/routes/routes.routes.js';
import stopsRoutes         from './modules/stops/stops.routes.js';
import tripsRoutes         from './modules/trips/trips.routes.js';
import ratingsRoutes       from './modules/ratings/ratings.routes.js';
import emergencyRoutes     from './modules/emergency/emergency.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import searchesRoutes      from './modules/searches/searches.routes.js';
import paymentsRoutes      from './modules/payments/payments.routes.js';

// Driver router
import driverRoutes from './modules/driver/driver.routes.js';

// Scanner router (BUSGO Scanner app — driver-authenticated QR scans)
import scannerRoutes from './modules/scanner/scanner.routes.js';

// Admin routers
import adminAuthRoutes          from './modules/admin/auth/admin.auth.routes.js';
import adminDashboardRoutes     from './modules/admin/dashboard/admin.dashboard.routes.js';
import adminBusesRoutes         from './modules/admin/buses/admin.buses.routes.js';
import adminDriversRoutes       from './modules/admin/drivers/admin.drivers.routes.js';
import adminPassengersRoutes    from './modules/admin/passengers/admin.passengers.routes.js';
import adminAdminsRoutes        from './modules/admin/admins/admin.admins.routes.js';
import adminEmergencyRoutes     from './modules/admin/emergency/admin.emergency.routes.js';
import adminAuditRoutes         from './modules/admin/audit/admin.audit.routes.js';
import adminNotificationsRoutes from './modules/admin/notifications/admin.notifications.routes.js';
import adminRoutesRoutes        from './modules/admin/routes/admin.routes.routes.js';
import adminStopsRoutes         from './modules/admin/stops/admin.stops.routes.js';
import adminPaymentsRoutes      from './modules/admin/payments/admin.payments.routes.js';

const app = express();

// ── Security headers ──────────────────────────────────────────────────────────
app.use(helmet());

// ── CORS ──────────────────────────────────────────────────────────────────────
const allowedOrigins = env.CORS_ORIGINS.split(',').map((o) => o.trim());
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow requests with no origin (mobile apps, Postman, etc.)
      if (!origin || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      // In development, allow any localhost/127.0.0.1 origin (Flutter web uses random ports)
      if (env.NODE_ENV === 'development') {
        const isLocal = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
        if (isLocal) return callback(null, true);
      }
      callback(new Error(`CORS: origin '${origin}' not allowed`));
    },
    methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  })
);

// ── Request parsing ────────────────────────────────────────────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// ── HTTP request logging ───────────────────────────────────────────────────────
app.use(
  morgan('combined', {
    stream: { write: (msg) => logger.http(msg.trim()) },
    skip: (req) => req.url === '/health',
  })
);

// ── General rate limiter (applied to all API routes) ─────────────────────────
app.use('/api', generalLimiter);

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), env: env.NODE_ENV });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api/auth',           authRoutes);
app.use('/api/users',          usersRoutes);
app.use('/api/qr',             qrRoutes);
app.use('/api/buses',          busesRoutes);
app.use('/api/routes',         routesRoutes);
app.use('/api/stops',          stopsRoutes);
app.use('/api/trips',          tripsRoutes);
app.use('/api/ratings',        ratingsRoutes);
app.use('/api/emergency',      emergencyRoutes);
app.use('/api/notifications',  notificationsRoutes);
app.use('/api/searches/recent', searchesRoutes);
app.use('/api/payments',        paymentsRoutes);
app.use('/api/driver',          driverRoutes);
app.use('/api/scanner',         scannerRoutes);

// ── Admin API Routes (/api/admin/*) ───────────────────────────
app.use('/api/admin/auth',          adminAuthRoutes);
app.use('/api/admin/dashboard',     adminDashboardRoutes);
app.use('/api/admin/buses',         adminBusesRoutes);
app.use('/api/admin/drivers',       adminDriversRoutes);
app.use('/api/admin/passengers',    adminPassengersRoutes);
app.use('/api/admin/admins',        adminAdminsRoutes);
app.use('/api/admin/emergency',     adminEmergencyRoutes);
app.use('/api/admin/audit',         adminAuditRoutes);
app.use('/api/admin/notifications', adminNotificationsRoutes);
app.use('/api/admin/routes',        adminRoutesRoutes);
app.use('/api/admin/stops',         adminStopsRoutes);
app.use('/api/admin/payments',      adminPaymentsRoutes);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use(notFoundHandler);

// ── Global error handler (must be last) ───────────────────────────────────────
app.use(errorHandler);

export default app;
