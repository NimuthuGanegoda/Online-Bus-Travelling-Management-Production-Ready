import * as svc from './admin.stops.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

// GET /api/admin/stops?route_id=<uuid>  — stops for a route (ordered)
export async function listForRoute(req, res, next) {
  try {
    const data = await svc.getRouteStops(req.query.route_id);
    sendSuccess(res, data, 'Route stops');
  } catch (err) { next(err); }
}

// GET /api/admin/stops/all  — all stops (for picker)
export async function listAll(req, res, next) {
  try {
    const data = await svc.getAllStops();
    sendSuccess(res, data, 'All stops');
  } catch (err) { next(err); }
}

// POST /api/admin/stops  — create new stop + assign to route
export async function create(req, res, next) {
  try {
    const { route_id, stop_name, latitude, longitude, stop_order } = req.body;
    const data = await svc.addStopToRoute(
      route_id,
      { stopName: stop_name, latitude: Number(latitude), longitude: Number(longitude), stopOrder: stop_order },
      req.admin,
    );
    sendSuccess(res, data, 'Stop added', 201);
  } catch (err) { next(err); }
}

// POST /api/admin/stops/link  — link existing stop to route
export async function link(req, res, next) {
  try {
    const { route_id, stop_id, stop_order } = req.body;
    const data = await svc.linkExistingStop(route_id, { stopId: stop_id, stopOrder: stop_order }, req.admin);
    sendSuccess(res, data, 'Stop linked', 201);
  } catch (err) { next(err); }
}

// PATCH /api/admin/stops/:junctionId/order  — reorder
export async function reorder(req, res, next) {
  try {
    const data = await svc.updateStopOrder(req.params.junctionId, req.body.stop_order, req.admin);
    sendSuccess(res, data, 'Stop order updated');
  } catch (err) { next(err); }
}

// DELETE /api/admin/stops/:junctionId  — remove stop from route
export async function remove(req, res, next) {
  try {
    await svc.removeStopFromRoute(req.params.junctionId, req.admin);
    sendSuccess(res, null, 'Stop removed from route');
  } catch (err) { next(err); }
}
