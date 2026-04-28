import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/scanner_topbar.dart';
import 'scan_success_screen.dart';
import 'scan_error_screen.dart';

class ActiveScannerScreen extends StatefulWidget {
  const ActiveScannerScreen({super.key});

  @override
  State<ActiveScannerScreen> createState() => _ActiveScannerScreenState();
}

class _ActiveScannerScreenState extends State<ActiveScannerScreen>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  bool _processing = false;

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
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
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _processing ? null : _openQrInputDialog,
                child: _buildViewfinder(),
              ),
            ),
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  // FR-43: send the scanned QR to the backend and display the verifying
  // message returned by the server. (Real camera scanning is handled the
  // same way once mobile_scanner is wired in — this manual entry path is
  // kept as the testable demo flow.)
  Future<void> _openQrInputDialog() async {
    final controller = TextEditingController();
    final qr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Passenger QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tap the passenger QR card or paste the code below.',
              style: TextStyle(fontSize: 13, color: Color(0xFF5A6477)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'BUSGO-xxxxxxxx-xxxx-…',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Scan'),
          ),
        ],
      ),
    );

    if (qr == null || qr.isEmpty) return;
    await _handleScan(qr);
  }

  Future<void> _handleScan(String qrCode) async {
    setState(() => _processing = true);
    try {
      final result = await ApiService().scan(qrCode);
      if (!mounted) return;

      // FR-43: small "verifying" message via snackbar.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.action == 'boarded'
              ? AppColors.success
              : AppColors.primaryLight,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(
                result.action == 'boarded'
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // After a brief moment, jump to the success screen for richer feedback.
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanSuccessScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanErrorScreen()),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _buildViewfinder() {
    return Container(
      color: AppColors.scannerSurface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final centerX = constraints.maxWidth / 2;
          final centerY = constraints.maxHeight / 2;
          const boxSize = 260.0;
          const boxHalf = boxSize / 2;
          final overlayColor = Colors.black.withValues(alpha: 0.55);

          return Stack(
            children: [
              // Dark overlay panels
              Positioned(
                top: 0, left: 0, right: 0,
                height: centerY - boxHalf,
                child: Container(color: overlayColor),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                height: centerY - boxHalf,
                child: Container(color: overlayColor),
              ),
              Positioned(
                top: centerY - boxHalf, left: 0,
                width: centerX - boxHalf, height: boxSize,
                child: Container(color: overlayColor),
              ),
              Positioned(
                top: centerY - boxHalf, right: 0,
                width: centerX - boxHalf, height: boxSize,
                child: Container(color: overlayColor),
              ),

              // Viewfinder box
              Positioned(
                top: centerY - boxHalf,
                left: centerX - boxHalf,
                child: SizedBox(
                  width: boxSize,
                  height: boxSize,
                  child: Stack(
                    children: [
                      // Subtle border
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Corner brackets
                      _corner(top: 0, left: 0, isTopLeft: true),
                      _corner(top: 0, right: 0, isTopRight: true),
                      _corner(bottom: 0, left: 0, isBottomLeft: true),
                      _corner(bottom: 0, right: 0, isBottomRight: true),

                      // Scan line
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 10 + (_scanLineAnimation.value * (boxSize - 20)),
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primaryLight.withValues(alpha: 0.4),
                                    AppColors.primaryLight,
                                    AppColors.primaryLight.withValues(alpha: 0.4),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Center crosshair
                      Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CustomPaint(
                            painter: _CrosshairPainter(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Flash button
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.flash_off_rounded,
                    color: Colors.white60,
                    size: 20,
                  ),
                ),
              ),

              // Camera switch button
              Positioned(
                top: 14,
                right: 66,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    Icons.cameraswitch_outlined,
                    color: Colors.white60,
                    size: 20,
                  ),
                ),
              ),

              // Hint text
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Position QR code within the frame',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Demo buttons
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _demoBtn(
                      'Simulate Success',
                      AppColors.success,
                      Icons.check_circle_outline,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanSuccessScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _demoBtn(
                      'Simulate Error',
                      AppColors.danger,
                      Icons.error_outline,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanErrorScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _corner({
    double? top,
    double? left,
    double? right,
    double? bottom,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border(
            top: (isTopLeft || isTopRight)
                ? const BorderSide(color: Colors.white, width: 3.5)
                : BorderSide.none,
            left: (isTopLeft || isBottomLeft)
                ? const BorderSide(color: Colors.white, width: 3.5)
                : BorderSide.none,
            right: (isTopRight || isBottomRight)
                ? const BorderSide(color: Colors.white, width: 3.5)
                : BorderSide.none,
            bottom: (isBottomLeft || isBottomRight)
                ? const BorderSide(color: Colors.white, width: 3.5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _demoBtn(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Passenger count header
          Row(
            children: [
              // Left side info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently On Board',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max capacity: 50',
                      style: GoogleFonts.inter(
                        color: AppColors.softBlue.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '32',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '/ 50',
                      style: GoogleFonts.inter(
                        color: AppColors.softBlue.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Capacity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 32 / 50,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.online),
            ),
          ),
          const SizedBox(height: 16),

          // Status + End session row
          Row(
            children: [
              // Status pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.online,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.online.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to Scan',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '14:32 · Session active',
                            style: GoogleFonts.inter(
                              color: AppColors.softBlue.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // End session button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop_circle_outlined,
                        color: AppColors.danger.withValues(alpha: 0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'End',
                        style: GoogleFonts.inter(
                          color: AppColors.danger.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;
  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
