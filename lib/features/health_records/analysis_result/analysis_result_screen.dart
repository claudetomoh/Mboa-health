import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../../symptom_checker/providers/symptom_checker_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// Analysis Result Screen — Dynamic
// Reads condition, urgency, and recommendations from SymptomCheckerProvider.
// ────────────────────────────────────────────────────────────────────────────

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<SymptomCheckerProvider>().analysis;

    if (analysis == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: Column(
              children: [
                _AppBar(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.science_outlined,
                            size: 56, color: AppColors.outline),
                        const SizedBox(height: AppSpacing.lg),
                        Text('No analysis yet',
                            style: AppTypography.titleLg
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Please select your symptoms first.',
                            style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: AppSpacing.xl2),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.symptomChecker),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Go Back'),
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                      // ── Urgency badge ──────────────────────────────────
                      _UrgencyBadge(urgency: analysis.urgency),
                      const SizedBox(height: AppSpacing.base),

                      // ── Condition headline ─────────────────────────────
                      Text(analysis.condition,
                          style: AppTypography.displaySm
                              .copyWith(letterSpacing: -1.0)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(analysis.summary,
                          style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurfaceVariant,
                              height: 1.5)),

                      // ── Matched symptoms chips ─────────────────────────
                      if (analysis.symptoms.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.base),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: analysis.symptoms
                              .map((s) => _SymptomBubble(label: s))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl2),

                      // ── Recommendations card ───────────────────────────
                      _RecommendationsCard(
                          recommendations: analysis.recommendations),
                      const SizedBox(height: AppSpacing.base),

                      // ── Urgency warning banner ─────────────────────────
                      _UrgencyWarningBanner(urgency: analysis.urgency),
                      const SizedBox(height: AppSpacing.xl2),

                      // ── Recommended clinic ─────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recommended Clinic',
                              style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text(analysis.clinicType,
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
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.clinicLocator),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                          color:
                              AppColors.primary.withValues(alpha: 0.35),
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

// ── App Bar ──────────────────────────────────────────────────────────────────

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
          onPressed: () => Navigator.pushNamed(
              context, AppRoutes.symptomChecker),
          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
          tooltip: 'Re-assess',
        ),
      ],
    );
  }
}

// ── Urgency badge ────────────────────────────────────────────────────────────

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.urgency});
  final String urgency;

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (urgency) {
      'emergency' => (
          'EMERGENCY — CALL 15 NOW',
          AppColors.error,
          AppColors.onError,
        ),
      'high' => (
          'ANALYSIS COMPLETE — HIGH URGENCY',
          AppColors.tertiaryContainer,
          Colors.white,
        ),
      'medium' => (
          'ANALYSIS COMPLETE',
          AppColors.secondaryContainer,
          AppColors.onSecondaryContainer,
        ),
      _ => (
          'ANALYSIS COMPLETE — LOW URGENCY',
          AppColors.primaryFixed,
          AppColors.onPrimaryFixed,
        ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Text(label,
            style: AppTypography.labelSm.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      ),
    );
  }
}

// ── Symptom bubble ───────────────────────────────────────────────────────────

class _SymptomBubble extends StatelessWidget {
  const _SymptomBubble({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w500)),
    );
  }
}

// ── Recommendations card ─────────────────────────────────────────────────────

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.recommendations});
  final List<String> recommendations;

  static const _icons = [
    Icons.water_drop_rounded,
    Icons.bedtime_rounded,
    Icons.thermostat_rounded,
    Icons.medication_rounded,
    Icons.local_hospital_rounded,
    Icons.phone_rounded,
    Icons.directions_walk_rounded,
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
      child: Column(
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
                  Text('Suggested Actions',
                      style: AppTypography.titleMd
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text('Self-care & Observation',
                      style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...List.generate(recommendations.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  children: [
                    Icon(_icons[i % _icons.length],
                        color: AppColors.secondary, size: 20),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Text(recommendations[i],
                          style: AppTypography.bodyMd
                              .copyWith(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Urgency warning banner ───────────────────────────────────────────────────

class _UrgencyWarningBanner extends StatelessWidget {
  const _UrgencyWarningBanner({required this.urgency});
  final String urgency;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, message) = switch (urgency) {
      'emergency' => (
          Icons.emergency_rounded,
          AppColors.error,
          'Seek emergency care immediately',
          'Call 15 now. Do not delay. This may be a life-threatening condition.',
        ),
      'high' => (
          Icons.warning_rounded,
          AppColors.tertiaryContainer,
          'Consult a doctor today',
          'Your symptoms require prompt medical evaluation — do not wait.',
        ),
      'medium' => (
          Icons.info_rounded,
          const Color(0xFFF59E0B),
          'Monitor and seek care if worsening',
          'If symptoms persist beyond 48 hours or worsen significantly, see a doctor.',
        ),
      _ => (
          Icons.check_circle_rounded,
          AppColors.secondary,
          'Low urgency — self-care advised',
          'Rest, hydrate, and monitor. Seek medical care if you don\'t improve.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelLg.copyWith(
                        color: color, fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(message,
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

// ── Recommended clinic card ──────────────────────────────────────────────────

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
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text('Open',
                          style: AppTypography.labelSm.copyWith(
                              color: AppColors.onPrimaryFixed,
                              fontWeight: FontWeight.w700)),
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
