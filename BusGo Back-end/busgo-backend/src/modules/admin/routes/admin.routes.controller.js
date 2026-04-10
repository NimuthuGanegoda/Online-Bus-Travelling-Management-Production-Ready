import * as svc from './admin.routes.service.js';
import { sendSuccess } from '../../../utils/response.utils.js';

export async function list(req, res, next) {
  try {
    const includeInactive = req.query.all === 'true';
    const data = await svc.getAllRoutes({ includeInactive });
    sendSuccess(res, data, 'Routes list');
  } catch (err) { next(err); }
}

export async function getOne(req, res, next) {
  try {
    const data = await svc.getRouteById(req.params.id);
    sendSuccess(res, data, 'Route detail');
  } catch (err) { next(err); }
}

export async function create(req, res, next) {
  try {
    const { route_number, route_name, origin, destination, color } = req.body;
    const data = await svc.createRoute(
      { routeNumber: route_number, routeName: route_name, origin, destination, color },
      req.admin,
    );
    sendSuccess(res, data, 'Route created', 201);
  } catch (err) { next(err); }
}

export async function update(req, res, next) {
  try {
    const { route_number, route_name, origin, destination, color } = req.body;
    const data = await svc.updateRoute(
      req.params.id,
      { routeNumber: route_number, routeName: route_name, origin, destination, color },
      req.admin,
    );
    sendSuccess(res, data, 'Route updated');
  } catch (err) { next(err); }
}

export async function toggleStatus(req, res, next) {
  try {
    const data = await svc.toggleRouteStatus(req.params.id, req.admin);
    sendSuccess(res, data, `Route ${data.is_active ? 'activated' : 'deactivated'}`);
  } catch (err) { next(err); }
}

export async function remove(req, res, next) {
  try {
    await svc.deleteRoute(req.params.id, req.admin);
    sendSuccess(res, null, 'Route deleted');
  } catch (err) { next(err); }
}
