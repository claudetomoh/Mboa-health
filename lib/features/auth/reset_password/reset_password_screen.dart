import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/security/security.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/ambient_blob.dart';
import '../../../shared/widgets/gradient_button.dart';

// =============================================================================
// MBOA HEALTH — Reset Password Screen
// User enters the 6-digit OTP received by email, then chooses a new password.
// The new password is pre-hashed client-side before sending (OWASP A02).
// =============================================================================

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // 6 individual digit controllers for the OTP input
  final List<TextEditingController> _digitCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _digitFocus = List.generate(6, (_) => FocusNode());

  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _loading         = false;
  String? _error;
  String? _email;

  PasswordStrength _passwordStrength = PasswordStrength.empty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    for (final c in _digitCtrl) { c.dispose(); }
    for (final f in _digitFocus) { f.dispose(); }
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _otpCode => _digitCtrl.map((c) => c.text).join();

  Future<void> _submit() async {
    setState(() => _error = null);

    final code = _otpCode;
    if (code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits of your reset code.');
      return;
    }

    final pw = _passwordCtrl.text;
    if (pw.isEmpty) {
      setState(() => _error = 'Please enter a new password.');
      return;
    }
    final pwError = AppValidators.validateNewPassword(pw);
    if (pwError != null) {
      setState(() => _error = pwError);
      return;
    }
    if (pw != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (_email == null) {
      setState(() => _error = 'Session error. Please start over.');
      return;
    }

    setState(() => _loading = true);

    // A02: client-side SHA-256 pre-hash — raw password never leaves device
    final salt         = PasswordHasher.generateSalt();
    final passwordHash = PasswordHasher.hashPassword(pw, salt);

    final error = await context.read<AuthProvider>().resetPassword(
      email:           _email!,
      token:           code,
      newPasswordHash: passwordHash,
      newSalt:         salt,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    // Success — go to login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password reset successfully! Please log in.',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _digitFocus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _digitFocus[index - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientBlob(
            color: AppColors.secondaryContainer,
            size: 380,
            sigma: 70,
            alignment: Alignment.topLeft,
            offset: Offset(-100, -100),
          ),
          const AmbientBlob(
            color: AppColors.primaryFixed,
            opacity: 0.20,
            size: 280,
            alignment: Alignment.bottomRight,
            offset: Offset(60, 40),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl2),

                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.onSurface,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.base),

                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withAlpha(80),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Check Your Email',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    _email != null
                        ? 'We sent a 6-digit code to\n$_email'
                        : 'We sent a 6-digit code to your email.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl3),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withAlpha(204),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXxxl),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 40,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.outlineVariant.withAlpha(26),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error banner
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.base,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEB),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                  color: const Color(0xFFE57373)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFD32F2F), size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                        ],

                        // ── OTP digit boxes ───────────────────────────────
                        Text(
                          'Reset Code',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (i) => _OtpBox(
                            controller: _digitCtrl[i],
                            focusNode:  _digitFocus[i],
                            onChanged:  (v) => _onDigitChanged(v, i),
                          )),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // ── New password ──────────────────────────────────
                        Text(
                          'New Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PasswordField(
                          controller: _passwordCtrl,
                          hint: 'Min 8 chars, uppercase, number, symbol',
                          obscure: _obscurePassword,
                          onToggleObscure: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          onChanged: (v) => setState(() =>
                              _passwordStrength =
                                  PasswordStrengthChecker.evaluate(v)),
                          textInputAction: TextInputAction.next,
                        ),

                        if (_passwordCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _StrengthBar(strength: _passwordStrength),
                        ],

                        const SizedBox(height: AppSpacing.base),

                        // ── Confirm password ──────────────────────────────
                        Text(
                          'Confirm New Password',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _PasswordField(
                          controller: _confirmCtrl,
                          hint: 'Re-enter your new password',
                          obscure: _obscureConfirm,
                          onToggleObscure: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        GradientButton(
                          label: 'Reset Password',
                          onPressed: _submit,
                          icon: Icons.check_circle_outline_rounded,
                          loading: _loading,
                        ),

                        const SizedBox(height: AppSpacing.base),

                        // Resend link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Didn\'t receive a code? Go back',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
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
}

// ─── OTP single-digit box ─────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: controller,
        focusNode:  focusNode,
        textAlign:  TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: filled
              ? AppColors.primaryContainer.withAlpha(60)
              : AppColors.surfaceContainerHigh,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: filled ? AppColors.primary : AppColors.outline,
              width: filled ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: filled ? AppColors.primary : AppColors.outlineVariant,
              width: filled ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── Password text field ──────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggleObscure,
    required this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  final TextEditingController   controller;
  final String                  hint;
  final bool                    obscure;
  final VoidCallback            onToggleObscure;
  final ValueChanged<String>    onChanged;
  final TextInputAction         textInputAction;
  final ValueChanged<String>?   onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.onSurfaceVariant.withAlpha(120),
        ),
        prefixIcon: const Icon(Icons.lock_outline_rounded,
            color: AppColors.onSurfaceVariant, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          onPressed: onToggleObscure,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

// ─── Password strength bar ────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});

  final PasswordStrength strength;

  static const _labels = {
    PasswordStrength.empty:  '',
    PasswordStrength.weak:   'Weak',
    PasswordStrength.fair:   'Fair',
    PasswordStrength.good:   'Good',
    PasswordStrength.strong: 'Strong',
  };

  static const _colors = {
    PasswordStrength.empty:  Colors.transparent,
    PasswordStrength.weak:   Color(0xFFD32F2F),
    PasswordStrength.fair:   Color(0xFFFF8F00),
    PasswordStrength.good:   Color(0xFF43A047),
    PasswordStrength.strong: Color(0xFF00692B),
  };

  static const _steps = {
    PasswordStrength.empty:  0,
    PasswordStrength.weak:   1,
    PasswordStrength.fair:   2,
    PasswordStrength.good:   3,
    PasswordStrength.strong: 4,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[strength]!;
    final steps = _steps[strength]!;
    final label = _labels[strength]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: i < steps ? color : AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
