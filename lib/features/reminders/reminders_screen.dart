import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/reminder_model.dart';
import '../../core/routing/app_routes.dart';
import 'providers/reminders_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reminders Screen
// Design ref: reminders/code.html
// ─────────────────────────────────────────────────────────────────────────────

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _metforminTaken = false;
  bool _metforminSkipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().fetchReminders();
    });
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal, AppSpacing.xl,
                AppSpacing.screenHorizontal, 120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Hero
                  Text('Reminders', style: AppTypography.displaySm),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Manage your daily wellness schedule and clinical adherence.',
                    style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Stats bento
                  _StatsBento(),
                  const SizedBox(height: AppSpacing.xl),
                  // Upcoming header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Upcoming Today',
                          style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700)),
                      Text('4 Remaining',
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.base),
                  // Active reminder (Metformin)
                  _ActiveReminderCard(
                    icon: Icons.medication_rounded,
                    iconBg: AppColors.secondaryContainer.withValues(alpha: 0.3),
                    iconColor: AppColors.secondary,
                    name: 'Metformin',
                    desc: '500mg \u2022 After breakfast',
                    time: '08:30',
                    timeLabel: 'Morning Dose',
                    taken: _metforminTaken,
                    skipped: _metforminSkipped,
                    onTaken: () => setState(() {
                      _metforminTaken = true;
                      _metforminSkipped = false;
                    }),
                    onSkip: () => setState(() {
                      _metforminSkipped = true;
                      _metforminTaken = false;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _PendingReminderCard(
                    icon: Icons.water_drop_rounded,
                    name: 'Hydration Goal',
                    desc: '500ml Water intake',
                    time: '11:00',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _PendingReminderCard(
                    icon: Icons.monitor_heart_rounded,
                    name: 'BP Reading',
                    desc: 'Daily vitals check',
                    time: '14:00',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Tip card
                  const _TipCard(),
                  const SizedBox(height: AppSpacing.xl),
                  // ── Live reminders from API ──
                  Consumer<RemindersProvider>(
                    builder: (_, p, _) {
                      if (p.isLoading) {
                        return const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.xl),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (p.reminders.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Reminders',
                              style: AppTypography.headlineSm.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.md),
                          ...p.reminders.map((r) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _LiveReminderTile(
                                  reminder: r,
                                  onToggle: () =>
                                      p.toggleActive(r.id),
                                  onDelete: () =>
                                      p.deleteReminder(r.id),
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
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.addReminder),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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

class _StatsBento extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Completion banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -8,
                bottom: -16,
                child: Opacity(
                  opacity: 0.10,
                  child: Icon(Icons.medication_rounded,
                      color: Colors.white, size: 96),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DAILY COMPLETION',
                      style: AppTypography.labelSm.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.5)),
                  const SizedBox(height: AppSpacing.xs),
                  RichText(
                    text: TextSpan(
                      text: '85%',
                      style: AppTypography.displaySm.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800),
                      children: [
                        TextSpan(
                          text: '  of doses taken',
                          style: AppTypography.bodyLg.copyWith(
                              color: Colors.white.withValues(alpha: 0.9)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Quick action row
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.history_rounded,
                label: 'View History',
                sub: 'Past 30 days',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder history coming soon.')),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _QuickAction(
                icon: Icons.snooze_rounded,
                label: 'Snooze All',
                sub: 'Pause for 1 hour',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Snooze all coming soon.')),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
  });
  final IconData icon;
  final String label, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(label,
                style: AppTypography.labelLg.copyWith(
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs2),
            Text(sub, style: AppTypography.labelSm),
          ],
        ),
      ),
    );
  }
}

class _ActiveReminderCard extends StatelessWidget {
  const _ActiveReminderCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.name,
    required this.desc,
    required this.time,
    required this.timeLabel,
    required this.taken,
    required this.skipped,
    required this.onTaken,
    required this.onSkip,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String name, desc, time, timeLabel;
  final bool taken, skipped;
  final VoidCallback onTaken, onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: const Border(
            left: BorderSide(color: AppColors.primary, width: 4)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTypography.titleMd.copyWith(
                            fontWeight: FontWeight.w700)),
                    Text(desc, style: AppTypography.bodyMd),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time,
                      style: AppTypography.headlineSm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                  Text(timeLabel,
                      style: AppTypography.labelSm.copyWith(
                          letterSpacing: 0.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onTaken,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: taken
                          ? AppColors.secondary
                          : AppColors.primary,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      taken ? 'Taken ✓' : 'Mark as Taken',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: onSkip,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: skipped
                        ? AppColors.surfaceContainerHighest
                        : AppColors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text('Skip',
                      style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingReminderCard extends StatelessWidget {
  const _PendingReminderCard({
    required this.icon,
    required this.name,
    required this.desc,
    required this.time,
  });
  final IconData icon;
  final String name, desc, time;

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
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: AppColors.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w700)),
                Text(desc, style: AppTypography.bodyMd),
              ],
            ),
          ),
          Text(time,
              style: AppTypography.titleMd.copyWith(
                  color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded,
              color: AppColors.secondary, size: 28),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consistency is key',
                    style: AppTypography.titleMd.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    'Taking your medication at the same time every day helps maintain a steady level in your bloodstream.',
                    style: AppTypography.bodyMd.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Reminder Tile (from API)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveReminderTile extends StatelessWidget {
  const _LiveReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });
  final Reminder reminder;
  final VoidCallback onToggle, onDelete;

  @override
  Widget build(BuildContext context) {
    final bool active = reminder.isActive;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: active
            ? const Border(
                left: BorderSide(color: AppColors.primary, width: 3))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryFixed
                  : AppColors.surfaceContainerLow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_rounded,
              color: active
                  ? AppColors.onPrimaryFixedVariant
                  : AppColors.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.medicationName,
                    style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w700)),
                if (reminder.dosage != null)
                  Text(reminder.dosage!,
                      style: AppTypography.bodyMd),
              ],
            ),
          ),
          Text(reminder.displayTime,
              style: AppTypography.titleMd.copyWith(
                  color: active
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant)),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              active
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              color: active ? AppColors.primary : AppColors.outline,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.tertiary, size: 20),
          ),
        ],
      ),
    );
  }
}
