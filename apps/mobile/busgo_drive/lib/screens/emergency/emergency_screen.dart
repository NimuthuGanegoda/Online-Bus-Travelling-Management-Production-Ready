import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';


class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyProvider>().reset();
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Consumer<EmergencyProvider>(
        builder: (context, emergency, _) => _buildAlertForm(emergency),
      ),
    );
  }

  void _showSuccessDialog(EmergencyProvider emergency) {
    final typeLabel = _typeLabelMap[emergency.selectedType] ?? emergency.selectedType ?? 'Alert';
    final typeEmoji = _typeEmojiMap[emergency.selectedType] ?? '🚨';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green checkmark icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Alert Sent Successfully',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              // Emergency type
              Text(
                'Emergency type: $typeEmoji $typeLabel',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 8),
              // Sub message
              Text(
                'Help is on the way. Stay calm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF78909C),
                ),
              ),
              const SizedBox(height: 28),
              // Close button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    emergency.reset();
                    _messageController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  // ═══════════════════════════════════════════════════════
  //  ALERT FORM
  // ═══════════════════════════════════════════════════════
  Widget _buildAlertForm(EmergencyProvider emergency) {
    final trip = context.watch<TripProvider>();
    final routeNum = trip.currentRoute?.routeNumber ?? '138';
    final isTypeSelected = emergency.selectedType != null;

    return Column(
      children: [
        // ── Header ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8E0000), Color(0xFFC62828)],
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 20,
            left: 24,
            right: 24,
          ),
          child: Column(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.emergency_rounded,
                    size: 28, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'EMERGENCY ALERT',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Route $routeNum  \u2022  ${TimeOfDay.now().format(context)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                _sectionLabel('SELECT INCIDENT TYPE'),
                const SizedBox(height: 10),

                // Options
                _buildOption(
                  emergency: emergency,
                  typeKey: 'medical',
                  icon: Icons.medical_services_rounded,
                  iconBg: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFC62828),
                  title: 'Medical Emergency',
                  subtitle: 'Passenger requires immediate medical help',
                ),
                _buildOption(
                  emergency: emergency,
                  typeKey: 'breakdown',
                  icon: Icons.build_circle_rounded,
                  iconBg: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFE65100),
                  title: 'Vehicle Breakdown',
                  subtitle: 'Bus mechanical failure or engine issue',
                ),
                _buildOption(
                  emergency: emergency,
                  typeKey: 'criminal',
                  icon: Icons.shield_rounded,
                  iconBg: const Color(0xFFEDE7F6),
                  iconColor: const Color(0xFF4A148C),
                  title: 'Criminal Activity',
                  subtitle: 'Threat, theft, or crime on board',
                ),
                _buildOption(
                  emergency: emergency,
                  typeKey: 'accident',
                  icon: Icons.car_crash_rounded,
                  iconBg: const Color(0xFFFFEBEE),
                  iconColor: const Color(0xFFD32F2F),
                  title: 'Accident',
                  subtitle: 'Collision or road incident',
                ),
                _buildOption(
                  emergency: emergency,
                  typeKey: 'other',
                  icon: Icons.report_rounded,
                  iconBg: const Color(0xFFF3E5F5),
                  iconColor: const Color(0xFF7B1FA2),
                  title: 'Other',
                  subtitle: 'Describe the situation below',
                ),

                // ── Message field ──
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: emergency.selectedType == 'other'
                      ? Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('DESCRIBE INCIDENT'),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFD0D7E0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(alpha: 0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _messageController,
                                  maxLines: 3,
                                  maxLength: 200,
                                  onChanged: emergency.setDescription,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'What is happening? Be specific...',
                                    hintStyle: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFFADB5BD),
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(
                                          left: 14, bottom: 40),
                                      child: Icon(Icons.edit_note_rounded,
                                          size: 20,
                                          color: Color(0xFFADB5BD)),
                                    ),
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        14, 14, 14, 14),
                                    border: InputBorder.none,
                                    counterStyle: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: const Color(0xFFADB5BD),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 18),

                // ── GPS info strip ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed_rounded,
                          size: 16, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'GPS location will be sent automatically with this alert',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Hold instruction ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    border:
                        Border.all(color: const Color(0xFFFFD54F), width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECB3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.touch_app_rounded,
                            size: 18, color: Color(0xFFE65100)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hold to confirm',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Press and hold for 5 seconds to send alert to dispatch',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFFF57F17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── SOS Button ──
                _SosHoldButton(
                  isLoading: emergency.isSending,
                  isEnabled: isTypeSelected,
                  onActivated: () {
                    HapticFeedback.heavyImpact();
                    _sendAlert(emergency);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  //  OPTION CARD
  // ═══════════════════════════════════════════════════════
  Widget _buildOption({
    required EmergencyProvider emergency,
    required String typeKey,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final isSelected = emergency.selectedType == typeKey;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        emergency.selectType(typeKey);
        if (typeKey != 'other') {
          _messageController.clear();
          emergency.setDescription('');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF5F5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.danger : const Color(0xFFE8EDF2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.danger.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8094A8),
                    ),
                  ),
                ],
              ),
            ),
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.danger : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.danger
                      : const Color(0xFFD0D7E0),
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Center(
                      child:
                          Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF6B7A8D),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _sendAlert(EmergencyProvider emergency) async {
    final tp = context.read<TripProvider>();
    final auth = context.read<AuthProvider>();
    await emergency.sendAlert(
      driverId: auth.driver?.id ?? 'DRV-2841',
      tripId: tp.currentTrip?.id ?? 'NO-TRIP',
      latitude: tp.currentLocation.latitude,
      longitude: tp.currentLocation.longitude,
    );
    if (mounted && emergency.isSent) {
      _showSuccessDialog(emergency);
    }
  }

  static const _typeLabelMap = {
    'medical': 'Medical Emergency',
    'breakdown': 'Vehicle Breakdown',
    'criminal': 'Criminal Activity',
    'accident': 'Accident',
    'other': 'Other',
  };

  static const _typeEmojiMap = {
    'medical': '🏥',
    'breakdown': '🔧',
    'criminal': '🛡️',
    'accident': '🚗',
    'other': '⚠️',
  };
}

// ═══════════════════════════════════════════════════════
//  SOS HOLD BUTTON
// ═══════════════════════════════════════════════════════
class _SosHoldButton extends StatefulWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onActivated;

  const _SosHoldButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onActivated,
  });

  @override
  State<_SosHoldButton> createState() => _SosHoldButtonState();
}

class _SosHoldButtonState extends State<_SosHoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onActivated();
          _controller.reset();
          setState(() => _isHolding = false);
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.danger.withValues(alpha: 0.8),
              AppColors.danger,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SENDING ALERT...',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onLongPressStart: widget.isEnabled
          ? (_) {
              HapticFeedback.heavyImpact();
              setState(() => _isHolding = true);
              _controller.forward();
            }
          : null,
      onLongPressEnd: (_) {
        _controller.reset();
        setState(() => _isHolding = false);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: widget.isEnabled
                  ? const LinearGradient(
                      colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                    )
                  : null,
              color: widget.isEnabled ? null : const Color(0xFFBDBDBD),
              borderRadius: BorderRadius.circular(16),
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.danger.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                // Progress fill
                if (_isHolding)
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                // Content
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isHolding
                            ? Icons.hourglass_top_rounded
                            : Icons.emergency_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isHolding
                            ? 'SENDING IN ${(5 - (progress * 5)).ceil()}s...'
                            : 'HOLD TO SEND ALERT',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
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
}
