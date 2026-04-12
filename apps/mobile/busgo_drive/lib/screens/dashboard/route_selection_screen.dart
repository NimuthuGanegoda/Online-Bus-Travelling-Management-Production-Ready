import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/route_provider.dart';
import '../../providers/trip_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/route_card.dart';
import '../../widgets/status_badge.dart';

class RouteSelectionScreen extends StatefulWidget {
  const RouteSelectionScreen({super.key});

  @override
  State<RouteSelectionScreen> createState() => _RouteSelectionScreenState();
}

class _RouteSelectionScreenState extends State<RouteSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RouteProvider>().loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Consumer<RouteProvider>(
              builder: (context, routeProvider, _) {
                if (routeProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDriverCard(),
                      const SizedBox(height: AppDimens.xxl),
                      _buildAssignedRoutes(routeProvider),
                      const SizedBox(height: AppDimens.xxl),
                      _buildAvailableRoutes(routeProvider),
                      const SizedBox(height: AppDimens.xxl),
                      _buildStartButton(routeProvider),
                      const SizedBox(height: AppDimens.lg),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.xl,
            AppDimens.md,
            AppDimens.xl,
            AppDimens.lg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Route',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Choose your route to begin',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          auth.driver?.initials ?? 'D',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final driver = auth.driver;
        if (driver == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(AppDimens.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    driver.initials,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${driver.vehicleModel} · ${driver.vehiclePlate}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.active(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedRoutes(RouteProvider provider) {
    final assigned = provider.assignedRoutes;
    if (assigned.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned Routes',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        ...assigned.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.md),
            child: RouteCard(
              route: route,
              isSelected: provider.selectedRoute?.id == route.id,
              onTap: () => provider.selectRoute(route),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAvailableRoutes(RouteProvider provider) {
    final available = provider.availableRoutes;
    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Routes',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        ...available.map((route) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.md),
            child: RouteCard(
              route: route,
              isSelected: provider.selectedRoute?.id == route.id,
              onTap: () => provider.selectRoute(route),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStartButton(RouteProvider provider) {
    final selected = provider.selectedRoute;
    return AppButton(
      text: selected != null
          ? 'Start Trip — Route ${selected.routeNumber}'
          : 'Select a Route to Begin',
      icon: Icons.play_arrow_rounded,
      onPressed: selected != null
          ? () {
              context.read<TripProvider>().startTrip(selected);
              context.go('/active-trip');
            }
          : null,
      color: selected != null ? AppColors.success : AppColors.textMuted,
    );
  }
}
