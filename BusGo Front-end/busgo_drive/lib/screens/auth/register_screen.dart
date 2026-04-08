import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final List<String> _allAreas = [
    'Colombo',
    'Nugegoda',
    'Maharagama',
    'Homagama',
    'Kaduwela',
    'Panadura',
    'Kelaniya',
  ];
  final Set<String> _selectedAreas = {'Colombo', 'Nugegoda', 'Homagama'};

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _licenseController.dispose();
    _licenseExpiryController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  TextStyle _inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.xxl, vertical: AppDimens.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('PERSONAL INFORMATION'),
                      const SizedBox(height: 12),
                      _buildInput(
                        label: 'FULL NAME',
                        hint: 'Kamal Perera',
                        icon: Icons.person_outline,
                        controller: _nameController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      _buildInput(
                        label: 'NIC NUMBER',
                        hint: '9XXXXXXXXV',
                        icon: Icons.credit_card_outlined,
                        controller: _nicController,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'NIC is required' : null,
                      ),

                      _buildSectionLabel('LICENSE DETAILS'),
                      const SizedBox(height: 12),
                      _buildInput(
                        label: 'LICENSE NUMBER',
                        hint: 'B-XXXXXXXXX',
                        icon: Icons.badge_outlined,
                        controller: _licenseController,
                        validator: (v) => v == null || v.isEmpty
                            ? 'License number is required'
                            : null,
                      ),
                      _buildInput(
                        label: 'LICENSE EXPIRY DATE',
                        hint: 'MM / YYYY',
                        icon: Icons.calendar_today_outlined,
                        controller: _licenseExpiryController,
                        keyboardType: TextInputType.datetime,
                      ),

                      _buildSectionLabel('EXPERIENCE AREAS'),
                      const SizedBox(height: 10),
                      _buildAreaChips(),
                      const SizedBox(height: 20),

                      _buildSectionLabel('CONTACT'),
                      const SizedBox(height: 12),
                      _buildInput(
                        label: 'EMAIL ADDRESS',
                        hint: 'your@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      _buildInput(
                        label: 'PHONE NUMBER',
                        hint: '+94 7X XXX XXXX',
                        icon: Icons.phone_outlined,
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Phone is required' : null,
                      ),
                      _buildInput(
                        label: 'PASSWORD',
                        hint: 'Min. 8 characters',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Password is required';
                          }
                          if (v.length < 8) return 'Minimum 8 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 18, color: AppColors.info),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Your account will be reviewed by the admin team before activation. This process usually takes 24-48 hours.',
                                style: _inter(
                                  size: 12,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Register button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.error != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppDimens.md),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerLight,
                                  borderRadius: BorderRadius.circular(
                                      AppDimens.radiusMd),
                                  border: Border.all(
                                    color:
                                        AppColors.danger.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 18, color: AppColors.danger),
                                    const SizedBox(width: AppDimens.sm),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: _inter(
                                            size: 13,
                                            color: AppColors.danger),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return AppButton(
                            text: 'Register — Pending Approval',
                            isLoading: auth.isLoading,
                            icon: Icons.how_to_reg_rounded,
                            color: AppColors.primary,
                            onPressed: () => _handleRegister(auth),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: _inter(
                                size: 13, color: AppColors.textSecondary),
                          ),
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Sign In',
                              style: _inter(
                                size: 13,
                                weight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
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
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.arrow_back, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: _inter(
                  size: 18,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Driver Registration',
                style: _inter(
                  size: 12,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SECTION LABEL
  // ═══════════════════════════════════════════════════════
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: _inter(
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // INPUT FIELD
  // ═══════════════════════════════════════════════════════
  Widget _buildInput({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _inter(
            size: 11,
            weight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          validator: validator,
          style: _inter(size: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _inter(size: 14, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide:
                  const BorderSide(color: AppColors.danger, width: 2),
            ),
            errorStyle: _inter(size: 11, color: AppColors.danger),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // AREA CHIPS
  // ═══════════════════════════════════════════════════════
  Widget _buildAreaChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allAreas.map((area) {
        final isSelected = _selectedAreas.contains(area);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAreas.remove(area);
              } else {
                _selectedAreas.add(area);
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Text(
              area,
              style: _inter(
                size: 12,
                weight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════
  // REGISTER HANDLER
  // ═══════════════════════════════════════════════════════
  Future<void> _handleRegister(AuthProvider auth) async {
    auth.clearError();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one experience area',
              style: _inter(size: 13, color: Colors.white)),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final router = GoRouter.of(context);
    final success = await auth.register(
      name: _nameController.text.trim(),
      nic: _nicController.text.trim(),
      licenseNumber: _licenseController.text.trim(),
      licenseExpiry: _licenseExpiryController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      areas: _selectedAreas.toList(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful! Login with your email & password.',
            style: _inter(size: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
      router.go('/login');
    }
  }
}
