import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/trip_provider.dart';
import '../../providers/auth_provider.dart';
import '../dashboard/main_shell.dart';

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
        builder: (context, emergency, _) {
          if (emergency.isSent) return _buildSentView(emergency);
          return _buildAlertForm(emergency);
        },
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
  //  SENT CONFIRMATION VIEW
  // ═══════════════════════════════════════════════════════
  Widget _buildSentView(EmergencyProvider emergency) {
    final alert = emergency.activeAlert;
    final typeLabel = _typeLabelMap[alert?.type] ?? alert?.type ?? 'Alert';
    final time = alert != null
        ? '${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Success animation
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  size: 52, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            Text(
              'Alert Sent Successfully',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Dispatch has been notified. Help is on the way.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7A8D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // ── Alert details card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _detailRow(
                    Icons.warning_amber_rounded,
                    'Incident Type',
                    typeLabel,
                    AppColors.danger,
                  ),
                  _divider(),
                  _detailRow(
                    Icons.access_time_rounded,
                    'Time Reported',
                    time,
                    AppColors.primaryLight,
                  ),
                  _divider(),
                  _detailRow(
                    Icons.gps_fixed_rounded,
                    'GPS Location',
                    alert != null
                        ? '${alert.latitude.toStringAsFixed(4)}, ${alert.longitude.toStringAsFixed(4)}'
                        : 'N/A',
                    AppColors.success,
                  ),
                  _divider(),
                  _detailRow(
                    Icons.verified_rounded,
                    'Alert Status',
                    'Sent to Dispatch',
                    const Color(0xFF1565C0),
                  ),
                  if (alert != null && alert.description.isNotEmpty) ...[
                    _divider(),
                    _detailRow(
                      Icons.message_rounded,
                      'Message',
                      alert.description,
                      const Color(0xFF7B1FA2),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Action buttons ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  emergency.cancelAlert();
                  _messageController.clear();
                },
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: Text(
                  'Cancel Alert',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  emergency.reset();
                  _messageController.clear();
                  context
                      .findAncestorStateOfType<MainShellState>()
                      ?.switchToTab(0);
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(
                  'Back to Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                      color: Color(0xFFD0D7E0), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E9E9E),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(height: 1, color: Color(0xFFF0F2F5));
  }

  void _sendAlert(EmergencyProvider emergency) {
    final tp = context.read<TripProvider>();
    final auth = context.read<AuthProvider>();
    emergency.sendAlert(
      driverId: auth.driver?.id ?? 'DRV-2841',
      tripId: tp.currentTrip?.id ?? 'NO-TRIP',
      latitude: tp.currentLocation.latitude,
      longitude: tp.currentLocation.longitude,
    );
  }

  static const _typeLabelMap = {
    'medical': 'Medical Emergency',
    'breakdown': 'Vehicle Breakdown',
    'criminal': 'Criminal Activity',
    'accident': 'Accident',
    'other': 'Other',
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
