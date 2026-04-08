import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_data.dart';
import '../../providers/bus_provider.dart';
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

  // User location (Colombo Fort area)
  static const _userLocation = LatLng(6.9271, 79.8612);

  // Live tracking state
  List<_LiveBus> _liveBuses = [];
  Timer? _trackingTimer;
  late AnimationController _pulseController;
  int? _selectedBusIndex;
  bool _routesLoaded = false;

  // Route definitions: id, label, waypoints, color, speed
  static const _routeDefinitions = [
    _RouteDefinition(
      id: '138',
      label: 'Nugegoda → Colombo',
      waypoints: RouteData.route138Waypoints,
      color: AppColors.secondary,
      speed: 0.15,
    ),
    _RouteDefinition(
      id: '163',
      label: 'Rajagiriya → Maharagama',
      waypoints: RouteData.route163Waypoints,
      color: AppColors.warning,
      speed: 0.10,
    ),
    _RouteDefinition(
      id: '171',
      label: 'Colombo 4 → Athurugiriya',
      waypoints: RouteData.route171Waypoints,
      color: Color(0xFF7B1FA2),
      speed: 0.12,
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for user dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusProvider>();
      if (provider.nearbyBuses.isEmpty) provider.loadAll();
    });

    _fetchRealRoutes();
  }

  Future<void> _fetchRealRoutes() async {
    // Fetch all routes in parallel from OSRM
    final waypointSets =
        _routeDefinitions.map((d) => d.waypoints.toList()).toList();

    final roadPolylines = await RoutingService.fetchRoutes(waypointSets);

    if (!mounted) return;

    setState(() {
      _liveBuses = List.generate(_routeDefinitions.length, (i) {
        final def = _routeDefinitions[i];
        return _LiveBus(
          id: def.id,
          label: def.label,
          route: roadPolylines[i],
          color: def.color,
          speed: def.speed,
        );
      });
      _routesLoaded = true;
    });

    // Start simulated GPS updates every 2 seconds
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _updateBusPositions(),
    );
  }

  void _updateBusPositions() {
    setState(() {
      for (final bus in _liveBuses) {
        bus.advance();
      }
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BusProvider>(
        builder: (context, busProvider, _) {
          final selectedBus = busProvider.selectedBus;
          return Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // ── OpenStreetMap ──
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _userLocation,
                        initialZoom: 13.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.busgo.client',
                        ),

                        // ── Route polylines (real roads) ──
                        if (_routesLoaded)
                          PolylineLayer(
                            polylines: _liveBuses.map((bus) {
                              return Polyline(
                                points: bus.route,
                                color: bus.color.withValues(alpha: 0.6),
                                strokeWidth: 4.5,
                                borderColor:
                                    bus.color.withValues(alpha: 0.2),
                                borderStrokeWidth: 2,
                              );
                            }).toList(),
                          ),

                        // ── User location with pulse ──
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _userLocation,
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
                                      // Pulse ring
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
                                      // Inner dot
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

                        // ── Live bus markers ──
                        if (_routesLoaded)
                          MarkerLayer(
                            markers:
                                List.generate(_liveBuses.length, (i) {
                              final bus = _liveBuses[i];
                              final isSelected = _selectedBusIndex == i;
                              return Marker(
                                point: bus.currentPosition,
                                width: isSelected ? 48 : 40,
                                height: isSelected ? 48 : 40,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedBusIndex =
                                        _selectedBusIndex == i
                                            ? null
                                            : i);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: bus.color,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.8),
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: bus.color
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
                                          bus.id,
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
                            }),
                          ),
                      ],
                    ),

                    // ── Loading overlay ──
                    if (!_routesLoaded)
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
                                  'Loading road routes...',
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
                                  color: Colors.black
                                      .withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search,
                                    size: 18,
                                    color: Color(0xFF999999)),
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
                            _mapController.move(_userLocation, 13.0),
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

                    // ── Layers button ──
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          '🗺 Layers',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // ── Live indicator ──
                    Positioned(
                      bottom: 60,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE TRACKING',
                              style: TextStyle(
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

              // ── Bottom sheet ──
              if (_selectedBusIndex != null)
                _buildLiveBusSheet(_liveBuses[_selectedBusIndex!])
              else if (selectedBus != null)
                _buildBottomSheet(selectedBus),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LIVE BUS INFO SHEET (when tapping a moving bus)
  // ═══════════════════════════════════════════════════════
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

  Widget _buildLiveBusSheet(_LiveBus bus) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
              // Route badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bus.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bus.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.speed,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${(bus.speed * 120).toStringAsFixed(0)} km/h',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.route,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${bus.route.length} road points',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Route Progress',
                      style: TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                  Text(
                    '${(bus.progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: bus.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: bus.progress,
                  minHeight: 5,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(bus.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _mapController.move(bus.currentPosition, 15.5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Track',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Board',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STATIC BUS BOTTOM SHEET (from provider)
  // ═══════════════════════════════════════════════════════
  Widget _buildBottomSheet(dynamic bus) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: 20,
            offset: const Offset(0, -4),
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
                        Text(
                          bus.displayRoute,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bus Stop ${bus.stopId} · Driver: ${bus.driverName}',
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
                'Passenger Load: Low (${bus.passengerLoad})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('Driver: ',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted)),
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
                            fontSize: 11,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
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
                  const SizedBox(width: 6),
                  Container(
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
// ROUTE DEFINITION — static config for each route
// ═══════════════════════════════════════════════════════════
class _RouteDefinition {
  final String id;
  final String label;
  final List<LatLng> waypoints;
  final Color color;
  final double speed;

  const _RouteDefinition({
    required this.id,
    required this.label,
    required this.waypoints,
    required this.color,
    required this.speed,
  });
}

// ═══════════════════════════════════════════════════════════
// LIVE BUS MODEL — simulates GPS movement along a route
// ═══════════════════════════════════════════════════════════
class _LiveBus {
  final String id;
  final String label;
  final List<LatLng> route;
  final Color color;
  final double speed; // progress per tick (0-1 range)

  double _progress = 0.0;
  bool _forward = true;

  _LiveBus({
    required this.id,
    required this.label,
    required this.route,
    required this.color,
    required this.speed,
  }) {
    // Start each bus at a random position along its route
    _progress = Random().nextDouble() * 0.6;
  }

  double get progress => _progress;

  LatLng get currentPosition {
    if (route.isEmpty) return const LatLng(6.9271, 79.8612);
    if (route.length == 1) return route[0];

    final totalSegments = route.length - 1;
    final exactIndex = _progress * totalSegments;
    final segIndex = exactIndex.floor().clamp(0, totalSegments - 1);
    final t = exactIndex - segIndex;

    final from = route[segIndex];
    final to = route[(segIndex + 1).clamp(0, route.length - 1)];

    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  void advance() {
    // Scale speed inversely with route density so buses move at
    // a consistent visual speed regardless of polyline resolution
    final step = speed * (10.0 / route.length.clamp(1, 9999));

    if (_forward) {
      _progress += step;
      if (_progress >= 1.0) {
        _progress = 1.0;
        _forward = false;
      }
    } else {
      _progress -= step;
      if (_progress <= 0.0) {
        _progress = 0.0;
        _forward = true;
      }
    }
  }
}
