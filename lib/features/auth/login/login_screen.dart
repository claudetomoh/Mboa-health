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

/// Login Screen — Phase 3.
/// Pixel-matches the HTML design: brand header, form card,
/// "or continue with" divider, social buttons, footer.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  // OWASP A07 – brute-force / credential-stuffing protection.
  final _rateLimiter = RateLimiter();
  String? _securityError; // Surface lockout / generic auth errors.

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// OWASP A07 – authentication with rate-limiting and generic error messages.
  void _submit() {
    setState(() => _securityError = null);

    final email = _emailCtrl.text.trim().toLowerCase();
    if (_rateLimiter.isLockedOut(email)) {
      final remaining = _rateLimiter.remainingLockout(email);
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      final timeMsg = mins > 0
          ? '$mins min${mins == 1 ? '' : 's'}'
          : '$secs sec${secs == 1 ? '' : 's'}';
      setState(() => _securityError = 'Too many failed attempts. Try again in $timeMsg.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    _loginWithApi(email);
  }

  Future<void> _loginWithApi(String email) async {
    final authProvider = context.read<AuthProvider>();

    // Step 1: fetch the stored salt for this email (OWASP A02)
    final salt = await authProvider.fetchSalt(email);
    if (!mounted) return;

    if (salt == null) {
      setState(() {
        _loading = false;
        _securityError = 'Unable to reach the server. Check your connection.';
      });
      return;
    }

    // Step 2: client-side SHA-256 pre-hash — raw password never leaves device
    final passwordHash = PasswordHasher.hashPassword(_passwordCtrl.text, salt);

    // Step 3: authenticate against the API
    final error = await authProvider.login(
      email: email,
      passwordHash: passwordHash,
    );
    if (!mounted) return;

    if (error == null) {
      _rateLimiter.recordSuccess(email);
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else {
      final remaining = _rateLimiter.recordFailure(email);
      setState(() {
        _loading = false;
        _securityError = remaining > 0
            ? '$error $remaining attempt${remaining == 1 ? '' : 's'} remaining before lockout.'
            : 'Too many failed attempts. Account temporarily locked.';
      });
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
                    const SizedBox(height: AppSpacing.xl3),

                    // ── Brand header ───────────────────────────────────────
                    _BrandHeader(),
                    const SizedBox(height: AppSpacing.xl3),

                    // ── Form card ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest
                            .withAlpha(204), // 80%
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXxxl),
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
                          // ── Security error banner (lockout / bad creds) ──────
                          if (_securityError != null) ...[              
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEB),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd),
                                border: Border.all(
                                    color: const Color(0xFFE57373)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_clock_rounded,
                                      color: Color(0xFFD32F2F), size: 16),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      _securityError!,
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

                          // Email — RFC 5322 validated (OWASP A07 / A03)
                          AppInputField(
                            label: 'Email Address',
                            hint: 'name@example.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            // A03: reject injection patterns in the email field
                            validator: AppValidators.validateEmail,
                          ),
                          const SizedBox(height: AppSpacing.base),

                          // Password — login uses presence-only check (OWASP A07:
                          // never reveal policy details that aid enumeration)
                          AppInputField(
                            label: 'Password',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            controller: _passwordCtrl,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _submit(),
                            suffixIcon: _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            onSuffixTap: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: AppValidators.validateLoginPassword,
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(
                                  context, AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs,
                                  vertical: AppSpacing.xs,
                                ),
                              ),
                              child: Text(
                                'Forgot?',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Login button
                          GradientButton(
                            label: 'Login',
                            onPressed: _submit,
                            icon: Icons.arrow_forward_rounded,
                            loading: _loading,
                          ),

                          const SizedBox(height: AppSpacing.xl2),

                          // Divider
                          _OrDivider(),

                          const SizedBox(height: AppSpacing.xl2),

                          // Social row
                          Row(
                            children: [
                              Expanded(
                                child: _SocialButton(
                                  label: 'Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                        content: Text('Sign in with Google coming soon.'),
                                      )),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.base),
                              Expanded(
                                child: _SocialButton(
                                  label: 'Apple',
                                  icon: Icons.apple_rounded,
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                        content: Text('Sign in with Apple coming soon.'),
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl3),

                    // Sign up link
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurfaceVariant,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.signUp),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.secondary,
                                    decoration:
                                        TextDecoration.underline,
                                    decorationColor: AppColors.secondary,
                                    decorationThickness: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl3),

                    // Footer
                    Center(
                      child: Text(
                        '© 2026 MBOA HEALTH SERVICES  •  ALL DATA ENCRYPTED',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color:
                              AppColors.outline.withAlpha(153), // 60%
                        ),
                        textAlign: TextAlign.center,
                      ),
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
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(26),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: Colors.white,
            size: AppSpacing.iconXl,
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Mboa Health',
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Welcome back to your clinical sanctuary',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: Color(0x4DC0C9BB), // outlineVariant 30%
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(
            'OR CONTINUE WITH',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.outline,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: Color(0x4DC0C9BB),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.onSurface),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
