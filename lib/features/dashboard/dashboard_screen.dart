import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/app_routes.dart';
import '../auth/providers/auth_provider.dart';
import '../profile/providers/profile_provider.dart';
import '../reminders/providers/reminders_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Screen
// "Clinical Sanctuary" — Bento-grid home with bottom nav.
// Design ref: home_dashboard/code.html
// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth    = context.read<AuthProvider>();
      final profile = context.read<ProfileProvider>();
      if (auth.user != null) profile.seedFromAuth(auth.user!);
      profile.fetchProfile();
      context.read<RemindersProvider>().fetchReminders();
    });
  }

  void _onNavTap(int index) {
    if (index == _selectedNav) return;
    setState(() => _selectedNav = index);
    switch (index) {
      case 1:
        Navigator.pushNamed(context, AppRoutes.healthRecords);
      case 2:
        Navigator.pushNamed(context, AppRoutes.notifications);
      case 3:
        Navigator.pushNamed(context, AppRoutes.profile);
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _DashboardAppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
                AppSpacing.screenHorizontal,
                0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _GreetingSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _HealthTipBanner(),
                  const SizedBox(height: AppSpacing.xl),
                  _BentoGrid(onNavigate: Navigator.of(context).pushNamed),
                  const SizedBox(height: AppSpacing.xl),
                  const _UpcomingSection(),
                  const SizedBox(height: 112),
                ]),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNavBar(
          selectedIndex: _selectedNav,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sliver App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      automaticallyImplyLeading: false,
      title: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs),
        child: Text(
          'Mboa Health',
          style: AppTypography.titleLg.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined, color: AppColors.primary),
          tooltip: 'Notifications',
        ),
        IconButton(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.profile),
          icon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
          tooltip: 'Profile',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Section
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Consumer<AuthProvider>(
                builder: (_, auth, _) => Text(
                  'Hello, ${auth.user?.firstName ?? 'there'} 👋',
                  style: AppTypography.displaySm.copyWith(
                    color: AppColors.onSurface,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const _GreetingAvatar(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Avatar (beside greeting text, taps to pick photo / navigate to profile)
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingAvatar extends StatefulWidget {
  const _GreetingAvatar();

  @override
  State<_GreetingAvatar> createState() => _GreetingAvatarState();
}

class _GreetingAvatarState extends State<_GreetingAvatar> {
  Future<void> _pickAndUpload() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    final err = await context.read<ProfileProvider>().uploadAvatar(picked);
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProfileProvider>();
    return GestureDetector(
      onTap: p.avatarUploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceContainerHigh,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                )
              ],
            ),
            child: ClipOval(
              child: p.avatarUploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    )
                  : p.avatarPreviewBytes != null
                      ? Image.memory(p.avatarPreviewBytes!, fit: BoxFit.cover)
                      : p.user?.avatarUrl != null
                          ? Image.network(
                              p.user!.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person_rounded,
                                color: AppColors.onSurfaceVariant,
                                size: 36,
                              ),
                            )
                          : const Icon(
                              Icons.person_rounded,
                              color: AppColors.onSurfaceVariant,
                              size: 36,
                            ),
            ),
          ),
          // Small camera badge
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Health Tip Banner
// ─────────────────────────────────────────────────────────────────────────────

