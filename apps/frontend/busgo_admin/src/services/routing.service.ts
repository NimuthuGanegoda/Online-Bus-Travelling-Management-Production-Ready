const OSRM_BASE = 'https://router.project-osrm.org/route/v1/driving';

/**
 * Fetch a road-snapped polyline from OSRM for the given waypoints.
 * Returns [lat, lng] pairs that follow real roads.
 * Falls back to straight-line waypoints if the request fails.
 */
export async function fetchRoadPolyline(
  waypoints: { latitude: number; longitude: number }[],
): Promise<[number, number][]> {
  if (waypoints.length < 2) {
    return waypoints.map((w) => [w.latitude, w.longitude]);
  }

  const coords = waypoints.map((w) => `${w.longitude},${w.latitude}`).join(';');
  const url = `${OSRM_BASE}/${coords}?overview=full&geometries=geojson&steps=false`;

  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
    if (!res.ok) throw new Error(`OSRM ${res.status}`);

    const json = await res.json();
    if (json.code !== 'Ok' || !json.routes?.length) throw new Error('No route');

    // GeoJSON coordinates are [lng, lat] — swap to [lat, lng] for Leaflet
    const coords2d: [number, number][] = json.routes[0].geometry.coordinates.map(
      ([lng, lat]: [number, number]) => [lat, lng],
    );

    return coords2d.length >= 2 ? coords2d : waypoints.map((w) => [w.latitude, w.longitude]);
  } catch {
    // Network error, timeout, or parse failure — fall back to straight lines
    return waypoints.map((w) => [w.latitude, w.longitude]);
  }
}
