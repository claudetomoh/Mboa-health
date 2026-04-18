import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/models/notification_model.dart';
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
                  Consumer<NotificationsProvider>(
                    builder: (_, p, _) {
                      if (p.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl8),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (p.notifications.isEmpty) {
                        return const _EmptyNotificationsState();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Notifications',
                                  style: AppTypography.headlineSm.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Row(
                                children: [
                                  if (p.unreadCount > 0)
                                    Container(
                                      margin: const EdgeInsets.only(right: AppSpacing.sm),
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
                                              color: AppColors.onPrimaryFixedVariant,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  TextButton(
                                    onPressed: () =>
                                        context.read<NotificationsProvider>().markAllRead(),
                                    child: Text('Mark all read',
                                        style: AppTypography.labelMd.copyWith(
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...p.notifications.map((n) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
      actions: const [],
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

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
            child: const Icon(Icons.notifications_none_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('No notifications yet',
              style: AppTypography.titleLg.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Text('Health alerts, reminders, and updates\nwill appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
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
