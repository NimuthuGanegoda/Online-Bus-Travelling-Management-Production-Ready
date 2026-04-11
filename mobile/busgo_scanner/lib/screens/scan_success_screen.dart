import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/scanner_topbar.dart';

class ScanSuccessScreen extends StatefulWidget {
  const ScanSuccessScreen({super.key});

  @override
  State<ScanSuccessScreen> createState() => _ScanSuccessScreenState();
}

class _ScanSuccessScreenState extends State<ScanSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _popAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.elasticOut,
    );
    _popController.forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fadeController.forward();
    });

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _popController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBg,
      body: SafeArea(
        child: Column(
          children: [
            const ScannerTopbar(),
            Expanded(child: _buildSuccessContent()),
            _buildBottomStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A1F0C), Color(0xFF111111)],
        ),
      ),
      child: Stack(
        children: [
          // Radial glow
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Check icon
                  ScaleTransition(
                    scale: _popAnimation,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Passenger Verified',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'QR code scanned successfully',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Passenger card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'AF',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Amira Fernando',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'TKT-20260318-4821',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Valid',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF81C784),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _chip(Icons.route_rounded, 'Route 138'),
                                  _chip(Icons.event_seat_rounded, 'Seat 14A'),
                                  _chip(Icons.access_time_rounded, '14:32'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Count update
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                color: const Color(0xFF81C784),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Count updated: 33 passengers',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF81C784),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Progress bar
                        SizedBox(
                          width: 120,
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                return LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF81C784),
                                      ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Auto-returning in 3s...',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.35)),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat('33', 'On Board'),
          _divider(),
          _stat('17', 'Seats Free'),
          _divider(),
          _stat('28', 'Scanned Today'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.softBlue.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}
