import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/clinic_model.dart';
import '../clinic_locator/clinic_details/clinic_details_screen.dart';
import 'providers/clinic_locator_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Clinic Locator Screen
// Design ref: clinic_locator/code.html
// ─────────────────────────────────────────────────────────────────────────────

class ClinicLocatorScreen extends StatefulWidget {
  const ClinicLocatorScreen({super.key});

  @override
  State<ClinicLocatorScreen> createState() => _ClinicLocatorScreenState();
}

class _ClinicLocatorScreenState extends State<ClinicLocatorScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicLocatorProvider>().fetchClinics();
    });
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context
            .read<ClinicLocatorProvider>()
            .fetchClinics(query: _searchCtrl.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            Column(
              children: [
                // App Bar
                _AppBar(),
                // Map
                _MapPlaceholder(searchCtrl: _searchCtrl),
                // Clinic list panel
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusXxxl),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Handle
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.base),
                          child: Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Consumer<ClinicLocatorProvider>(
                            builder: (_, provider, _) {
                              if (provider.isLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                );
                              }
                              if (provider.error != null) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            AppSpacing.screenHorizontal),
                                    child: Text(
                                      provider.error!,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyMd.copyWith(
                                          color: AppColors.onSurfaceVariant),
                                    ),
                                  ),
                                );
                              }
                              final clinics = provider.clinics;
                              return SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screenHorizontal,
                                  0,
                                  AppSpacing.screenHorizontal,
                                  AppSpacing.xl8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text('Nearby Locations',
                                                style: AppTypography.bodySm
                                                    .copyWith(
                                                        color: AppColors
                                                            .onSurfaceVariant,
                                                        fontWeight:
                                                            FontWeight
                                                                .w500)),
                                            Text('Clinics in Yaoundé',
                                                style: AppTypography
                                                    .headlineMd
                                                    .copyWith(
                                                        color: AppColors
                                                            .primary)),
                                          ],
                                        ),
                                        Text('${clinics.length} Found',
                                            style:
                                                AppTypography.labelMd.copyWith(
                                                    color: AppColors.secondary,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.base),
                                    if (clinics.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: AppSpacing.xl2),
                                        child: Center(
                                          child: Text(
                                            'No clinics found.',
                                            style: AppTypography.bodyMd
                                                .copyWith(
                                                    color: AppColors
                                                        .onSurfaceVariant),
                                          ),
                                        ),
                                      )
                                    else
                                      ...clinics.map(
                                        (c) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: AppSpacing.base),
                                          child: _ClinicCard(
                                            clinic: c,
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    ClinicDetailsScreen(clinic: c),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    return Container(
      color: Colors.white.withValues(alpha: 0.88),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Mboa Health',
              style: AppTypography.titleLg.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Options coming soon.')),
            ),
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.searchCtrl});
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      width: double.infinity,
      color: AppColors.surfaceContainerLow,
      child: Stack(
        children: [
          // Simulated map grid
          CustomPaint(painter: _MapGridPainter(), child: const SizedBox.expand()),
          // Floating search bar
          Positioned(
            top: AppSpacing.base,
            left: AppSpacing.base,
            right: AppSpacing.base,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: AppTypography.bodyMd,
                      decoration: InputDecoration(
                        hintText: 'Search clinics or services...',
                        hintStyle: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.tune_rounded,
                        color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
          // Map pins
          const Positioned(
            top: 90,
            left: 80,
            child: _MapPin(
                label: 'Central Clinic', primary: true),
          ),
          const Positioned(
            top: 130,
            right: 100,
            child: _MapPin(label: 'Riverside Wellness', primary: false),
          ),
          // User pin
          const Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label, required this.primary});
  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppColors.primary : AppColors.secondary;
    const onBg = Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusFull),
            boxShadow: [
              BoxShadow(
                  color: bg.withValues(alpha: 0.4), blurRadius: 8)
            ],
          ),
          child: Text(label,
              style: AppTypography.labelSm
                  .copyWith(color: onBg, letterSpacing: 0)),
        ),
        const SizedBox(height: AppSpacing.xs2),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: primary
                ? AppColors.primaryContainer
                : AppColors.secondaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6)
            ],
          ),
          child: Icon(
            primary
                ? Icons.local_hospital_rounded
                : Icons.medical_services_rounded,
            size: 14,
            color: primary
                ? AppColors.onPrimaryContainer
                : AppColors.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic, required this.onTap});
  final Clinic clinic;
  final VoidCallback onTap;

  String get _statusLabel {
    if (clinic.is24h) return 'Open 24h';
    if (clinic.hours != null && clinic.hours!.isNotEmpty) return clinic.hours!;
    return clinic.type[0].toUpperCase() + clinic.type.substring(1);
  }

  bool get _statusActive =>
      clinic.is24h || (clinic.hours?.toLowerCase().contains('open') ?? false);

  List<String> get _tags {
    if (clinic.services.isNotEmpty) return clinic.services.take(2).toList();
    return [clinic.type[0].toUpperCase() + clinic.type.substring(1)];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clinic icon placeholder
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(clinic.name,
                                style: AppTypography.titleMd.copyWith(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs2),
                            decoration: BoxDecoration(
                              color: _statusActive
                                  ? AppColors.secondaryContainer
                                      .withValues(alpha: 0.3)
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            child: Text(_statusLabel,
                                style: AppTypography.labelSm.copyWith(
                                    color: _statusActive
                                        ? AppColors.onSecondaryContainer
                                        : AppColors.onSurfaceVariant,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: AppSpacing.xs2),
                          Text(
                              clinic.rating != null
                                  ? clinic.rating!.toStringAsFixed(1)
                                  : 'N/A',
                              style: AppTypography.labelMd.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: AppSpacing.xs),
                          Text('(${clinic.city})',
                              style: AppTypography.labelSm.copyWith(
                                  letterSpacing: 0)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppColors.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.xs2),
                          Expanded(
                            child: Text(clinic.address,
                                style: AppTypography.labelSm.copyWith(
                                    letterSpacing: 0)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                ..._tags.map((t) => Padding(
                      padding:
                          const EdgeInsets.only(right: AppSpacing.xs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusSm),
                        ),
                        child: Text(t, style: AppTypography.labelSm),
                      ),
                    )),
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _statusActive
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd),
                    ),
                    child: Text('View Info',
                        style: AppTypography.labelSm.copyWith(
                            color: _statusActive
                                ? Colors.white
                                : AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
