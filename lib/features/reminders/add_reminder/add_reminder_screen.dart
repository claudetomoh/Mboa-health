import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../providers/reminders_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// Add Reminder Screen
// Design ref: add_reminder/code.html
// ────────────────────────────────────────────────────────────────────────────

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleCtrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _frequency = 'Once';
  bool _saving = false;

  static const _frequencies = ['Once', 'Daily', 'Weekly', 'Custom'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  // Frequency label → backend value accepted by the API
  static const _freqMap = {
    'Once':   'as_needed',
    'Daily':  'daily',
    'Weekly': 'weekly',
    'Custom': 'daily',
  };

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder title.')),
      );
      return;
    }
    if (_time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reminder time.')),
      );
      return;
    }
    setState(() => _saving = true);
    final timeStr =
        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}:00';
    final payload = <String, dynamic>{
      'medication_name': title,
      'reminder_time':   timeStr,
      'frequency':       _freqMap[_frequency] ?? 'daily',
      if (_date != null)
        'start_date': '${_date!.year}-'
            '${_date!.month.toString().padLeft(2, '0')}-'
            '${_date!.day.toString().padLeft(2, '0')}',
    };
    final error =
        await context.read<RemindersProvider>().addReminder(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _AppBar(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal, AppSpacing.xl,
                AppSpacing.screenHorizontal, AppSpacing.xl8,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hero banner ──────────────────────────────────────
                  const _HeroBanner(),
                  const SizedBox(height: AppSpacing.xl2),
                  // ── Title Input ───────────────────────────────────────
                  const _SectionLabel(
                    icon: Icons.edit_note_rounded,
                    label: 'Reminder Title',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _titleCtrl,
                    style: AppTypography.titleMd.copyWith(
                        fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'e.g., Morning Insulin Shot',
                      hintStyle: AppTypography.titleMd.copyWith(
                          color: AppColors.outline
                              .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 0.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.lg),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // ── Date & time ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _DatePickerCard(
                          date: _date, onTap: _pickDate)),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(child: _TimePickerCard(
                          time: _time, onTap: _pickTime)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // ── Frequency ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recurring Schedule',
                            style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.base),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _frequencies
                              .map((f) => GestureDetector(
                                    onTap: () =>
                                        setState(() => _frequency = f),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xl,
                                          vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: _frequency == f
                                            ? AppColors.primary
                                            : AppColors
                                                .surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusFull),
                                      ),
                                      child: Text(f,
                                          style:
                                              AppTypography.labelMd.copyWith(
                                            color: _frequency == f
                                                ? Colors.white
                                                : AppColors.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0,
                                          )),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // ── Save button ───────────────────────────────────────
                  GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.30),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: _saving
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Save Reminder',
                                    style: AppTypography.titleLg.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                      'You will receive a notification 5 minutes before the scheduled time.',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.6),
                          letterSpacing: 0,
                          height: 1.5,
                          fontStyle: FontStyle.italic)),
                ]),
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
      title: Text('Add Reminder',
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -16,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.20,
              child: Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 96,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Never miss a dose\nor checkup.',
                  style: AppTypography.headlineMd.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                  'Set precise notifications for your medical routine in the Mboa Sanctuary.',
                  style: AppTypography.bodyMd.copyWith(
                      color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.onSurfaceVariant, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Text(label.toUpperCase(),
            style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
      ],
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({required this.date, required this.onTap});
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm + 2),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('SELECT DATE',
                    style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              date == null
                  ? 'Tap to pick'
                  : '${date!.day}/${date!.month}/${date!.year}',
              style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: date == null
                      ? AppColors.outline
                      : AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({required this.time, required this.onTap});
  final TimeOfDay? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm + 2),
                  ),
                  child: const Icon(Icons.schedule_rounded,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('SET TIME',
                    style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              time == null
                  ? 'Tap to pick'
                  : time!.format(context),
              style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: time == null
                      ? AppColors.outline
                      : AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
