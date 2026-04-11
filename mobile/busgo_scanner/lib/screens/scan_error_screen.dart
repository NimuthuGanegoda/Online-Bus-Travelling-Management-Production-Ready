import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../widgets/scanner_topbar.dart';

class ScanErrorScreen extends StatefulWidget {
  const ScanErrorScreen({super.key});

  @override
  State<ScanErrorScreen> createState() => _ScanErrorScreenState();
}

class _ScanErrorScreenState extends State<ScanErrorScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
    _shakeController.forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerBg,
      body: SafeArea(
        child: Column(
          children: [
            const ScannerTopbar(isError: true),
            Expanded(child: _buildErrorContent()),
            _buildBottomStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F0A0A), Color(0xFF111111)],
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
                    AppColors.danger.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Error icon
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
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
                          'Invalid QR Code',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan was not recognized',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Error detail card
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
                              // Attempt header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Scan Attempt',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '1 / 5',
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFFEF9A9A),
                                        fontSize: 14,
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

                              // Possible reasons
                              _reason(
                                Icons.timer_off_outlined,
                                'QR code may be expired',
                              ),
                              const SizedBox(height: 10),
                              _reason(
                                Icons.check_circle_outline,
                                'Ticket already used',
                              ),
                              const SizedBox(height: 10),
                              _reason(
                                Icons.alt_route_rounded,
                                'Wrong route assignment',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Hint
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Please verify the passenger\'s ticket manually or ask them to show a valid QR code.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Try Again button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Try Again',
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _reason(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: const Color(0xFFEF9A9A).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 14,
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
        color: AppColors.danger.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.danger.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        children: [
          _stat('32', 'On Board', false),
          _divider(),
          _stat('1', 'Failed', true),
          _divider(),
          _stat('27', 'OK Today', false),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, bool highlight) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: highlight ? const Color(0xFFEF9A9A) : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFFEF9A9A).withValues(alpha: 0.7),
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
      color: AppColors.danger.withValues(alpha: 0.15),
    );
  }
}
