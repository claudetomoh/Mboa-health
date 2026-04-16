import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Gradient-filled primary CTA button used throughout Mboa Health.
///
/// Implements the design system rule:
/// "For primary CTAs, use a linear gradient from `primary` (#00450d)
/// to `primary_container` (#1b5e20) at a 135° angle."
///
/// Usage:
/// ```dart
/// GradientButton(
///   label: 'Get Started',
///   onPressed: () => Navigator.pushNamed(context, AppRoutes.onboarding),
/// )
/// ```
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Optional trailing icon (e.g., `Icons.arrow_forward`).
  final IconData? icon;

  /// Shows a [CircularProgressIndicator] and disables taps while true.
  final bool loading;

  /// If false, the button wraps its content instead of filling width.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null // disabled: flat, muted
            : AppColors.primaryGradient,
        color: onPressed == null
            ? AppColors.surfaceContainerHigh
            : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withAlpha(51), // 20%
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          splashColor: Colors.white.withAlpha(51),
          highlightColor: Colors.white.withAlpha(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.base,
            ),
            child: SizedBox(
              height: AppSpacing.buttonHeight - (AppSpacing.base * 2),
              child: loading
                  ? const Center(
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.onPrimary,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          expanded ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: AppTypography.titleMd.copyWith(
                            color: onPressed == null
                                ? AppColors.onSurfaceVariant
                                : AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            icon,
                            size: AppSpacing.iconSm,
                            color: onPressed == null
                                ? AppColors.onSurfaceVariant
                                : AppColors.onPrimary,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return expanded
        ? SizedBox(
            height: AppSpacing.buttonHeight,
            width: double.infinity,
            child: button,
          )
        : SizedBox(height: AppSpacing.buttonHeight, child: button);
  }
}
