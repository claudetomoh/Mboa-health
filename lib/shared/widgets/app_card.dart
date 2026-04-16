import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// Mboa Health standard card.
///
/// Per design system:
/// - Background: [AppColors.surfaceContainerLowest] on [AppColors.surfaceContainerLow]
/// - No borders (use tonal contrast, not lines)
/// - Card radius `lg` (1rem = 16dp) or `xl` (1.5rem = 24dp) for hero modules
/// - Ambient shadow: 32px blur, 0x, 8y, 4% opacity — "feels like a whisper"
///
/// Example:
/// ```dart
/// AppCard(
///   child: Text('Content'),
///   paddding: EdgeInsets.all(16),
///   isHero: false, // true = xl radius
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.isHero = false,
    this.color,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets? padding;
  /// When true uses `xl` (24dp) radius — for hero/feature cards.
  final bool isHero;
  final Color? color;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final double radius =
        isHero ? AppSpacing.radiusXl : AppSpacing.radiusLg;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withAlpha(10), // 4% — "ambient whisper"
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppColors.secondaryContainer.withAlpha(77),
          highlightColor: AppColors.surfaceContainerLow.withAlpha(128),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.base),
            child: child,
          ),
        ),
      ),
    );
  }
}
