import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart' hide RouteData;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/route_data.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/routing_service.dart';
import '../../widgets/bus_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _userLocation = LatLng(6.9271, 79.8612);

  // Mini-map route state
  List<List<LatLng>> _routePolylines = [];
  List<_DashBus> _dashBuses = [];
  Timer? _busTimer;
  bool _routesReady = false;

  static const _routeDefs = [
    _DashRouteDef('138', RouteData.route138Waypoints, AppColors.secondary),
    _DashRouteDef('163', RouteData.route163Waypoints, AppColors.warning),
    _DashRouteDef('171', RouteData.route171Waypoints, Color(0xFF7B1FA2)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusProvider>().loadAll();
      context.read<TripProvider>().loadTripHistory();

      // Sync user from auth provider
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<UserProvider>().setUser(auth.currentUser!);
      }
    });
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final polylines = await RoutingService.fetchRoutes(
      _routeDefs.map((d) => d.waypoints.toList()).toList(),
    );
    if (!mounted) return;
    setState(() {
      _routePolylines = polylines;
      _dashBuses = List.generate(_routeDefs.length, (i) {
        return _DashBus(
          id: _routeDefs[i].id,
          route: polylines[i],
          color: _routeDefs[i].color,
        );
      });
      _routesReady = true;
    });
    _busTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _tickBuses(),
    );
  }

  void _tickBuses() {
    if (!mounted) return;
    setState(() {
      for (final b in _dashBuses) {
        b.advance();
      }
    });
  }

  @override
  void dispose() {
    _busTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildMapPreview(),
                  const SizedBox(height: 8),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildNearbyBuses(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Helpers.getGreeting(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.lightBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userProvider.user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              final shell = StatefulNavigationShell.maybeOf(context);
              shell?.goBranch(1);
            },
            child: SizedBox(
              height: 180,
              child: Stack(
                children: [
                // Real map
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _userLocation,
                    initialZoom: 12.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.busgo.client',
                    ),
                    // Route polylines
                    if (_routesReady)
                      PolylineLayer(
                        polylines: List.generate(
                          _routePolylines.length,
                          (i) => Polyline(
                            points: _routePolylines[i],
                            color: _routeDefs[i]
                                .color
                                .withValues(alpha: 0.6),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    // Bus stop markers
                    MarkerLayer(
                      markers: RouteData.busStops.map((pos) {
                        return Marker(
                          point: pos,
                          width: 10,
                          height: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.danger,
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // User location
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation,
                          width: 16,
                          height: 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Live bus markers
                    if (_routesReady)
                      MarkerLayer(
                        markers: _dashBuses.map((bus) {
                          return Marker(
                            point: bus.currentPosition,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: bus.color,
                                borderRadius:
                                    BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: bus.color
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.directions_bus,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                  Text(
                                    bus.id,
                                    style: const TextStyle(
                                      fontSize: 6,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                // Live badge overlay
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Live Map',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                // Tap to open hint
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1B2A)
                            .withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1A6FA8)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_full_rounded,
                              size: 11, color: Color(0xFF5BB8F5)),
                          SizedBox(width: 4),
                          Text(
                            'Tap to open full map',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5BB8F5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickAction(
            icon: Icons.search_rounded,
            label: 'Search',
            color: const Color(0xFFEDEAFF),
            iconColor: const Color(0xFF5E35B1),
            onTap: () {
              final shell = StatefulNavigationShell.maybeOf(context);
              shell?.goBranch(2);
            },
          ),
          _QuickAction(
            icon: Icons.notifications_active_rounded,
            label: 'Emergency',
            color: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFE53935),
            onTap: () => context.push('/emergency'),
          ),
          _QuickAction(
            icon: Icons.phone_android_rounded,
            label: 'My QR',
            color: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF43A047),
            onTap: () => context.push('/qr'),
          ),
          _QuickAction(
            icon: Icons.assignment_rounded,
            label: 'History',
            color: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFF57C00),
            onTap: () => context.push('/history'),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyBuses() {
    return Consumer<BusProvider>(
      builder: (context, busProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Text(
                'Nearby Buses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: busProvider.nearbyBuses.map((bus) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BusCard(bus: bus),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: iconColor ?? Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// Helper models for the dashboard mini-map
// ═══════════════════════════════════════════════════════
class _DashRouteDef {
  final String id;
  final List<LatLng> waypoints;
  final Color color;

  const _DashRouteDef(this.id, this.waypoints, this.color);
}

class _DashBus {
  final String id;
  final List<LatLng> route;
  final Color color;

  double _progress = 0.0;
  bool _forward = true;

  _DashBus({
    required this.id,
    required this.route,
    required this.color,
  }) {
    _progress = Random().nextDouble() * 0.6;
  }

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
    final step = 0.12 * (10.0 / route.length.clamp(1, 9999));
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
