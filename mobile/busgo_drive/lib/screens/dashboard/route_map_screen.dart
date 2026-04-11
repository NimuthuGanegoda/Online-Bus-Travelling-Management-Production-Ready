import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../services/mock_data_service.dart';
import 'main_shell.dart';

class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  double _calcDistanceKm(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, a, b);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, trip, _) {
        final route = trip.currentRoute ?? MockDataService.routes.first;
        final busLocation = trip.currentLocation;
        final nextStop = trip.nextStop ?? route.stops.first;
        final traveledPath = trip.traveledPath;

        // Remaining path: from bus position to end of polyline
        final remainingPath = <LatLng>[busLocation];
        if (route.polyline.isNotEmpty) {
          // Find the closest upcoming polyline point
          double minDist = double.infinity;
          int startIdx = 0;
          for (int i = 0; i < route.polyline.length; i++) {
            final d = _calcDistanceKm(busLocation, route.polyline[i]);
            if (d < minDist) {
              minDist = d;
              startIdx = i;
            }
          }
          for (int i = startIdx; i < route.polyline.length; i++) {
            remainingPath.add(route.polyline[i]);
          }
        }

        // Kaduwela Bus Stand info
        final kaduwela = route.stops.first;
        final distToKaduwela =
            _calcDistanceKm(busLocation, kaduwela.location);
        final etaToKaduwela = (distToKaduwela / 0.5).round();

        // Next stop info
        final distToNext = _calcDistanceKm(busLocation, nextStop.location);
        final etaToNext = (distToNext / 0.5).round();

        return Scaffold(
          body: Stack(
            children: [
              // Full map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: busLocation,
                  initialZoom: _currentZoom,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      _currentZoom = _mapController.camera.zoom;
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.busgo.drive',
                  ),
                  // Remaining route (blue, dashed feel via lower opacity)
                  if (remainingPath.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: remainingPath,
                          strokeWidth: 5,
                          color: AppColors.primaryLight.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  // Traveled route (bright green highlight)
                  if (traveledPath.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: traveledPath,
                          strokeWidth: 6,
                          color: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                  // Stop markers
                  if (route.stops.isNotEmpty)
                    MarkerLayer(
                      markers: List.generate(route.stops.length, (i) {
                        final stop = route.stops[i];
                        final isCompleted = i < trip.currentStopIndex;
                        final isCurrent = i == trip.currentStopIndex;
                        return Marker(
                          point: stop.location,
                          width: 28,
                          height: 28,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.success
                                    : isCurrent
                                        ? AppColors.warning
                                        : AppColors.primaryLight,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isCompleted
                                      ? AppColors.success
                                      : isCurrent
                                          ? AppColors.warning
                                          : AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  // Real-time bus icon marker
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: busLocation,
                        width: 48,
                        height: 48,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final pulseScale =
                                1.0 + _pulseController.value * 0.6;
                            final pulseOpacity =
                                0.4 * (1 - _pulseController.value);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulse ring
                                Container(
                                  width: 48 * pulseScale,
                                  height: 48 * pulseScale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryLight
                                        .withValues(alpha: pulseOpacity),
                                  ),
                                ),
                                // Bus icon circle
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.directions_bus_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Title overlay
              Positioned(
                top: MediaQuery.of(context).padding.top + 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus_rounded,
                            size: 16, color: Color(0xFF64B5F6)),
                        const SizedBox(width: 6),
                        Text(
                          'Route ${route.routeNumber} \u2014 Live',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Map controls
              Positioned(
                right: 12,
                top: MediaQuery.of(context).padding.top + 50,
                child: Column(
                  children: [
                    _mapCtrlBtn(Icons.add, () {
                      _currentZoom = (_currentZoom + 1).clamp(5.0, 18.0);
                      _mapController.move(
                          _mapController.camera.center, _currentZoom);
                    }),
                    const SizedBox(height: 6),
                    _mapCtrlBtn(Icons.remove, () {
                      _currentZoom = (_currentZoom - 1).clamp(5.0, 18.0);
                      _mapController.move(
                          _mapController.camera.center, _currentZoom);
                    }),
                    const SizedBox(height: 6),
                    _mapCtrlBtn(Icons.my_location, () {
                      _mapController.move(busLocation, 14);
                    }),
                  ],
                ),
              ),

              // Floating emergency button
              Positioned(
                right: 14,
                bottom: 190,
                child: GestureDetector(
                  onTap: () {
                    context
                        .findAncestorStateOfType<MainShellState>()
                        ?.switchToTab(2);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        size: 24, color: Colors.white),
                  ),
                ),
              ),

              // Bottom info card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStopInfoRow(
                            icon: Icons.flag_rounded,
                            iconColor: AppColors.primaryLight,
                            name: kaduwela.name,
                            etaMin: etaToKaduwela,
                            distKm: distToKaduwela,
                            label: 'ORIGIN',
                          ),
                          if (nextStop.id != kaduwela.id) ...[
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(
                                  height: 1,
                                  color: const Color(0xFFEEEEEE)),
                            ),
                            _buildStopInfoRow(
                              icon: Icons.navigation_rounded,
                              iconColor: AppColors.success,
                              name: nextStop.name,
                              etaMin: etaToNext,
                              distKm: distToNext,
                              label: 'NEXT STOP',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopInfoRow({
    required IconData icon,
    required Color iconColor,
    required String name,
    required int etaMin,
    required double distKm,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9E9E9E),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 3),
                Text(
                  '$etaMin min',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${distKm.toStringAsFixed(1)} km away',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF8094A8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _mapCtrlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}
