import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/api_service.dart';

/// FR-28 / FR-29 — 3-step driver password recovery:
///   1. enter email      → backend issues a 6-digit PIN (printed to server console)
///   2. enter the PIN     → backend verifies + returns a short-lived reset_token
///   3. enter new password → backend updates the password hash
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _Step { email, pin, password, done }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  _Step _step = _Step.email;
  bool _loading = false;
  String? _error;
  String? _resetToken;
  bool _obscurePw = true;

  final _api = ApiService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPin() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.requestPasswordReset(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _step = _Step.pin;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not send PIN. Check your connection.';
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pinCtrl.text.trim().length < 4) {
      setState(() => _error = 'Enter the 6-digit PIN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await _api.verifyResetPin(
        _emailCtrl.text.trim(),
        _pinCtrl.text.trim(),
      );
      if (!mounted) return;
      _resetToken = res.data?['data']?['reset_token'] as String?;
      setState(() {
        _step = _Step.password;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _readError(e) ?? 'Invalid or expired PIN';
      });
    }
  }

  Future<void> _submitNewPassword() async {
    final pw = _newPwCtrl.text;
    final confirm = _confirmPwCtrl.text;
    if (pw.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (pw != confirm) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    if (_resetToken == null) {
      setState(() => _error = 'Session expired. Start again.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _api.resetPassword(
        resetToken: _resetToken!,
        newPassword: pw,
      );
      if (!mounted) return;
      setState(() {
        _step = _Step.done;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _readError(e) ?? 'Could not reset password';
      });
    }
  }

  String? _readError(Object e) {
    final dyn = e as dynamic;
    try { return dyn.response?.data?['message'] as String?; }
    catch (_) { return null; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 24),
              if (_step == _Step.email)    _buildEmailStep(),
              if (_step == _Step.pin)      _buildPinStep(),
              if (_step == _Step.password) _buildPasswordStep(),
              if (_step == _Step.done)     _buildDoneStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Email', 'PIN', 'Password', 'Done'];
    final activeIdx = _Step.values.indexOf(_step);
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i <= activeIdx;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primaryLight : const Color(0xFFE0E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmailStep() => _stepCard(
        title: 'Step 1 of 3 — your email',
        subtitle: 'We will send a 6-digit PIN to this email.',
        child: TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.mail_outline_rounded),
          ),
        ),
        primaryLabel: 'Send PIN',
        onPrimary: _requestPin,
      );

  Widget _buildPinStep() => _stepCard(
        title: 'Step 2 of 3 — verify PIN',
        subtitle: 'Enter the 6-digit PIN we sent to ${_emailCtrl.text}.',
        child: TextField(
          controller: _pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '6-digit PIN',
            counterText: '',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.pin_rounded),
          ),
        ),
        primaryLabel: 'Verify',
        onPrimary: _verifyPin,
        secondaryLabel: 'Resend',
        onSecondary: _requestPin,
      );

  Widget _buildPasswordStep() => _stepCard(
        title: 'Step 3 of 3 — new password',
        subtitle: 'Choose a new password (at least 8 characters).',
        child: Column(
          children: [
            TextField(
              controller: _newPwCtrl,
              obscureText: _obscurePw,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'New password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePw
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPwCtrl,
              obscureText: _obscurePw,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
          ],
        ),
        primaryLabel: 'Reset password',
        onPrimary: _submitNewPassword,
      );

  Widget _buildDoneStep() => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 48),
            const SizedBox(height: 12),
            Text(
              'Password reset!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can now sign in with your new password.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Back to login'),
              ),
            ),
          ],
        ),
      );

  Widget _stepCard({
    required String title,
    required String subtitle,
    required Widget child,
    required String primaryLabel,
    required VoidCallback onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          child,
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (secondaryLabel != null) ...[
                TextButton(
                  onPressed: _loading ? null : onSecondary,
                  child: Text(secondaryLabel),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _loading ? null : onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(primaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
