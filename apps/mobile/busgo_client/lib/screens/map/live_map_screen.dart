import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart' hide RouteData;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_data.dart';
import '../../models/bus_model.dart';
import '../../models/stop_model.dart';
import '../../providers/bus_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/routing_service.dart';
import '../../widgets/crowd_indicator.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();

  // User location (Colombo Fort area). Replace with real geolocation later.
  static const _userLocation = LatLng(6.9271, 79.8612);

  late AnimationController _pulseController;

  // OSRM-snapped road polylines per route number ('138' → list of LatLng)
  Map<String, List<LatLng>> _routePolylines = {};
  bool _routesLoaded = false;

  // FR-20/21: arrival watch state for the bus the passenger has boarded.
  Timer? _arrivalSimTimer;
  String? _watchedBusId;

  // The user's current map position. Starts hardcoded near Colombo Fort
  // (no real geolocation yet — install `geolocator` for production).
  // During an active trip the user "boards" the bus and this position
  // tracks the bus marker for a clear visual journey.
  LatLng _userPosition = const LatLng(6.9271, 79.8612);

  // Trip lifecycle for the watched bus, drives the visual journey:
  //   idle           → no active trip; buses bounce along their routes
  //   awaitingPickup → watched bus is heading toward the user's stop
  //   onTrip         → user has boarded, bus heads to destination
  //   arrived        → reached destination; reset shortly after
  _TripPhase _tripPhase = _TripPhase.idle;

  // Cached provider reference so dispose() can safely unsubscribe even
  // after the widget has been removed from the tree.
  BusProvider? _busProvider;

  // Visual movement: per-bus simulated progress along its route polyline.
  // Used only for the demo since no driver is currently broadcasting GPS.
  // Real GPS updates from Supabase Realtime override these.
  Timer? _movementTimer;
  final Map<String, double> _simProgress = {}; // bus.busId → 0.0–1.0
  final Map<String, bool> _simForward = {};

  // Lookup table mapping a bus route_number to OSRM waypoints (Colombo geography)
  static const _waypointsByRouteNumber = <String, List<LatLng>>{
    '138': RouteData.route138Waypoints,
    '163': RouteData.route163Waypoints,
    '171': RouteData.route171Waypoints,
  };

  // Per-route color (used as a fallback when the backend doesn't return one)
  static const _fallbackRouteColors = <String, Color>{
    '138': AppColors.secondary,
    '163': AppColors.warning,
    '171': Color(0xFF7B1FA2),
  };

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _busProvider = context.read<BusProvider>();
      // Fetch real buses, stops and routes from the backend.
      await _busProvider!.loadAll(
        _userLocation.latitude,
        _userLocation.longitude,
      );
      // Subscribe to live GPS broadcasts so markers update on push.
      _busProvider!.subscribeToLiveLocations();
      if (mounted) _fetchRoutePolylines();
    });
  }

  Future<void> _fetchRoutePolylines() async {
    final waypointSets = _waypointsByRouteNumber.values
        .map((wp) => wp.toList())
        .toList();
    final polylines = await RoutingService.fetchRoutes(waypointSets);
    if (!mounted) return;
    setState(() {
      _routePolylines = {
        for (var i = 0; i < _waypointsByRouteNumber.length; i++)
          _waypointsByRouteNumber.keys.elementAt(i): polylines[i],
      };
      _routesLoaded = true;
    });
    _startMovementSimulation();
  }

  // Tracks the watched bus's explicit position during awaitingPickup/onTrip,
  // so it can break out of its bouncy polyline animation and drive toward
  // the user, then toward the route destination.
  LatLng? _watchedBusPos;

  // Animate buses along their route polylines for visual "live" feel.
  // Real GPS broadcasts (via Supabase Realtime) take priority and will
  // overwrite these positions in BusProvider when they arrive.
  //
  // Special handling: while a trip is active, the watched bus is steered
  // toward the user (awaitingPickup) and then toward the destination
  // (onTrip), driving the FR-20 and FR-21 popups via real proximity checks.
  void _startMovementSimulation() {
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _busProvider == null) return;
      final buses = _busProvider!.nearbyBuses;
      if (buses.isEmpty) return;
      setState(() {
        for (final bus in buses) {
          final id = bus.busId ?? bus.stopId;
          final polyline = _routePolylines[bus.routeNumber];
          if (polyline == null || polyline.length < 2) continue;

          // Watched bus during an active trip — steer to a target.
          if (id == _watchedBusId &&
              _tripPhase != _TripPhase.idle &&
              _tripPhase != _TripPhase.arrived) {
            _stepWatchedBus(bus, polyline);
            continue;
          }

          // Default bouncy progress along the polyline.
          if (!_simProgress.containsKey(id)) {
            _simProgress[id] = _initialProgressFor(bus, polyline);
            _simForward[id] = true;
          }
          var p = _simProgress[id]!;
          var fwd = _simForward[id] ?? true;
          const step = 0.015;
          p = fwd ? p + step : p - step;
          if (p >= 1.0) {
            p = 1.0;
            fwd = false;
          } else if (p <= 0.0) {
            p = 0.0;
            fwd = true;
          }
          _simProgress[id] = p;
          _simForward[id] = fwd;
        }
      });
    });
  }

  // One simulation tick for the watched bus: it stays on its real route
  // polyline (always forward) while the passenger waits at a stop ahead.
  // FR-20 fires when the bus reaches the passenger's stop; FR-21 fires
  // when the bus reaches its route destination.
  void _stepWatchedBus(BusModel bus, List<LatLng> polyline) {
    final id = bus.busId ?? bus.stopId;

    // Always advance the bus forward along its route during a trip.
    var p = _simProgress[id] ?? _initialProgressFor(bus, polyline);
    p = (p + 0.020).clamp(0.0, 1.0);
    _simProgress[id] = p;
    _simForward[id] = true;
    _watchedBusPos = _interpolateAlong(polyline, p);

    final messenger = ScaffoldMessenger.of(context);

    if (_tripPhase == _TripPhase.awaitingPickup) {
      // Passenger is waiting at a stop on the route — fire FR-20 when
      // the bus reaches them.
      if (_haversineMeters(_watchedBusPos!, _userPosition) < 250) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.directions_bus,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bus ${bus.routeNumber} has arrived at your stop. '
                    'Boarding now...',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
        _userPosition = _watchedBusPos!;
        _tripPhase = _TripPhase.onTrip;
      } else if (p >= 1.0) {
        // Reached the end of the route without picking up — loop back so
        // the demo always reaches the pickup eventually.
        _simProgress[id] = 0.0;
      }
    } else if (_tripPhase == _TripPhase.onTrip) {
      // User travels with the bus along the route.
      _userPosition = _watchedBusPos!;
      if (p >= 0.99) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
            content: Row(
              children: [
                const Icon(Icons.flag, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have arrived at ${bus.to}. Please rate your trip!',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        );
        _tripPhase = _TripPhase.arrived;

        // Mark the trip as completed in the backend and navigate to rating.
        final fare = _estimateFare(polyline);
        _completeTripAndRate(fare, bus);

        _arrivalSimTimer?.cancel();
        _arrivalSimTimer = Timer(const Duration(seconds: 5), () {
          if (!mounted) return;
          setState(() {
            _watchedBusId = null;
            _watchedBusPos = null;
            _tripPhase = _TripPhase.idle;
          });
        });
      }
    }
  }

  // Auto-arrival flow: bus reached destination on the map. We do NOT alight
  // the trip here — instead we navigate the user to the QR card so they can
  // tap "Scan to Exit Bus" themselves (matches the real-world scanner flow).
  // The QR screen will end the trip and continue to the rating page.
  void _completeTripAndRate(double fare, BusModel bus) {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    developer.log(
      '[TripEnd] auto-arrival → navigating to QR exit screen, fare=$fare',
      name: 'busgo.trip',
    );

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.secondary,
        duration: const Duration(seconds: 4),
        content: Text(
          'Bus arrived at ${bus.to}. Scan your QR to exit and rate the driver.',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) router.push('/qr');
    });
  }

  // Rough fare estimate: Rs 50 base + Rs 5 per km of total route length.
  // Replace with a real fare-rules table (zones, time-of-day, etc.) for prod.
  double _estimateFare(List<LatLng> polyline) {
    if (polyline.length < 2) return 50;
    var totalM = 0.0;
    for (var i = 1; i < polyline.length; i++) {
      totalM += _haversineMeters(polyline[i - 1], polyline[i]);
    }
    final km = totalM / 1000;
    return (50 + km * 5).clamp(50, 500).roundToDouble();
  }

  double _haversineMeters(LatLng a, LatLng b) {
    const earthM = 6371000.0;
    double rad(double deg) => deg * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earthM * math.asin(math.sqrt(h));
  }

  // Linearly interpolate a point along a polyline given a 0–1 progress value.
  LatLng _interpolateAlong(List<LatLng> polyline, double progress) {
    if (polyline.isEmpty) return const LatLng(0, 0);
    if (polyline.length == 1) return polyline.first;
    final p = progress.clamp(0.0, 1.0);
    final segments = polyline.length - 1;
    final exact = p * segments;
    final i = exact.floor().clamp(0, segments - 1);
    final t = exact - i;
    final a = polyline[i];
    final b = polyline[i + 1];
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  double _initialProgressFor(BusModel bus, List<LatLng> polyline) {
    if (bus.currentLat == null || bus.currentLng == null) return 0.0;
    final point = LatLng(bus.currentLat!, bus.currentLng!);
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < polyline.length; i++) {
      final dLat = polyline[i].latitude - point.latitude;
      final dLng = polyline[i].longitude - point.longitude;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return polyline.length <= 1 ? 0.0 : bestIdx / (polyline.length - 1);
  }

  @override
  void dispose() {
    _arrivalSimTimer?.cancel();
    _movementTimer?.cancel();
    _busProvider?.unsubscribeFromLiveLocations();
    _pulseController.dispose();
    super.dispose();
  }

  Color _tripPhaseColor() {
    switch (_tripPhase) {
      case _TripPhase.awaitingPickup:
        return AppColors.warning;
      case _TripPhase.onTrip:
        return AppColors.secondary;
      case _TripPhase.arrived:
        return AppColors.success;
      case _TripPhase.idle:
        return AppColors.success;
    }
  }

  String _tripPhaseLabel(int busCount) {
    switch (_tripPhase) {
      case _TripPhase.awaitingPickup:
        return 'BUS COMING TO YOU';
      case _TripPhase.onTrip:
        return 'ON TRIP';
      case _TripPhase.arrived:
        return 'ARRIVED';
      case _TripPhase.idle:
        return 'LIVE · $busCount BUSES';
    }
  }

  Color _routeColorFor(BusModel bus) {
    if (_fallbackRouteColors.containsKey(bus.routeNumber)) {
      return _fallbackRouteColors[bus.routeNumber]!;
    }
    return bus.routeColor;
  }

  LatLng? _busPosition(BusModel bus) {
    final id = bus.busId ?? bus.stopId;
    final polyline = _routePolylines[bus.routeNumber];

    // Watched bus during a trip: use the explicit steered position.
    if (id == _watchedBusId &&
        _tripPhase != _TripPhase.idle &&
        _watchedBusPos != null) {
      return _watchedBusPos;
    }
    // Otherwise prefer the simulated walk-along position once initialized.
    if (polyline != null && polyline.length >= 2 && _simProgress.containsKey(id)) {
      return _interpolateAlong(polyline, _simProgress[id]!);
    }
    if (bus.currentLat != null && bus.currentLng != null) {
      return LatLng(bus.currentLat!, bus.currentLng!);
    }
    if (polyline != null && polyline.isNotEmpty) return polyline.first;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BusProvider>(
        builder: (context, busProvider, _) {
          final selectedBus = busProvider.selectedBus;
          final buses = busProvider.nearbyBuses;
          final stops = busProvider.nearbyStops;

          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: _userLocation,
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.busgo.client',
                        ),

                        // ── Route polylines (real road shape via OSRM) ──
                        if (_routesLoaded)
                          PolylineLayer(
                            polylines: _routePolylines.entries.map((entry) {
                              final color =
                                  _fallbackRouteColors[entry.key] ??
                                      AppColors.secondary;
                              return Polyline(
                                points: entry.value,
                                color: color.withValues(alpha: 0.6),
                                strokeWidth: 4.5,
                                borderColor: color.withValues(alpha: 0.2),
                                borderStrokeWidth: 2,
                              );
                            }).toList(),
                          ),

                        // ── Start (A) and end (B) markers per route ──
                        if (_routesLoaded)
                          MarkerLayer(
                            markers: _waypointsByRouteNumber.entries
                                .expand((entry) {
                              final wp = entry.value;
                              if (wp.isEmpty) return <Marker>[];
                              return [
                                Marker(
                                  point: wp.first,
                                  width: 36,
                                  height: 36,
                                  child: const _TerminalMarker(
                                    label: 'A',
                                    color: Color(0xFF2E7D32),
                                    icon: Icons.trip_origin,
                                  ),
                                ),
                                Marker(
                                  point: wp.last,
                                  width: 36,
                                  height: 36,
                                  child: const _TerminalMarker(
                                    label: 'B',
                                    color: Color(0xFFC62828),
                                    icon: Icons.flag,
                                  ),
                                ),
                              ];
                            }).toList(),
                          ),

                        // ── Bus stop markers (from backend) ──
                        if (stops.isNotEmpty)
                          MarkerLayer(
                            markers: stops
                                .where((s) =>
                                    s.latitude != null && s.longitude != null)
                                .map((s) => Marker(
                                      point: LatLng(s.latitude!, s.longitude!),
                                      width: 22,
                                      height: 22,
                                      child: _StopMarker(stop: s),
                                    ))
                                .toList(),
                          ),

                        // ── User pulse marker ──
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _userPosition,
                              width: 30,
                              height: 30,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (_, __) {
                                  final scale =
                                      1.0 + _pulseController.value * 0.4;
                                  return Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.secondary
                                                .withValues(
                                                    alpha: 0.2 *
                                                        (1 -
                                                            _pulseController
                                                                .value)),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 14,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.secondary
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        // ── Real bus markers (from backend) ──
                        if (buses.isNotEmpty)
                          MarkerLayer(
                            markers: buses
                                .map((bus) {
                                  final pos = _busPosition(bus);
                                  if (pos == null) return null;
                                  final isSelected =
                                      selectedBus?.busId == bus.busId;
                                  final color = _routeColorFor(bus);
                                  return Marker(
                                    point: pos,
                                    width: isSelected ? 48 : 40,
                                    height: isSelected ? 48 : 40,
                                    child: GestureDetector(
                                      onTap: () => busProvider.selectBus(bus),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white
                                                    .withValues(alpha: 0.8),
                                            width: isSelected ? 3 : 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color
                                                  .withValues(alpha: 0.5),
                                              blurRadius:
                                                  isSelected ? 14 : 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.directions_bus,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            Text(
                                              bus.routeNumber,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                })
                                .whereType<Marker>()
                                .toList(),
                          ),
                      ],
                    ),

                    // ── Loading overlay ──
                    if (busProvider.isLoading || !_routesLoaded)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.6),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.secondary,
                                  strokeWidth: 3,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Loading live buses...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ── Search bar ──
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search,
                                    size: 18, color: Color(0xFF999999)),
                                SizedBox(width: 8),
                                Text(
                                  'Search stops or routes...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Zoom controls ──
                    Positioned(
                      right: 12,
                      bottom: 70,
                      child: Column(
                        children: [
                          _zoomButton(Icons.add_rounded, () {
                            final z = _mapController.camera.zoom;
                            _mapController.move(
                                _mapController.camera.center,
                                (z + 1).clamp(3, 18));
                          }),
                          Container(
                            width: 40,
                            height: 1,
                            color: const Color(0xFF1A6FA8)
                                .withValues(alpha: 0.3),
                          ),
                          _zoomButton(Icons.remove_rounded, () {
                            final z = _mapController.camera.zoom;
                            _mapController.move(
                                _mapController.camera.center,
                                (z - 1).clamp(3, 18));
                          }),
                        ],
                      ),
                    ),

                    // ── My location FAB ──
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () =>
                            _mapController.move(_userPosition, 13.0),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.my_location,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),

                    // ── Live + trip-phase indicator ──
                    Positioned(
                      bottom: 60,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _tripPhaseColor(),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle,
                                size: 6, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              _tripPhaseLabel(buses.length),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Bottom sheet (real selected bus from backend) ──
              if (selectedBus != null) _buildBottomSheet(selectedBus),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // FR-22: Pre-boarding approve/disapprove confirmation prompt.
  // Shown when the passenger taps "Board" on a bus from the live map.
  // ─────────────────────────────────────────────────────────────────
  Future<void> _showBoardingDialog(BusModel bus) async {
    final approved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding:
            const EdgeInsets.fromLTRB(20, 20, 20, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bus.routeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bus.routeNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.directions_bus,
                    size: 20, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Confirm boarding',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you boarding bus ${bus.busNumber ?? bus.routeNumber} '
              '(${bus.displayRoute})?',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Disapprove',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Approve',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (approved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          content: Text(
            'Boarding confirmed for bus ${bus.busNumber ?? bus.routeNumber}. '
            'Have a safe trip!',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
      _startArrivalWatch(bus);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FR-20 / FR-21: arrival notifications driven by the trip lifecycle.
  // In production these fire from real GPS broadcasts via Supabase
  // Realtime when the bus comes within 250m of the boarding/destination
  // stop. For demo without a driver app pushing GPS, the movement
  // simulation steers the watched bus through the same proximity logic.
  // ─────────────────────────────────────────────────────────────────
  void _startArrivalWatch(BusModel bus) {
    _arrivalSimTimer?.cancel();
    final id = bus.busId ?? bus.stopId;
    final polyline = _routePolylines[bus.routeNumber];

    // Place the passenger at a stop further ahead on the bus's route
    // so the bus actually drives along its real route to reach them.
    LatLng pickupStop = _userPosition;
    if (polyline != null && polyline.length >= 2) {
      final busProgress =
          _simProgress[id] ?? _initialProgressFor(bus, polyline);
      final stopProgress = (busProgress + 0.30).clamp(0.05, 0.90);
      pickupStop = _interpolateAlong(polyline, stopProgress);
    }

    setState(() {
      _watchedBusId = id;
      _watchedBusPos = bus.currentLat != null && bus.currentLng != null
          ? LatLng(bus.currentLat!, bus.currentLng!)
          : (polyline?.first);
      _userPosition = pickupStop; // user "walks" to the stop on the route
      _tripPhase = _TripPhase.awaitingPickup;
      _simForward[id] = true; // ensure bus moves forward along the route
    });
    // Pan the map so the user can see the bus + their stop together.
    if (polyline != null && _watchedBusPos != null) {
      _mapController.move(_watchedBusPos!, 14.0);
    }

    // Persist the trip in the backend. Creates an `ongoing` row in the
    // `trips` table; the bus_id and route_id come from the real backend
    // BusModel so this row joins back to a real bus + route.
    _persistTripStart(bus);
  }

  Future<void> _persistTripStart(BusModel bus) async {
    developer.log(
      '[TripStart] called for bus=${bus.busNumber} '
      'busId=${bus.busId} routeId=${bus.routeId}',
      name: 'busgo.trip',
    );

    if (bus.busId == null || bus.routeId == null) {
      developer.log(
        '[TripStart] SKIPPED — bus.busId or bus.routeId is null. '
        'This bus is missing UUIDs from the backend.',
        name: 'busgo.trip',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 5),
          content: Text(
            'Cannot save trip: this bus has no UUID. '
            '(busId=${bus.busId}, routeId=${bus.routeId})',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    final tripProvider = context.read<TripProvider>();
    final messenger = ScaffoldMessenger.of(context);

    developer.log('[TripStart] calling tripProvider.startTrip…',
        name: 'busgo.trip');
    final trip = await tripProvider.startTrip(
      busId: bus.busId!,
      routeId: bus.routeId!,
    );

    if (!mounted) return;

    if (trip == null) {
      final reason = tripProvider.errorMessage ?? 'Unknown error';
      developer.log('[TripStart] FAILED — $reason', name: 'busgo.trip');
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 6),
          content: Text(
            'Could not save trip: $reason',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else {
      developer.log(
        '[TripStart] SUCCESS — trip.id=${trip.id} status=${trip.tripStatus}',
        name: 'busgo.trip',
      );
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          content: Text(
            'Trip saved (id ${trip.id?.substring(0, 8) ?? '?'}…)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1A3A5C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF1A6FA8).withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF5BB8F5), size: 22),
      ),
    );
  }

  Widget _buildBottomSheet(BusModel bus) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: bus.routeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bus.routeNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bus.displayRoute,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bus ${bus.busNumber ?? bus.stopId} · Driver: ${bus.driverName}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${bus.etaMinutes}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const Text(
                    'MIN',
                    style: TextStyle(
                        fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          CrowdIndicator(
            level: bus.crowdLevel,
            customLabel:
                'Passenger Load: ${bus.crowdLevel.name} (${bus.passengerLoad})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('Driver: ',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    ...List.generate(
                        4,
                        (_) => const Text('★',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.starFilled))),
                    const Text('★',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.starEmpty)),
                    const SizedBox(width: 4),
                    Text('${bus.driverRating}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      final pos = _busPosition(bus);
                      if (pos != null) _mapController.move(pos, 15.5);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Track',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showBoardingDialog(bus),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Board',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// TERMINAL MARKER — shown only at route start (A) and end (B)
// ═══════════════════════════════════════════════════════════
class _TerminalMarker extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TerminalMarker({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STOP MARKER — small circle for each backend bus stop
// ═══════════════════════════════════════════════════════════
class _StopMarker extends StatelessWidget {
  final StopModel stop;
  const _StopMarker({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: stop.name,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.directions_bus,
            size: 11,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════
// TRIP PHASE — drives the visual journey after passenger boards
// ═══════════════════════════════════════════════════════════
enum _TripPhase { idle, awaitingPickup, onTrip, arrived }

