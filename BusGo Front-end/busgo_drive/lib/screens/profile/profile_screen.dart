import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final driver = auth.driver;
          if (driver == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context, driver),
                Padding(
                  padding: const EdgeInsets.all(AppDimens.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPerformanceStats(driver),
                      const SizedBox(height: AppDimens.xxl),
                      _buildPersonalInfo(driver),
                      const SizedBox(height: AppDimens.xxl),
                      _buildVehicleInfo(driver),
                      const SizedBox(height: AppDimens.xxl),
                      _buildSettings(context),
                      const SizedBox(height: AppDimens.xxl),
                      _buildLogout(context, auth),
                      const SizedBox(height: AppDimens.lg),
                      Center(
                        child: Text(
                          'BusGo Drive v1.0.0 · © 2026 BusGo Ltd.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimens.lg),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic driver) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.xl,
            AppDimens.md,
            AppDimens.xl,
            AppDimens.xxxl,
          ),
          child: Column(
            children: [
              // Top bar
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.md),
                  Text(
                    'Driver Profile',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.xxl),
              // Avatar
              Container(
                width: AppDimens.avatarXl,
                height: AppDimens.avatarXl,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    driver.initials,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                driver.name,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${driver.employeeId}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: AppDimens.sm),
              StatusBadge.active(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceStats(dynamic driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Trips Completed',
                value: '${driver.tripsCompleted}',
                icon: Icons.route,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimens.md),
            Expanded(
              child: StatCard(
                label: 'Rating',
                value: driver.ratingDisplay,
                unit: '/ 5',
                icon: Icons.star_outline,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.md),
        StatCard(
          label: 'Hours Logged',
          value: '${driver.hoursLogged.toStringAsFixed(0)}',
          unit: 'hrs',
          icon: Icons.timer_outlined,
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildPersonalInfo(dynamic driver) {
    return _SectionCard(
      title: 'Personal Information',
      children: [
        _InfoRow(label: 'Full Name', value: driver.name),
        _InfoRow(label: 'Email', value: driver.email),
        _InfoRow(label: 'Phone', value: driver.phone),
        _InfoRow(label: 'License No.', value: driver.licenseNumber),
        _InfoRow(
          label: 'License Expiry',
          value: driver.licenseExpiry,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(dynamic driver) {
    return _SectionCard(
      title: 'Vehicle Information',
      children: [
        _InfoRow(label: 'Vehicle ID', value: driver.vehicleId),
        _InfoRow(label: 'Model', value: driver.vehicleModel),
        _InfoRow(
          label: 'Plate Number',
          value: driver.vehiclePlate,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context) {
    return _SectionCard(
      title: 'Settings',
      children: [
        _SettingsRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          trailing: Switch(
            value: true,
            onChanged: (_) {},
            activeColor: AppColors.primary,
          ),
        ),
        _SettingsRow(
          icon: Icons.dark_mode_outlined,
          label: 'Dark Mode',
          trailing: Switch(
            value: false,
            onChanged: (_) {},
            activeColor: AppColors.primary,
          ),
        ),
        _SettingsRow(
          icon: Icons.language,
          label: 'Language',
          trailing: Text(
            'English',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildLogout(BuildContext context, AuthProvider auth) {
    return SizedBox(
      width: double.infinity,
      height: AppDimens.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: () {
          auth.logout();
          context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded),
        label: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            fontSize: 16,
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimens.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.md,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool isLast;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.lg,
        vertical: AppDimens.sm,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppDimens.md),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
