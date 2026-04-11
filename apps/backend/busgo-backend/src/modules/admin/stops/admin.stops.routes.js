import { Router } from 'express';
import { verifyAdmin } from '../../../middleware/adminAuth.middleware.js';
import * as ctrl from './admin.stops.controller.js';

const router = Router();
router.use(verifyAdmin);

// GET  /api/admin/stops?route_id=<uuid>   — stops assigned to a route (ordered)
router.get('/',                       ctrl.listForRoute);

// GET  /api/admin/stops/all              — every stop (for picker dropdown)
router.get('/all',                    ctrl.listAll);

// POST /api/admin/stops                  — create new stop + assign to route
router.post('/',                      ctrl.create);

// POST /api/admin/stops/link             — link existing stop to route
router.post('/link',                  ctrl.link);

// PATCH /api/admin/stops/:junctionId/order  — change stop_order
router.patch('/:junctionId/order',    ctrl.reorder);

// DELETE /api/admin/stops/:junctionId    — remove stop from route
router.delete('/:junctionId',         ctrl.remove);

export default router;
