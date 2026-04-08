import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/trip_provider.dart';
import '../../providers/route_provider.dart';
import '../../services/mock_data_service.dart';
import 'main_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rp = context.read<RouteProvider>();
      if (rp.routes.isEmpty) rp.loadRoutes();
      final tp = context.read<TripProvider>();
      if (tp.currentTrip == null && rp.routes.isNotEmpty) {
        final route138 =
            rp.routes.where((r) => r.routeNumber == '138').firstOrNull;
        if (route138 != null) tp.startTrip(route138);
      }
    });
  }

  void _goToMapTab() {
    context.findAncestorStateOfType<MainShellState>()?.switchToTab(1);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripProvider>(
      builder: (context, trip, _) {
        final passengers = trip.currentTrip?.currentPassengers ?? 32;
        const totalSeats = 50;
        final fillPercent = (passengers / totalSeats).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: const Color(0xFFEDF1F7),
          body: Column(
            children: [
              _buildTopBar(trip),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    children: [
                      _buildPassengerGauge(passengers, totalSeats, fillPercent),
                      const SizedBox(height: 14),
                      _buildMapPreview(trip),
                      const SizedBox(height: 14),
                      _buildNextStopCard(trip),
                      const SizedBox(height: 14),
                      _buildTripStats(trip),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(TripProvider trip) {
    final routeNumber = trip.currentRoute?.routeNumber ?? '138';
    final routeName =
        trip.currentRoute?.routeDirection ?? 'Kaduwela \u2192 Colombo Fort';
    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A2342), Color(0xFF123564)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On Duty \u2014 Route $routeNumber',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  routeName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF90CAF9),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ON DUTY',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerGauge(
      int passengers, int totalSeats, double fillPercent) {
    Color gaugeColor;
    if (fillPercent < 0.5) {
      gaugeColor = AppColors.success;
    } else if (fillPercent < 0.75) {
      gaugeColor = AppColors.warning;
    } else if (fillPercent < 0.95) {
      gaugeColor = AppColors.danger;
    } else {
      gaugeColor = const Color(0xFF212121);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A2E),
            Color(0xFF132F54),
            Color(0xFF1E5AA8),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A2E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_alt_rounded,
                        size: 14, color: Color(0xFF64B5F6)),
                    const SizedBox(width: 4),
                    Text(
                      'PASSENGER LOAD',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF90CAF9),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: _GaugeRingPainter(
                fillPercent: fillPercent,
                fillColor: gaugeColor,
                bgColor: Colors.white.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$passengers',
                      style: GoogleFonts.inter(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/ $totalSeats seats',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF90CAF9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'on board',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: const Color(0xFF64B5F6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1).withValues(alpha: 0.9),
              border: Border.all(color: const Color(0xFFFFD54F)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 15, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Text(
                  'STOP if bell rings',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(const Color(0xFF66BB6A), 'Low'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFFFB74D), 'Moderate'),
              const SizedBox(width: 16),
              _legendItem(const Color(0xFFEF5350), 'High'),
              const SizedBox(width: 16),
              _legendItem(Colors.white, 'Full'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF90CAF9),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(TripProvider trip) {
    final route = trip.currentRoute ?? MockDataService.routes.first;
    final busLocation = trip.currentLocation;
    final traveledPath = trip.traveledPath;

    return GestureDetector(
      onTap: _goToMapTab,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E8F0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A2342), Color(0xFF123564)],
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map_rounded,
                          size: 16, color: const Color(0xFF64B5F6)),
                      const SizedBox(width: 6),
                      Text(
                        'Live Route Map',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Tap to expand',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF90CAF9),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.open_in_full_rounded,
                          size: 12, color: Color(0xFF90CAF9)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 150,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: busLocation,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.busgo.drive',
                  ),
                  // Full route (faded)
                  if (route.polyline.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route.polyline,
                          strokeWidth: 4,
                          color: AppColors.primaryLight.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  // Traveled path (green)
                  if (traveledPath.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: traveledPath,
                          strokeWidth: 5,
                          color: const Color(0xFF00C853),
                        ),
                      ],
                    ),
                  // Station markers
                  if (route.stops.isNotEmpty)
                    MarkerLayer(
                      markers: List.generate(route.stops.length, (i) {
                        final stop = route.stops[i];
                        final isCompleted = i < trip.currentStopIndex;
                        return Marker(
                          point: stop.location,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.success
                                    : AppColors.primaryLight,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: isCompleted
                                      ? AppColors.success
                                      : AppColors.primaryLight,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  // Bus icon
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: busLocation,
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStopCard(TripProvider trip) {
    final nextStop = trip.nextStop;
    final etaMin = trip.etaMinutes;
    final stopsCompleted = trip.currentStopIndex;
    final totalStops = trip.currentRoute?.stops.length ?? 7;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.navigation_rounded,
                        size: 13, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'NEXT STOP',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$stopsCompleted / $totalStops stops',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on_rounded,
                    size: 24, color: AppColors.primaryLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextStop?.name ?? 'Trip Complete',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          nextStop != null
                              ? '$etaMin min'
                              : 'Completed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.straighten_rounded,
                            size: 13, color: const Color(0xFF6B7A8D)),
                        const SizedBox(width: 4),
                        Text(
                          '${(etaMin * 0.3).toStringAsFixed(1)} km',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B7A8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalStops > 0 ? stopsCompleted / totalStops : 0,
              minHeight: 5,
              backgroundColor: const Color(0xFFE4EAF0),
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripStats(TripProvider trip) {
    final speed = trip.currentSpeed;
    final distance = trip.currentTrip?.distanceCovered ?? 0.0;
    final startTime = trip.currentTrip?.startTime;
    final durationMin = startTime != null
        ? DateTime.now().difference(startTime).inMinutes
        : 0;
    final boarded = trip.currentTrip?.passengersBoarded ?? 0;

    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.speed_rounded,
            value: speed.toStringAsFixed(0),
            unit: 'km/h',
            label: 'Speed',
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.route_rounded,
            value: distance.toStringAsFixed(1),
            unit: 'km',
            label: 'Distance',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.timer_outlined,
            value: '$durationMin',
            unit: 'min',
            label: 'Duration',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            icon: Icons.people_alt_rounded,
            value: '$boarded',
            unit: '',
            label: 'Boarded',
            color: const Color(0xFF7B1FA2),
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String unit,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8094A8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7A8D),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeRingPainter extends CustomPainter {
  final double fillPercent;
  final Color fillColor;
  final Color bgColor;

  _GaugeRingPainter({
    required this.fillPercent,
    required this.fillColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 14.0;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final sweepAngle = 2 * pi * fillPercent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugeRingPainter old) =>
      old.fillPercent != fillPercent || old.fillColor != fillColor;
}
