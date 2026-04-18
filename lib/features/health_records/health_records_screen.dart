import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/health_record_model.dart';
import '../../../core/routing/app_routes.dart';
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
                      // ── Records from API (or empty state) ──
                      Consumer<HealthRecordsProvider>(
                        builder: (_, p, _) {
                          if (p.isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xl2),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (p.records.isEmpty) {
                            return _EmptyRecordsState();
                          }
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyRecordsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_open_rounded,
                  size: 40, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.base),
            Text('No medical records yet',
                style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your prescriptions, lab results, X-rays, vaccinations, and consultation notes to build your personal health history.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.addRecord),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl2,
                    vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Add your first record',
                        style: AppTypography.labelLg.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
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
