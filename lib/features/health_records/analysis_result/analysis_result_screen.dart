import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';

// ────────────────────────────────────────────────────────────────────────────
// Analysis Result Screen
// Design ref: analysis_result/code.html
// ────────────────────────────────────────────────────────────────────────────

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _AppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal, AppSpacing.xl2,
                    AppSpacing.screenHorizontal, 160,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Result title ──────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text('ANALYSIS COMPLETE',
                            style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4)),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Text(
                          'Mild Viral Respiratory Infection',
                          style: AppTypography.displaySm.copyWith(
                              letterSpacing: -1.0)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'Based on your reported symptoms of cough, mild fever, and fatigue.',
                          style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.5)),
                      const SizedBox(height: AppSpacing.xl2),
                      // ── Suggested Action card ─────────────────────────
                      const _SuggestedActionCard(),
                      const SizedBox(height: AppSpacing.base),
                      // ── Urgency banner ────────────────────────────────
                      const _UrgencyBanner(),
                      const SizedBox(height: AppSpacing.xl2),
                      // ── Recommended clinic ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recommended Clinic',
                              style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text('Closest Match',
                              style: AppTypography.labelMd.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.base),
                      const _RecommendedClinicCard(),
                    ]),
                  ),
                ),
              ],
            ),
            // ── Sticky bottom CTA ──────────────────────────────────────
            Positioned(
              bottom: 100,
              left: AppSpacing.screenHorizontal,
              right: AppSpacing.screenHorizontal,
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.clinicLocator),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Find Nearby Clinic',
                          style: AppTypography.titleMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
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
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
      ),
      title: Text('Mboa Health',
          style: AppTypography.titleLg.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w800)),
      actions: [
        IconButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Options coming soon.')),
          ),
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _SuggestedActionCard extends StatelessWidget {
  const _SuggestedActionCard();

  static const _actions = [
    _ActionRow(
        icon: Icons.water_drop_rounded, label: 'Increase fluid intake (2.5L/day)'),
    _ActionRow(
        icon: Icons.bedtime_rounded, label: 'Minimum 8 hours of rest'),
    _ActionRow(
        icon: Icons.thermostat_rounded, label: 'Monitor temperature every 6 hours'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: AppColors.onPrimaryFixed, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Suggested Action',
                          style: AppTypography.titleMd.copyWith(
                              fontWeight: FontWeight.w700)),
                      Text('Self-care \u0026 Observation',
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              ..._actions.map((a) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ActionRowWidget(row: a),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionRow {
  const _ActionRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _ActionRowWidget extends StatelessWidget {
  const _ActionRowWidget({required this.row});
  final _ActionRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(row.icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Text(row.label,
                style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: AppColors.tertiaryContainer.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_rounded,
              color: AppColors.tertiaryContainer, size: 24),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('When to seek urgent care',
                    style: AppTypography.labelLg.copyWith(
                        color: AppColors.tertiaryContainer,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                    'If you experience shortness of breath, chest pain, or a fever exceeding 39.5\u00b0C.',
                    style: AppTypography.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedClinicCard extends StatelessWidget {
  const _RecommendedClinicCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl)),
            child: Container(
              height: 140,
              color: AppColors.surfaceContainerHigh,
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.local_hospital_rounded,
                        color: AppColors.primary, size: 48),
                  ),
                  Positioned(
                    top: AppSpacing.base,
                    left: AppSpacing.base,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(
                            AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 14),
                          const SizedBox(width: AppSpacing.xs2),
                          Text('4.9',
                              style: AppTypography.labelSm.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('La Paix Medical Center',
                              style: AppTypography.titleLg.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xs2),
                          Text('General Practice \u2022 0.8 km away',
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions_car_rounded,
                          color: AppColors.onSecondaryContainer, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.base),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Open until 8:00 PM \u2022 Next slot 2:30 PM',
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
