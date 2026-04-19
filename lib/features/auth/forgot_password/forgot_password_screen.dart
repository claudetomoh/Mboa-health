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

// =============================================================================
// MBOA HEALTH — Forgot Password Screen
// User enters their registered email.  The backend sends a 6-digit OTP.
// On success the user is pushed to ResetPasswordScreen to enter the code
// and choose a new password.
// =============================================================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool  _loading   = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _error = null; });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim().toLowerCase();
    final error = await context.read<AuthProvider>().forgotPassword(email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    // Navigate to reset screen — pass email so it's pre-filled
    Navigator.pushNamed(
      context,
      AppRoutes.resetPassword,
      arguments: email,
    );
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
              child: Form(
                key: _formKey,
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
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    Text(
                      'Forgot Password?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Enter the email address linked to your account and\nwe\'ll send you a 6-digit reset code.',
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
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(color: const Color(0xFFE57373)),
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

                          AppInputField(
                            label: 'Email Address',
                            hint: 'name@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.email],
                            validator: AppValidators.validateEmail,
                            onSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          GradientButton(
                            label: 'Send Reset Code',
                            onPressed: _submit,
                            icon: Icons.send_rounded,
                            loading: _loading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl2),

                    // Back to login
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text.rich(
                          TextSpan(
                            text: 'Remember your password? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.onSurfaceVariant,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log in',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
