import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/routing/app_routes.dart';
import '../../shared/widgets/ambient_blob.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Role data model
// ─────────────────────────────────────────────────────────────────────────────

class _RoleOption {
  const _RoleOption({
    required this.title,
    required this.description,
    required this.cta,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String description;
  final String cta;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// RoleSelectionScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Role Selection Screen — Phase 3.
/// Three tappable role cards (Patient, Health Worker, Clinic Admin).
/// Tapping any card navigates to the Login screen.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const List<_RoleOption> _roles = [
    _RoleOption(
      title: 'Patient',
      description:
          'Access your medical history, book consultations, and manage your health journey in one secure place.',
      cta: 'Continue as Patient',
      icon: Icons.person_search_rounded,
      iconBg: AppColors.secondaryContainer,
      iconColor: AppColors.onSecondaryContainer,
    ),
    _RoleOption(
      title: 'Health Worker',
      description:
          'Manage patient records, schedule appointments, and provide digital care with clinical precision tools.',
      cta: 'Continue as Provider',
      icon: Icons.medical_services_rounded,
      iconBg: AppColors.primaryContainer,
      iconColor: AppColors.onPrimaryContainer,
    ),
    _RoleOption(
      title: 'Clinic Admin',
      description:
          'Oversee staff operations, analyze facility performance, and maintain organizational compliance settings.',
      cta: 'Continue as Admin',
      icon: Icons.admin_panel_settings_rounded,
      iconBg: AppColors.surfaceContainerHighest,
      iconColor: AppColors.onSurface,
    ),
  ];

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
            opacity: 0.20,
            size: 380,
            sigma: 70,
            alignment: Alignment.topLeft,
            offset: Offset(-100, -100),
          ),
          const AmbientBlob(
            color: AppColors.primaryContainer,
            size: 320,
            alignment: Alignment.bottomRight,
            offset: Offset(80, 80),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── App bar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
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
                ),

                // ── Scrollable content ────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.xl2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero heading
                        Text(
                          'Select Your Role',
                          style: GoogleFonts.manrope(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Choose the account type that best describes your interaction with Mboa Health services.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl3), // 40

                        // Role cards
                        ..._roles.map(
                          (role) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppSpacing.base),
                            child: _RoleCard(
                              role: role,
                              onTap: () => Navigator.pushNamed(
                                  context, AppRoutes.login),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xl3),

                        // Footer help
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'Need help choosing your account type? ',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.onSurfaceVariant,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final uri = Uri(
                                        scheme: 'mailto',
                                        path: 'support@mboahealth.cm',
                                        query: 'subject=Account%20Type%20Help',
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    child: Text(
                                      'Contact Support',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor:
                                            AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role card widget
// ─────────────────────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role, required this.onTap});
  final _RoleOption role;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      lowerBound: 0.97,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl2), // 32
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl + 8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: AppColors.outlineVariant.withAlpha(38), // ring-1
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: role.iconBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Icon(role.icon, color: role.iconColor, size: 28),
              ),
              const SizedBox(height: AppSpacing.xl2),

              // Title
              Text(
                role.title,
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Description
              Text(
                role.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),

              // CTA row
              Row(
                children: [
                  Text(
                    role.cta,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
