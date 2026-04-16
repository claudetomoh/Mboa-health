import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/security/security.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/ambient_blob.dart';
import '../../../shared/widgets/app_input_field.dart';
import '../../../shared/widgets/gradient_button.dart';

/// Sign Up Screen — Phase 3.
/// Single-column mobile form: Full Name, Email, Phone, Password,
/// Terms checkbox, Create Account button, Sign In link.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController(); // OWASP A07
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _loading = false;

  // OWASP A07 – live password strength tracking.
  PasswordStrength _passwordStrength = PasswordStrength.empty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// OWASP A07 – strong password policy + client-side pre-hash before transmission.
  /// OWASP A03 – sanitize all free-text inputs before processing.
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must accept the Terms of Service and Privacy Policy to create an account.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    _registerWithApi();
  }

  Future<void> _registerWithApi() async {
    // A03: sanitize inputs before transmission
    final safeName  = InputSanitizer.sanitize(_nameCtrl.text.trim());
    final safeEmail = _emailCtrl.text.trim().toLowerCase();
    final safePhone = _phoneCtrl.text.trim();

    // A02: client-side SHA-256 pre-hash — raw password never leaves device
    final salt         = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(_passwordCtrl.text, salt);

    final error = await context.read<AuthProvider>().register(
      name:         safeName,
      email:        safeEmail,
      phone:        safePhone,
      passwordHash: passwordHash,
      salt:         salt,
    );
    if (!mounted) return;

    setState(() => _loading = false);
    if (error == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.inter(fontSize: 13)),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient blobs
          const AmbientBlob(
            color: AppColors.secondaryContainer,
            opacity: 0.15,
            size: 340,
            sigma: 65,
            offset: Offset(80, -80),
          ),
          const AmbientBlob(
            color: AppColors.primaryContainer,
            opacity: 0.08,
            sigma: 55,
            alignment: Alignment.bottomLeft,
            offset: Offset(-60, 60),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl2,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mobile brand header row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.primary,
                          onPressed: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Mboa Health',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl3),

                    // Page title
                    Text(
                      'Create Account',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Step into the future of healthcare management.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl3),

                    // ── Form fields ────────────────────────────────────────
                    AppInputField(
                      label: 'Full Name',
                      hint: 'Dr. John Doe',
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _nameCtrl,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      // A03: rejects HTML, special chars, digits.
                      autofillHints: const [AutofillHints.name],
                      validator: AppValidators.validateFullName,
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Email — A07: RFC 5322 regex + A03: injection check.
                    AppInputField(
                      label: 'Email Address',
                      hint: 'john@mboahealth.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: AppValidators.validateEmail,
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Phone — A07: Cameroon-format validation.
                    AppInputField(
                      label: 'Phone Number',
                      hint: '+237 600 000 000',
                      prefixIcon: Icons.call_outlined,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      validator: AppValidators.validatePhone,
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // Password — A07: full complexity policy.
                    AppInputField(
                      label: 'Password',
                      hint: '••••••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      controller: _passwordCtrl,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      onSuffixTap: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                      onChanged: (v) => setState(() {
                        _passwordStrength =
                            PasswordStrengthChecker.evaluate(v);
                      }),
                      validator: AppValidators.validateNewPassword,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // ── Password strength meter (OWASP A07) ───────────────
                    _PasswordStrengthBar(strength: _passwordStrength),
                    const SizedBox(height: AppSpacing.base),

                    // Confirm Password — A07: mismatch check prevents typos.
                    AppInputField(
                      label: 'Confirm Password',
                      hint: '••••••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      controller: _confirmPasswordCtrl,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onSubmitted: (_) => _submit(),
                      suffixIcon: _obscureConfirm
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      onSuffixTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) => AppValidators.validateConfirmPassword(
                          v, _passwordCtrl.text),
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // ── Terms checkbox ─────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _termsAccepted,
                            onChanged: (v) => setState(
                                () => _termsAccepted = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm),
                            ),
                            side: const BorderSide(
                              color: AppColors.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),

                    // ── Primary CTA ────────────────────────────────────────
                    GradientButton(
                      label: 'Create Account',
                      onPressed: _submit,
                      loading: _loading,
                    ),

                    const SizedBox(height: AppSpacing.xl3),

                    // Sign in link
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Already have an account? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.login),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl4),

                    // Trust badges divider row
                    const Divider(
                        color: AppColors.surfaceContainer, thickness: 1),
                    const SizedBox(height: AppSpacing.base),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TrustBadge(
                            icon: Icons.verified_rounded,
                            label: 'GDPR Compliant'),
                        SizedBox(width: AppSpacing.xl2),
                        _TrustBadge(
                            icon: Icons.lock_rounded,
                            label: 'End-to-End Encrypted'),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password strength bar  (OWASP A07)
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar({required this.strength});
  final PasswordStrength strength;

  static const _colors = {
    PasswordStrength.empty: Color(0xFFE0E0E0),
    PasswordStrength.weak: Color(0xFFEF5350),
    PasswordStrength.fair: Color(0xFFFF9800),
    PasswordStrength.good: Color(0xFF42A5F5),
    PasswordStrength.strong: Color(0xFF66BB6A),
  };

  static const _fills = {
    PasswordStrength.empty: 0.0,
    PasswordStrength.weak: 0.25,
    PasswordStrength.fair: 0.50,
    PasswordStrength.good: 0.75,
    PasswordStrength.strong: 1.0,
  };

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();
    final color = _colors[strength]!;
    final fill = _fills[strength]!;
    final label = PasswordStrengthChecker.label(strength);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 4,
            backgroundColor: const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $label',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trust badge chip
// ─────────────────────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.outline.withAlpha(120)),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.outline.withAlpha(120),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
