import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Branded input field that strictly follows the "Clinical Sanctuary"
/// design system input rules:
/// - Background: [AppColors.surfaceContainerLow] at rest.
/// - On focus: background transitions to [AppColors.surfaceContainerLowest]
///   + 1px "Ghost Border" using [AppColors.primary].
/// - Forbids high-contrast black borders.
///
/// Usage:
/// ```dart
/// AppInputField(
///   label: 'Email Address',
///   hint: 'name@example.com',
///   prefixIcon: Icons.mail_outline,
///   keyboardType: TextInputType.emailAddress,
///   controller: _emailController,
/// )
/// ```
class AppInputField extends StatefulWidget {
  const AppInputField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.autofillHints,
  });

  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final Iterable<String>? autofillHints;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text(
              widget.label!,
              style: AppTypography.labelMd.copyWith(
                color: _hasFocus
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _hasFocus
                ? AppColors.surfaceContainerLowest
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _hasFocus
                  ? AppColors.primary
                  : Colors.transparent,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: widget.validator,
            maxLines: widget.maxLines,
            autofillHints: widget.autofillHints,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
              fontSize: 15,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.outline.withAlpha(153),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: AppSpacing.iconMd,
                      color: _hasFocus
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    )
                  : null,
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixTap,
                      child: Icon(
                        widget.suffixIcon,
                        size: AppSpacing.iconMd,
                        color: AppColors.onSurfaceVariant,
                      ),
                    )
                  : null,
              // Fill & border managed by wrapping AnimatedContainer
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
