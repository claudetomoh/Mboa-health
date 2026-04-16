import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/notification_model.dart';
import '../../core/routing/app_routes.dart';
import 'providers/notifications_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notifications Screen
// Design ref: notifications/code.html
// ─────────────────────────────────────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().fetchNotifications();
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
                AppSpacing.screenHorizontal, AppSpacing.xl8,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Today
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Today',
                          style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700)),
                      TextButton(
                        onPressed: () =>
                            context.read<NotificationsProvider>().markAllRead(),
                        child: Text('Mark all as read',
                            style: AppTypography.labelMd.copyWith(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Critical Alert
                  const _CriticalAlertCard(),
                  const SizedBox(height: AppSpacing.md),
                  const _NotifCard(
                    iconBg: AppColors.secondaryContainer,
                    icon: Icons.health_and_safety_rounded,
                    iconColor: AppColors.onSecondaryContainer,
                    typeLabel: 'Health Insight',
                    typeColor: AppColors.secondary,
                    time: '2h ago',
                    title: 'Your weekly sleep score improved by 12%',
                    body:
                        'Great job! Consistency in your bedtime routine is showing clear benefits in your recovery metrics.',
                    isUnread: true,
                    dimmed: false,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _NotifCard(
                    iconBg: AppColors.primaryFixed,
                    icon: Icons.medication_rounded,
                    iconColor: AppColors.onPrimaryFixedVariant,
                    typeLabel: 'Reminders',
                    typeColor: AppColors.primary,
                    time: '4h ago',
                    title: 'Time for your morning supplements',
                    body:
                        'Remember to take your Vitamin D and Omega-3 with food for better absorption.',
                    isUnread: true,
                    dimmed: false,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Earlier this week',
                      style: AppTypography.headlineSm.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.md),
                  const _NotifCard(
                    iconBg: AppColors.surfaceContainerHigh,
                    icon: Icons.calendar_today_rounded,
                    iconColor: AppColors.onSurfaceVariant,
                    typeLabel: 'Appointment',
                    typeColor: AppColors.onSurfaceVariant,
                    time: '2 days ago',
                    title: 'Lab Results are Ready',
                    body:
                        'Your results from St. Luke\'s Diagnostic Center have been uploaded to your health records.',
                    isUnread: false,
                    dimmed: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _NotifCard(
                    iconBg: AppColors.surfaceContainerHigh,
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.onSurfaceVariant,
                    typeLabel: 'Community',
                    typeColor: AppColors.onSurfaceVariant,
                    time: '4 days ago',
                    title: 'Wellness Workshop tomorrow',
                    body:
                        "Don't forget the 'Mindful Living' webinar starting at 10:00 AM. Access link is in your email.",
                    isUnread: false,
                    dimmed: true,
                  ),
                  const SizedBox(height: AppSpacing.xl4),
                  // Empty state cue
                  const _EmptyStateCue(),
                  // ── Live notifications from API ──
                  Consumer<NotificationsProvider>(
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
                      if (p.notifications.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text('All Notifications',
                                  style: AppTypography.headlineSm.copyWith(
                                      fontWeight: FontWeight.w700)),
                              if (p.unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryFixed,
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusFull),
                                  ),
                                  child: Text('${p.unreadCount} unread',
                                      style: AppTypography.labelSm.copyWith(
                                          color:
                                              AppColors.onPrimaryFixedVariant,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...p.notifications.map((n) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: _LiveNotifTile(notification: n),
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
      title: Text('Alerts',
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

class _CriticalAlertCard extends StatelessWidget {
  const _CriticalAlertCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
              color: AppColors.tertiaryContainer.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.crisis_alert_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('CRITICAL ALERT',
                              style: AppTypography.labelSm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 1.5)),
                          Text('10m ago',
                              style: AppTypography.labelSm.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                          'Emergency: High Blood Pressure detected',
                          style: AppTypography.titleMd.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                          'Your smart-monitor detected a spike (155/95). Please rest and contact your physician if symptoms persist.',
                          style: AppTypography.bodySm.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.5)),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                            context, AppRoutes.emergencyPortal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.base,
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd),
                          ),
                          child: Text('Take Action',
                              style: AppTypography.labelSm.copyWith(
                                  color: AppColors.tertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                      ),
                    ],
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

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.typeLabel,
    required this.typeColor,
    required this.time,
    required this.title,
    required this.body,
    required this.isUnread,
    required this.dimmed,
  });

  final Color iconBg, iconColor, typeColor;
  final IconData icon;
  final String typeLabel, time, title, body;
  final bool isUnread, dimmed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.75 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: dimmed
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          boxShadow: dimmed
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(typeLabel.toUpperCase(),
                          style: AppTypography.labelSm.copyWith(
                              color: typeColor, letterSpacing: 1.0)),
                      Text(time,
                          style: AppTypography.labelSm.copyWith(
                              letterSpacing: 0)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(title,
                      style: AppTypography.titleSm.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(body,
                      style: AppTypography.bodySm.copyWith(height: 1.5)),
                ],
              ),
            ),
            if (isUnread) ...
              [
                const SizedBox(width: AppSpacing.sm),
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: _UnreadDot(),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _EmptyStateCue extends StatelessWidget {
  const _EmptyStateCue();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.3,
      child: Column(
        children: [
          const Icon(Icons.notifications_off_rounded,
              size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text("You've reached the end of your alerts",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Notification Tile (from API)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveNotifTile extends StatelessWidget {
  const _LiveNotifTile({required this.notification});
  final AppNotification notification;

  IconData get _icon {
    switch (notification.type) {
      case 'reminder':
        return Icons.medication_rounded;
      case 'appointment':
        return Icons.calendar_today_rounded;
      case 'alert':
        return Icons.crisis_alert_rounded;
      case 'system':
        return Icons.info_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;
    return GestureDetector(
      onTap: isUnread
          ? () => context
              .read<NotificationsProvider>()
              .markRead(notification.id)
          : null,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.primaryFixed.withValues(alpha: 0.15)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: isUnread
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.20))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isUnread
                  ? AppColors.primaryFixed
                  : AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon,
                color: isUnread
                    ? AppColors.onPrimaryFixedVariant
                    : AppColors.onSurfaceVariant,
                size: 20),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: isUnread
                            ? FontWeight.w700
                            : FontWeight.w500)),
                if (notification.body != null) ...[
                  const SizedBox(height: AppSpacing.xs2),
                  Text(notification.body!,
                      style: AppTypography.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(notification.createdAt,
                    style: AppTypography.labelSm.copyWith(
                        color: AppColors.outline)),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
    );
  }
}