class _HealthTipBanner extends StatelessWidget {
  const _HealthTipBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative background icon
          const Positioned(
            right: -16,
            bottom: -20,
            child: Opacity(
              opacity: 0.10,
              child: Icon(
                Icons.water_drop_rounded,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: AppColors.primaryFixed,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'DAILY INSIGHT',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.primaryFixed,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _DailyTip.current.title,
                style: AppTypography.titleMd.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const _TipDetailSheet(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read more',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.secondaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.secondaryFixed,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento Grid
// ─────────────────────────────────────────────────────────────────────────────

class _BentoGrid extends StatelessWidget {
  const _BentoGrid({required this.onNavigate});

  final Future<dynamic> Function(String route) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Check Symptoms | Find Clinic (2-col square cards)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SmallActionCard(
                  iconData: Icons.monitor_heart_rounded,
                  iconBgColor: AppColors.secondaryContainer.withValues(alpha: 0.3),
                  iconColor: AppColors.secondary,
                  title: 'Check Symptoms',
                  subtitle: 'AI-powered health assessment',
                  onTap: () => onNavigate(AppRoutes.symptomChecker),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _SmallActionCard(
                  iconData: Icons.map_rounded,
                  iconBgColor: AppColors.primaryFixed.withValues(alpha: 0.3),
                  iconColor: AppColors.primary,
                  title: 'Find Clinic',
                  subtitle: 'Locate specialists near you',
                  onTap: () => onNavigate(AppRoutes.clinicLocator),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Row 2: Emergency (full-width — red)
        _EmergencyCard(onTap: () => onNavigate(AppRoutes.emergencyPortal)),
        const SizedBox(height: AppSpacing.md),
        // Row 3: My Records (full-width — horizontal)
        _RecordsCard(onTap: () => onNavigate(AppRoutes.healthRecords)),
      ],
    );
  }
}

// ─── Small square action card ───────────────────────────────────────────────

class _SmallActionCard extends StatelessWidget {
  const _SmallActionCard({
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(height: AppSpacing.xl2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  subtitle,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
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

// ─── Emergency card (tertiary red) ─────────────────────────────────────────

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency',
                    style: AppTypography.headlineSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    'Immediate medical assistance',
                    style: AppTypography.bodySm.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }
}

// ─── Records list-tile card ─────────────────────────────────────────────────

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.folder_shared_rounded,
                color: AppColors.onSecondaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Records',
                    style: AppTypography.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    'Lab results & prescriptions',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.outline,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily Tip Data
// ─────────────────────────────────────────────────────────────────────────────

class _DailyTip {
  const _DailyTip({required this.title, required this.body});
  final String title;
  final String body;

  static const _tips = [
    _DailyTip(
      title: 'Stay hydrated — drink 8 glasses of water daily.',
      body: 'Water regulates body temperature, carries nutrients to cells, and flushes out waste. Starting your day with a glass of water activates your metabolism and improves alertness. Aim for 2–3 litres per day based on your activity level.',
    ),
    _DailyTip(
      title: '10 minutes of walking after meals lowers blood sugar.',
      body: 'Research shows that a short post-meal walk of 10–15 minutes significantly reduces blood glucose spikes. It improves insulin sensitivity and aids digestion. Try it after lunch for the most benefit.',
    ),
    _DailyTip(
      title: 'Quality sleep repairs your heart and blood vessels.',
      body: 'During deep sleep, your brain clears toxins, your heart rate drops, and your body repairs damaged tissue. Adults need 7–9 hours per night. Poor sleep is linked to hypertension, diabetes, and weight gain.',
    ),
    _DailyTip(
      title: 'Eat more colourful fruits and vegetables every day.',
      body: 'Different colours in produce indicate different antioxidants and phytonutrients. Red tomatoes provide lycopene for heart health; orange carrots provide beta-carotene for eyesight; leafy greens supply folate and iron. Aim for 5 portions of fruits and vegetables daily.',
    ),
    _DailyTip(
      title: 'Manage stress — it directly affects your immune system.',
      body: 'Chronic stress raises cortisol, which suppresses the immune system, increases blood pressure, and disrupts sleep. Daily mindfulness, even 5 minutes of deep breathing, activates the parasympathetic nervous system and lowers cortisol measurably.',
    ),
    _DailyTip(
      title: 'Wash your hands — the most effective disease prevention.',
      body: 'Proper handwashing for 20 seconds with soap and water removes 99% of bacteria and viruses. It prevents respiratory illnesses, gastrointestinal infections, and transmission of healthcare-associated infections. Always wash before meals and after using the toilet.',
    ),
    _DailyTip(
      title: 'Regular checkups catch health issues before symptoms appear.',
      body: 'Many serious conditions — hypertension, diabetes, cancers — are asymptomatic in early stages. Annual blood panels, blood pressure checks, and cancer screenings appropriate for your age and risk profile can identify problems when they are most treatable.',
    ),
  ];

  static _DailyTip get current {
    final dayIndex = DateTime.now().weekday - 1; // 0 = Monday
    return _tips[dayIndex % _tips.length];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tip Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TipDetailSheet extends StatelessWidget {
  const _TipDetailSheet();

  @override
  Widget build(BuildContext context) {
    final tip = _DailyTip.current;
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text('DAILY INSIGHT',
                style: AppTypography.labelSm.copyWith(
                    color: AppColors.onPrimaryContainer,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(tip.title,
              style: AppTypography.headlineMd.copyWith(
                  fontWeight: FontWeight.w700, height: 1.3)),
          const SizedBox(height: AppSpacing.base),
          Text(tip.body,
              style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurfaceVariant, height: 1.6)),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl)),
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text('Got it',
                  style: AppTypography.labelLg.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Upcoming Section
// ─────────────────────────────────────────────────────────────────────────────

class _UpcomingSection extends StatelessWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<RemindersProvider>(
      builder: (context, reminders, _) {
        final upcoming = reminders.reminders
            .where((r) => r.isActive)
            .take(3)
            .toList();
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming',
                  style: AppTypography.headlineSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.reminders),
                  child: Text(
                    'View all',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (reminders.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (upcoming.isEmpty)
              _UpcomingEmptyState()
            else
              ...upcoming.map((r) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReminderItem(
                      dotColor: AppColors.secondary,
                      title: r.medicationName,
                      subtitle: r.dosage != null
                          ? '${r.dosage!} • ${r.displayTime}'
                          : r.displayTime,
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _UpcomingEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl2, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_available_rounded,
              size: 40, color: AppColors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text('No upcoming reminders',
              style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xs),
          Text('Add a medication or wellness reminder to get started.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.reminders),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text('Set a reminder',
                  style: AppTypography.labelLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderItem extends StatelessWidget {
  const _ReminderItem({
    required this.dotColor,
    required this.title,
    required this.subtitle,
  });

  final Color dotColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs2),
                Text(
                  subtitle,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
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
// Bottom Navigation Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.description_rounded, label: 'Records'),
      _NavItem(icon: Icons.notifications_rounded, label: 'Alerts'),
      _NavItem(icon: Icons.person_rounded, label: 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: active ? AppSpacing.lg : AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: AppSpacing.iconMd,
                        color: active
                            ? AppColors.primary
                            : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppSpacing.xs2),
                      Text(
                        item.label.toUpperCase(),
                        style: AppTypography.labelSm.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}
