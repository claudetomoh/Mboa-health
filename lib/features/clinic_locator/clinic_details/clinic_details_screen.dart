import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/clinic_model.dart';

// ────────────────────────────────────────────────────────────────────────────
// Clinic Details Screen
// Design ref: clinic_details/code.html
// ────────────────────────────────────────────────────────────────────────────

class ClinicDetailsScreen extends StatelessWidget {
  final Clinic clinic;
  const ClinicDetailsScreen({super.key, required this.clinic});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero image with frosted app-bar overlay ──────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(6),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
              actions: const [],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // placeholder for clinic image
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1B5E20),
                            Color(0xFF004D40),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          color: Colors.white24, size: 120),
                    ),
                    // gradient scrim
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    // Info over image
                    Positioned(
                      left: AppSpacing.xl,
                      right: AppSpacing.xl,
                      bottom: AppSpacing.xl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: AppSpacing.xs2),
                                Text(
                                    clinic.rating != null
                                        ? '${clinic.rating!.toStringAsFixed(1)} Stars'
                                        : 'Health Clinic',
                                    style: AppTypography.labelSm.copyWith(
                                        color: Colors.white,
                                        letterSpacing: 0.3)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(clinic.name,
                              style: AppTypography.displaySm.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1)),
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: AppSpacing.xs2),
                              Text(
                                  '${clinic.address} • ${clinic.city}',
                                  style: AppTypography.bodyMd.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal, 0,
                  AppSpacing.screenHorizontal, AppSpacing.xl8,
                ),
                child: Column(
                  children: [
                    // ── Sticky action bar ──────────────────────────────────
                    _ActionsBar(
                      phone: clinic.phone,
                      latitude: clinic.latitude,
                      longitude: clinic.longitude,
                      name: clinic.name,
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    // ── Content ────────────────────────────────────────────
                    _StatusCard(is24h: clinic.is24h, hours: clinic.hours),
                    const SizedBox(height: AppSpacing.base),
                    const _EmergencyCard(),
                    const SizedBox(height: AppSpacing.base),
                    _SpecializationsCard(services: clinic.services),
                    const SizedBox(height: AppSpacing.base),
                    _LocationCard(
                      name: clinic.name,
                      address: clinic.address,
                      city: clinic.city,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _AboutSection(name: clinic.name, type: clinic.type),
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

class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  final String? phone;
  final double? latitude;
  final double? longitude;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: phone != null
                  ? () => launchUrl(Uri.parse('tel:$phone'))
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.call_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Call Now',
                        style: AppTypography.titleMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: () {
                final uri = (latitude != null && longitude != null)
                    ? Uri.parse('https://maps.google.com/?q=$latitude,$longitude')
                    : Uri.parse(
                        'https://maps.google.com/?q=${Uri.encodeQueryComponent(name)}');
                launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_rounded,
                        color: AppColors.onSurface, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Navigate',
                        style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w700)),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.is24h, this.hours});

  final bool is24h;
  final String? hours;

  @override
  Widget build(BuildContext context) {
    final statusLabel =
        is24h ? 'Open 24/7' : (hours ?? 'See clinic for hours');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(Icons.schedule_rounded,
                    color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATUS',
                        style: AppTypography.labelSm.copyWith(
                            letterSpacing: 1.5)),
                    Text(statusLabel,
                        style: AppTypography.titleMd.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          const _HoursRow(day: 'Mon \u2013 Fri', time: '08:00 \u2013 20:00'),
          const SizedBox(height: AppSpacing.sm),
          const _HoursRow(day: 'Saturday', time: '09:00 \u2013 16:00'),
          const SizedBox(height: AppSpacing.sm),
          const _HoursRow(day: 'Sunday', time: 'Closed'),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  const _HoursRow({required this.day, required this.time});
  final String day, time;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day,
            style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant)),
        Text(time,
            style: AppTypography.bodyMd.copyWith(
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            bottom: -8,
            child: Opacity(
              opacity: 0.10,
              child: Icon(Icons.emergency_rounded,
                  color: Colors.white, size: 100),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EMERGENCY SERVICE',
                  style: AppTypography.labelSm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.xs),
              Text('24/7 Response\nAvailable',
                  style: AppTypography.headlineSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.base),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyPortal),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.medical_services_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Request Ambulance',
                          style: AppTypography.labelMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecializationsCard extends StatelessWidget {
  const _SpecializationsCard({required this.services});

  final List<String> services;

  static const _defaultSpecs = [
    _Spec(icon: Icons.monitor_heart_rounded, label: 'Cardiology'),
    _Spec(icon: Icons.child_care_rounded, label: 'Pediatrics'),
    _Spec(icon: Icons.psychology_rounded, label: 'Neurology'),
    _Spec(icon: Icons.visibility_rounded, label: 'Eye Care'),
    _Spec(icon: Icons.sentiment_satisfied_alt_rounded, label: 'Dental'),
    _Spec(icon: Icons.more_horiz_rounded, label: 'View All'),
  ];

  @override
  Widget build(BuildContext context) {
    final specs = services.isNotEmpty
        ? services
            .take(6)
            .map((s) => _Spec(icon: Icons.medical_services_rounded, label: s))
            .toList()
        : _defaultSpecs;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Medical Specializations',
              style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xl),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: specs
                .map((s) => Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(s.icon,
                              color: AppColors.primary, size: 28),
                          const SizedBox(height: AppSpacing.xs),
                          Text(s.label,
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Spec {
  const _Spec({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.name,
    required this.address,
    required this.city,
  });

  final String name;
  final String address;
  final String city;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      child: Column(
        children: [
          // Map placeholder
          Container(
            height: 140,
            color: AppColors.surfaceContainerHigh,
            child: Stack(
              children: [
                CustomPaint(
                  painter: _MapGridPainter(),
                  child: const SizedBox.expand(),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: AppSpacing.xs2),
                        Text(name,
                            style: AppTypography.labelSm.copyWith(
                                color: Colors.white,
                                letterSpacing: 0.3)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            color: AppColors.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(address,
                          style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.xs2),
                      Text(city,
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '$address, $city'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Address copied to clipboard.')),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.copy_all_rounded,
                        color: AppColors.primary, size: 18),
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.outlineVariant.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const step = 32.0;
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

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.name, required this.type});

  final String name;
  final String type;

  @override
  Widget build(BuildContext context) {
    final typeLabel = type == 'hospital'
        ? 'hospital'
        : type == 'pharmacy'
            ? 'pharmacy'
            : 'clinic';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About $name',
              style: AppTypography.headlineSm.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.base),
          Text(
              '$name is a dedicated healthcare $typeLabel committed to '
              'providing quality medical services to the community. '
              'Our team of experienced professionals is available to '
              'assist you with your health needs.',
              style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant, height: 1.6)),
        ],
      ),
    );
  }
}
