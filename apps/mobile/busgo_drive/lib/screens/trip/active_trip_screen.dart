import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/utils/helpers.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/live_map_widget.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class ActiveTripScreen extends StatelessWidget {
  const ActiveTripScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, _) {
          final trip = tripProvider.currentTrip;
          final route = tripProvider.currentRoute;

          if (trip == null || route == null) {
            return _buildNoTrip(context);
          }

          return Column(
            children: [
              // Header with SOS button
              _buildHeader(context, tripProvider),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Live map
                      SizedBox(
                        height: 240,
                        child: LiveMapWidget(
                          center: tripProvider.currentLocation,
                          zoom: 14,
                          routePolyline:
                              route.polyline,
                          stopLocations:
                              route.stops.map((s) => s.location).toList(),
                          stopNames:
                              route.stops.map((s) => s.name).toList(),
                          busLocation: tripProvider.currentLocation,
                          currentStopIndex: tripProvider.currentStopIndex,
                        ),
                      ),
                      // Trip info panel
                      _buildTripPanel(context, tripProvider),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TripProvider tp) {
    final trip = tp.currentTrip!;
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.xl,
            AppDimens.sm,
            AppDimens.xl,
            AppDimens.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Route ${trip.routeNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: AppDimens.sm),
                        tp.status == TripStatus.atStop
                            ? StatusBadge.atStop()
                            : StatusBadge.onRoute(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trip.routeName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                ),
              ),
              // SOS button
              GestureDetector(
                onTap: () => context.push('/emergency'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.sosRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sosRed.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SOS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripPanel(BuildContext context, TripProvider tp) {
    final trip = tp.currentTrip!;
    final nextStop = tp.nextStop;
    final isAtStop = tp.status == TripStatus.atStop;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      padding: const EdgeInsets.all(AppDimens.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Next stop
          if (nextStop != null) ...[
            Container(
              padding: const EdgeInsets.all(AppDimens.lg),
              decoration: BoxDecoration(
                color: isAtStop
                    ? AppColors.warningLight
                    : AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: isAtStop
                      ? AppColors.warning.withValues(alpha: 0.3)
                      : AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAtStop
                        ? Icons.location_on
                        : Icons.navigate_next_rounded,
                    color: isAtStop ? AppColors.warning : AppColors.info,
                    size: 28,
                  ),
                  const SizedBox(width: AppDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAtStop ? 'Arrived at Stop' : 'Next Stop',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          nextStop.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Stop ${nextStop.sequence}/${tp.currentRoute!.stops.length}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'ETA ${tp.etaMinutes}m',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.lg),
          ],

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Passengers',
                  value: trip.passengerDisplay,
                  icon: Icons.people_outline,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: StatCard(
                  label: 'Speed',
                  value: tp.currentSpeed.toStringAsFixed(0),
                  unit: 'km/h',
                  icon: Icons.speed,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Distance',
                  value: trip.distanceCovered.toStringAsFixed(1),
                  unit: 'km',
                  icon: Icons.straighten,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: StatCard(
                  label: 'Duration',
                  value: trip.duration,
                  icon: Icons.timer_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xl),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trip Progress',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${trip.stopsCompleted}/${trip.totalStops} stops',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: trip.progress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.tripActive,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.xl),

          // Passenger controls
          if (isAtStop) _buildPassengerControls(tp),
          const SizedBox(height: AppDimens.lg),

          // Action buttons
          _buildActionButtons(context, tp),
        ],
      ),
    );
  }

  Widget _buildPassengerControls(TripProvider tp) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger Count',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          Row(
            children: [
              Expanded(
                child: _PassengerButton(
                  label: 'Board',
                  icon: Icons.person_add_outlined,
                  color: AppColors.success,
                  onTap: () => tp.updatePassengers(1, 0),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: _PassengerButton(
                  label: 'Alight',
                  icon: Icons.person_remove_outlined,
                  color: AppColors.warning,
                  onTap: () => tp.updatePassengers(0, 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, TripProvider tp) {
    final isAtStop = tp.status == TripStatus.atStop;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: AppDimens.buttonHeight,
            child: isAtStop
                ? ElevatedButton.icon(
                    onPressed: () => tp.departFromStop(),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'Depart',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => tp.arriveAtStop(),
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      'Arrived',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMd),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppDimens.md),
        SizedBox(
          height: AppDimens.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () {
              tp.endTrip();
              context.go('/trip-summary');
            },
            icon: const Icon(Icons.stop_rounded),
            label: Text(
              'End',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTrip(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimens.lg),
          Text(
            'No Active Trip',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.xxl),
          SizedBox(
            width: 200,
            height: AppDimens.buttonHeightSm,
            child: ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Select Route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassengerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PassengerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDimens.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
