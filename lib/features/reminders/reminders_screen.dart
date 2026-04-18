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
                  // ── Live reminders from API ──
                  Consumer<RemindersProvider>(
                    builder: (_, p, _) {
                      if (p.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (p.reminders.isEmpty) {
                        return const _EmptyRemindersState();
                      }
                      final activeCount =
                          p.reminders.where((r) => r.isActive).length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Your Reminders',
                                  style: AppTypography.headlineSm.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text('$activeCount Active',
                                  style: AppTypography.labelMd.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.base),
                          ...p.reminders.map((r) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _LiveReminderTile(
                                  reminder: r,
                                  onToggle: () => p.toggleActive(r.id),
                                  onDelete: () => p.deleteReminder(r.id),
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
      actions: const [],
    );
  }
}

class _EmptyRemindersState extends StatelessWidget {
  const _EmptyRemindersState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl8),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medication_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('No reminders yet',
              style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Add medication reminders to stay\non top of your wellness schedule.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.addReminder),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add first reminder'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
