import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/stat_card.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<TripProvider>(
        builder: (context, tripProvider, _) {
          final trip = tripProvider.lastCompletedTrip;

          if (trip == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No trip data available',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.lg),
                  SizedBox(
                    width: 200,
                    height: AppDimens.buttonHeightSm,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Back to Routes'),
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.xl),
              child: Column(
                children: [
                  const SizedBox(height: AppDimens.xl),
                  _buildSuccessHeader(),
                  const SizedBox(height: AppDimens.xxl),
                  _buildRouteInfo(trip),
                  const SizedBox(height: AppDimens.xl),
                  _buildStatsGrid(trip),
                  const SizedBox(height: AppDimens.xl),
                  _buildTimeline(trip),
                  const SizedBox(height: AppDimens.xxxl),
                  _buildActions(context, tripProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.3),
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 36,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppDimens.lg),
        Text(
          'Trip Completed',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Great job! Here\'s your trip summary.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(dynamic trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          Text(
            'Route ${trip.routeNumber}',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trip.routeName,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic trip) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Total Passengers',
                value: '${trip.passengersBoarded}',
                icon: Icons.people_outline,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: StatCard(
                label: 'Distance',
                value: trip.distanceCovered.toStringAsFixed(1),
                unit: 'km',
                icon: Icons.straighten,
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
                label: 'Duration',
                value: trip.duration,
                icon: Icons.timer_outlined,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: StatCard(
                label: 'Stops Completed',
                value: '${trip.stopsCompleted}/${trip.totalStops}',
                icon: Icons.location_on_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Avg Speed',
                value: trip.avgSpeed.toStringAsFixed(1),
                unit: 'km/h',
                icon: Icons.speed,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: StatCard(
                label: 'Alighted',
                value: '${trip.passengersAlighted}',
                icon: Icons.person_remove_outlined,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(dynamic trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.md),
          _TimelineItem(
            icon: Icons.play_circle_outline,
            label: 'Trip Started',
            time: _formatTime(trip.startTime),
            color: AppColors.success,
          ),
          _TimelineItem(
            icon: Icons.stop_circle_outlined,
            label: 'Trip Ended',
            time: trip.endTime != null
                ? _formatTime(trip.endTime!)
                : 'N/A',
            color: AppColors.danger,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, TripProvider tp) {
    return Column(
      children: [
        AppButton(
          text: 'Submit Report',
          icon: Icons.send_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Trip report submitted successfully!',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppDimens.md),
        AppButton(
          text: 'Start New Trip',
          icon: Icons.replay_rounded,
          isOutlined: true,
          onPressed: () {
            tp.resetForNewTrip();
            context.go('/dashboard');
          },
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Icon(icon, size: 22, color: color),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: AppDimens.md),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppDimens.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
