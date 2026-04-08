import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final List<TextEditingController> _pinControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _pinFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final n in _pinFocusNodes) {
      n.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeader(auth),
                  const SizedBox(height: 24),
                  _buildStepIndicator(auth.forgotPasswordStep),
                  const SizedBox(height: 16),
                  if (auth.forgotPasswordStep == 0) _buildStep1(auth),
                  if (auth.forgotPasswordStep == 1) _buildStep2(auth),
                  if (auth.forgotPasswordStep == 2) _buildStep3(auth),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final titles = ['Forgot Password', 'Verify PIN', 'New Password'];
    final step = auth.forgotPasswordStep;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (step > 0) {
              auth.resetForgotPassword();
            } else {
              context.pop();
            }
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.headerBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          titles[step],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(0, currentStep),
        _buildStepLine(0, currentStep),
        _buildStepDot(1, currentStep),
        _buildStepLine(1, currentStep),
        _buildStepDot(2, currentStep),
      ],
    );
  }

  Widget _buildStepDot(int step, int currentStep) {
    final isDone = step < currentStep;
    final isActive = step == currentStep;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.success
            : isActive
                ? AppColors.secondary
                : AppColors.border,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isDone
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : Text(
              '${step + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildStepLine(int step, int currentStep) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: step < currentStep ? AppColors.success : AppColors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  // -- Step 1: Enter Email --
  Widget _buildStep1(AuthProvider auth) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('\u{1F4E7}', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 10),
        const Text(
          'Enter Your Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "We'll send a 6-digit PIN to your\nregistered email address.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Email Address',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF999999),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (auth.errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 12, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  auth.errorMessage!,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          text: 'Send PIN \u2192',
          isLoading: auth.isLoading,
          onPressed: () async {
            await auth.sendResetPin(_emailController.text.trim());
          },
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Back to Login',
            style: TextStyle(fontSize: 12, color: AppColors.secondary),
          ),
        ),
      ],
    );
  }

  // -- Step 2: Enter PIN --
  Widget _buildStep2(AuthProvider auth) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('\u{1F510}', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 10),
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.6,
            ),
            children: [
              const TextSpan(text: 'Enter the 6-digit PIN sent to\n'),
              TextSpan(
                text: auth.forgotEmail,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Show the simulated PIN as a hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Demo PIN: ${auth.generatedPin}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // PIN boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = _pinControllers[index].text.isNotEmpty;
            return Container(
              width: 38,
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _pinControllers[index],
                focusNode: _pinFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  filled: true,
                  fillColor: isFilled
                      ? const Color(0xFFF0F4FF)
                      : const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.secondary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isFilled
                          ? AppColors.secondary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  if (value.isNotEmpty && index < 5) {
                    _pinFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _pinFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        if (auth.errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber,
                  size: 12, color: AppColors.danger),
              const SizedBox(width: 4),
              Text(
                auth.errorMessage!,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.danger),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Verify PIN \u2192',
          isLoading: auth.isLoading,
          onPressed: () async {
            final pin =
                _pinControllers.map((c) => c.text).join();
            await auth.verifyPin(pin);
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Didn't receive it? ",
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            GestureDetector(
              onTap: () async {
                await auth.sendResetPin(auth.forgotEmail);
              },
              child: const Text(
                'Resend PIN',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -- Step 3: New Password --
  Widget _buildStep3(AuthProvider auth) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text('\u{1F512}', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 10),
        const Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Must be at least 8 characters',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 22),

        // New Password
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'New Password',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF333333)),
                  decoration: const InputDecoration(
                    hintText: 'Enter new password',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _obscureNew = !_obscureNew),
                child: Icon(
                  _obscureNew
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Password strength
        _buildPasswordStrength(),
        const SizedBox(height: 10),

        // Confirm Password
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Confirm Password',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF333333)),
                  decoration: const InputDecoration(
                    hintText: 'Confirm new password',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                child: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (auth.errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 12, color: AppColors.danger),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  auth.errorMessage!,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.danger),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        PrimaryButton(
          text: 'Reset Password \u2192',
          isLoading: auth.isLoading,
          onPressed: () async {
            final success = await auth.resetPassword(
              _newPasswordController.text,
              _confirmPasswordController.text,
            );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset successful! Please login.'),
                  backgroundColor: AppColors.success,
                ),
              );
              GoRouter.of(context).go('/login');
            }
          },
        ),
      ],
    );
  }

  Widget _buildPasswordStrength() {
    final password = _newPasswordController.text;
    int strength = 0;
    String label = '';
    Color labelColor = AppColors.border;

    if (password.isNotEmpty) {
      strength++;
      if (password.length >= 8) strength++;
      if (RegExp(r'[A-Z]').hasMatch(password) &&
          RegExp(r'[0-9]').hasMatch(password)) {
        strength++;
      }
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    }

    switch (strength) {
      case 0:
        label = '';
        break;
      case 1:
        label = 'Weak';
        labelColor = AppColors.danger;
        break;
      case 2:
        label = 'Fair strength';
        labelColor = AppColors.warning;
        break;
      case 3:
        label = 'Good';
        labelColor = AppColors.secondary;
        break;
      case 4:
        label = 'Strong';
        labelColor = AppColors.success;
        break;
    }

    final colors = [
      strength >= 1 ? AppColors.danger : AppColors.border,
      strength >= 2 ? AppColors.warning : AppColors.border,
      strength >= 3 ? AppColors.secondary : AppColors.border,
      strength >= 4 ? AppColors.success : AppColors.border,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: colors
              .map((c) => Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ))
              .toList(),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: labelColor),
          ),
        ],
      ],
    );
  }
}
