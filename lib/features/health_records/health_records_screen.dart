import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/health_record_model.dart';
import '../../../core/routing/app_routes.dart';
import '../../../shared/widgets/gradient_button.dart';
import 'providers/health_records_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Health Records Screen
// Design ref: health_records/code.html
// ─────────────────────────────────────────────────────────────────────────────

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthRecordsProvider>().fetchRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
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
                    AppSpacing.screenHorizontal, AppSpacing.xl,
                    AppSpacing.screenHorizontal, 120,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero
                      Text('Medical Records',
                          style: AppTypography.displaySm.copyWith(
                              color: AppColors.primary, letterSpacing: -1.0)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                          'Manage your clinical history, lab results, and prescriptions in one secure sanctuary.',
                          style: AppTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: AppSpacing.xl),
                      // Search + filter
                      _SearchBar(),
                      const SizedBox(height: AppSpacing.xl),
                      // Featured card
                      const _FeaturedCard(),
                      const SizedBox(height: AppSpacing.base),
                      // Lab trends card
                      const _LabTrendsCard(),
                      const SizedBox(height: AppSpacing.base),
                      // Record grid (prescription, x-ray, vaccine)
                      const IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _RecordMiniCard(
                              iconBg: AppColors.tertiaryFixed,
                              icon: Icons.medication_rounded,
                              iconColor: AppColors.onTertiaryFixedVariant,
                              title: 'Lisinopril',
                              subtitle: 'Dr. Aris Thorne',
                              badge: 'Active Plan',
                              date: 'Sep 12, 2023',
                            )),
                            SizedBox(width: AppSpacing.md),
                            Expanded(child: _RecordMiniCard(
                              iconBg: AppColors.secondaryFixed,
                              icon: Icons.medical_services_rounded,
                              iconColor: AppColors.onSecondaryFixedVariant,
                              title: 'Chest X-Ray',
                              subtitle: 'Diagnostic Imaging',
                              badge: 'Image Ready',
                              date: 'Aug 30, 2023',
                            )),
                            SizedBox(width: AppSpacing.md),
                            Expanded(child: _RecordMiniCard(
                              iconBg: AppColors.primaryFixed,
                              icon: Icons.vaccines_rounded,
                              iconColor: AppColors.onPrimaryFixedVariant,
                              title: 'COVID-19 Boost.',
                              subtitle: 'Community Hub',
                              badge: 'Vaccinated',
                              date: 'Jul 05, 2023',
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      // Wide record tiles
                      const _RecordWideTile(
                        icon: Icons.description_rounded,
                        title: 'Annual Wellness Blood Panel',
                        subtitle: 'Summary of metabolic and lipid profiles',
                        status: 'Archived',
                        statusColor: AppColors.secondary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const _RecordWideTile(
                        icon: Icons.medical_information_rounded,
                        title: 'General Consultation Notes',
                        subtitle: 'Follow-up on lifestyle adjustments',
                        status: 'Verified',
                        statusColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // ── Live records from API ──
                      Consumer<HealthRecordsProvider>(
                        builder: (_, p, _) {
                          if (p.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xl),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (p.records.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your Records',
                                  style: AppTypography.headlineSm.copyWith(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: AppSpacing.md),
                              ...p.records.map((r) => Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppSpacing.sm),
                                    child: _LiveRecordTile(
                                      record: r,
                                      onDelete: () => p.deleteRecord(r.id),
                                    ),
                                  )),
                            ],
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 100,
              right: AppSpacing.xl,
              child: GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.addRecord),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Add Record',
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search records, doctors, or clinics...',
              hintStyle: AppTypography.bodyMd,
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.base, vertical: AppSpacing.base),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_list_rounded,
                  color: AppColors.onSurface, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('Filters',
                  style: AppTypography.labelLg.copyWith(
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard();

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
            right: -32,
            top: -32,
            child: Container(
              width: 160,
              height: 160,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text('Recent Activity',
                        style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary, letterSpacing: 1.2)),
                  ),
                  Text('Oct 24, 2023',
                      style: AppTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              Text('Cardiology Assessment',
                  style: AppTypography.headlineMd.copyWith(
                      color: AppColors.onSurface)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Full diagnostic report from St. Elizabeth Heart Center regarding recent treadmill stress tests.',
                  style: AppTypography.bodyMd),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded,
                            color: AppColors.onSecondaryContainer, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HEALTH SCORE',
                              style: AppTypography.labelSm.copyWith(
                                  color: AppColors.outline)),
                          Text('94/100',
                              style: AppTypography.titleLg.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: GradientButton(
                      label: 'View Full Report',
                      icon: Icons.visibility_rounded,
                      onPressed: () => Navigator.pushNamed(
                          context, AppRoutes.analysisResult),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabTrendsCard extends StatelessWidget {
  const _LabTrendsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text('Lab Trends',
                  style: AppTypography.titleMd.copyWith(
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          const _LabRow(label: 'Glucose (Fasting)', value: '88 mg/dL',
              progress: 0.75, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          const _LabRow(label: 'Hemoglobin', value: '14.2 g/dL',
              progress: 0.80, color: AppColors.secondary),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detailed lab trends coming soon.')),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('See historical trends',
                    style: AppTypography.labelMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: AppSpacing.xs2),
                const Icon(Icons.trending_up_rounded,
                    color: AppColors.primary, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });
  final String label, value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
            Text(value, style: AppTypography.titleSm.copyWith(
                fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecordMiniCard extends StatelessWidget {
  const _RecordMiniCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.date,
  });
  final Color iconBg, iconColor;
  final IconData icon;
  final String title, subtitle, badge, date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 4),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const Icon(Icons.more_horiz_rounded,
                  color: AppColors.outline, size: 18),
            ],
          ),
          const Spacer(),
          Text(title,
              style:
                  AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.xs2),
          Text(subtitle,
              style: AppTypography.labelSm.copyWith(letterSpacing: 0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(badge,
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.outline, letterSpacing: 0.4)),
              Text(date,
                  style: AppTypography.labelSm.copyWith(letterSpacing: 0),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordWideTile extends StatelessWidget {
  const _RecordWideTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
  });
  final IconData icon;
  final String title, subtitle, status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(subtitle, style: AppTypography.labelSm),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('STATUS',
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.outline, letterSpacing: 1.0)),
              const SizedBox(height: AppSpacing.xs2),
              Text(status,
                  style: AppTypography.labelMd.copyWith(
                      color: statusColor, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Record Tile (from API)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveRecordTile extends StatelessWidget {
  const _LiveRecordTile({required this.record, required this.onDelete});
  final HealthRecord record;
  final VoidCallback onDelete;

  IconData get _icon {
    switch (record.type) {
      case 'prescription':
        return Icons.medication_rounded;
      case 'lab_result':
        return Icons.biotech_rounded;
      case 'x_ray':
        return Icons.medical_services_rounded;
      case 'vaccination':
        return Icons.vaccines_rounded;
      case 'consultation':
        return Icons.medical_information_rounded;
      case 'surgery':
        return Icons.local_hospital_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(_icon, color: AppColors.onPrimaryFixedVariant, size: 26),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.title,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  [record.doctor, record.facility]
                      .whereType<String>()
                      .join(' \u2022 '),
                  style: AppTypography.labelSm,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(record.date,
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.outline)),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.tertiary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
