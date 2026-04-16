import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Emergency Portal Screen
// Design ref: emergency_portal/code.html
// ─────────────────────────────────────────────────────────────────────────────

class EmergencyPortalScreen extends StatefulWidget {
  const EmergencyPortalScreen({super.key});

  @override
  State<EmergencyPortalScreen> createState() =>
      _EmergencyPortalScreenState();
}

class _EmergencyPortalScreenState extends State<EmergencyPortalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot dial $number on this device.')),
        );
      }
    }
  }

  Future<void> _sendSms(String number) async {
    final uri = Uri(scheme: 'sms', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot send SMS to $number on this device.')),
        );
      }
    }
  }

  Future<void> _showAlertContacts() async {
    // Fetch emergency contacts for the current user from the API.
    final result =
        await ApiClient.instance.get(ApiConfig.emergencyContacts);

    if (!mounted) return;

    List<Map<String, dynamic>> contacts = [];
    if (result is ApiSuccess<Map<String, dynamic>>) {
      final raw = result.data['contacts'] as List<dynamic>? ?? [];
      contacts = raw.cast<Map<String, dynamic>>();
    }

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxxl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emergency Contacts',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.base),
              if (contacts.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      'No emergency contacts saved.\nGo to Profile → Emergency Contacts to add them.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                )
              else
                ...contacts.map((c) {
                  final name  = c['full_name']  as String? ?? 'Unknown';
                  final phone = c['phone'] as String? ?? '';
                  final rel   = c['relationship'] as String? ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.secondaryContainer,
                      child: Icon(Icons.person_rounded,
                          color: AppColors.onSecondaryContainer),
                    ),
                    title: Text(name,
                        style: AppTypography.titleMd
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('$rel • $phone',
                        style: AppTypography.bodySm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sms_rounded,
                              color: AppColors.primary),
                          tooltip: 'Send SMS',
                          onPressed: phone.isNotEmpty
                              ? () {
                                  Navigator.pop(ctx);
                                  _sendSms(phone);
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.call_rounded,
                              color: AppColors.primary),
                          tooltip: 'Call',
                          onPressed: phone.isNotEmpty
                              ? () {
                                  Navigator.pop(ctx);
                                  _callNumber(phone);
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _AppBar(),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal, AppSpacing.xl,
                  AppSpacing.screenHorizontal, AppSpacing.xl8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Context
                    Text('Need Immediate Help?',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineLg),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Press and hold the button for 2 seconds',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMd),
                    const SizedBox(height: AppSpacing.xl2),
                    // SOS Button with pulse
                    _SosButton(
                      pulseCtrl: _pulseCtrl,
                      onLongPress: () => _callNumber('15'),
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    // Action grid
                    Row(
                      children: [
                        Expanded(
                            child: _ActionTile(
                          icon: Icons.call_rounded,
                          label: 'Call Ambulance',
                          onTap: () => _callNumber('15'),
                        )),
                        const SizedBox(width: AppSpacing.base),
                        Expanded(
                            child: _ActionTile(
                          icon: Icons.sms_rounded,
                          label: 'Alert Contacts',
                          onTap: _showAlertContacts,
                        )),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    // First-aid guides
                    const _FirstAidSection(),
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

class _SosButton extends StatelessWidget {
  const _SosButton({required this.pulseCtrl, required this.onLongPress});
  final AnimationController pulseCtrl;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + pulseCtrl.value * 0.25,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer
                    .withValues(alpha: 0.2 * (1 - pulseCtrl.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            onLongPress();
          },
          child: Container(
            width: 192,
            height: 192,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.tertiaryContainer, AppColors.tertiary],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emergency_rounded,
                    color: Colors.white, size: 72),
                const SizedBox(height: AppSpacing.sm),
                Text('SOS',
                    style: AppTypography.headlineLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl),
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
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: AppColors.onSecondaryContainer, size: 22),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FirstAidSection extends StatelessWidget {
  const _FirstAidSection();

  static const _guides = [
    _Guide(
      icon: Icons.air_rounded,
      title: 'CPR Steps',
      body:
          'Push hard and fast in the center of the chest at 100-120 bpm.',
    ),
    _Guide(
      icon: Icons.water_drop_rounded,
      title: 'Severe Bleeding',
      body:
          'Apply direct pressure to the wound with a clean cloth or bandage.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('First-Aid Guides',
                style: AppTypography.headlineSm.copyWith(
                    fontWeight: FontWeight.w700)),
            Text('View all',
                style: AppTypography.labelMd.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: _guides
              .map((g) => Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: g == _guides.last ? 0 : AppSpacing.md),
                      child: _GuideCard(guide: g),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.medical_information_rounded,
                    color: AppColors.tertiary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your Medical ID',
                        style: AppTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppSpacing.xs2),
                    Text(
                        'Blood Type: O+ \u2022 Allergies: Penicillin \u2022 ICE: Jane Doe (0712-345-678)',
                        style: AppTypography.bodySm.copyWith(
                            color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Guide {
  const _Guide(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});
  final _Guide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 4),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4)
              ],
            ),
            child: Icon(guide.icon, color: AppColors.tertiary, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(guide.title,
              style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs2),
          Text(guide.body,
              style:
                  AppTypography.labelSm.copyWith(letterSpacing: 0, height: 1.5)),
        ],
      ),
    );
  }
}
