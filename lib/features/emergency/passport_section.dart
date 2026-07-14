import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../profile/providers/profile_provider.dart';
import 'providers/passport_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Digital Health Passport Section
// Status + key medical fields (reusing ProfileProvider, same source as the
// rest of this screen — CC-03) plus lifecycle actions backed by the
// authenticated passport endpoint (CC-04) and the public view endpoint
// (CC-05A). Visual language matches the existing surfaceContainerLow /
// radiusXl card convention used throughout this screen.
// ─────────────────────────────────────────────────────────────────────────────

class PassportSection extends StatefulWidget {
  const PassportSection({super.key});

  @override
  State<PassportSection> createState() => _PassportSectionState();
}

class _PassportSectionState extends State<PassportSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PassportProvider>().fetchStatus();
    });
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<String?> Function() action,
    required String successMessage,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? successMessage)),
    );
  }

  void _showQr(PassportProvider passport) {
    final url = passport.publicUrl;
    if (url == null) return;

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
            children: [
              Text('Your Passport QR',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.base),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: QrImageView(data: url, size: 220),
              ),
              const SizedBox(height: AppSpacing.base),
              Text(
                'Anyone who scans this code can view your blood type, '
                'allergies, and emergency contact. Regenerate anytime to '
                'invalidate it immediately.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAsText(PassportProvider passport) async {
    final error = await passport.fetchPublicSnapshot();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final data = passport.publicSnapshot ?? const <String, dynamic>{};
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
              Text('Passport — Text View',
                  style: AppTypography.headlineSm
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs2),
              Text(
                'Exactly what the public passport link exposes — the same '
                'whitelist a scanner would see.',
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.base),
              _TextRow('Full Name', data['full_name'] as String?),
              _TextRow('Date of Birth', data['date_of_birth'] as String?),
              _TextRow('Blood Type', data['blood_type'] as String?),
              _TextRow('Allergies', data['allergies'] as String?),
              _TextRow('Emergency Contact',
                  data['emergency_contact_name'] as String?),
              _TextRow('Emergency Phone',
                  data['emergency_contact_phone'] as String?),
              _TextRow('Last Updated', data['last_updated'] as String?),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passport = context.watch<PassportProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Digital Health Passport',
            style: AppTypography.headlineSm
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: _buildBody(context, passport),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, PassportProvider passport) {
    if (passport.isLoading && !passport.exists) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!passport.exists) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set up a shareable emergency medical summary that first '
            'responders can scan.',
            style: AppTypography.bodySm
                .copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: passport.isLoading
                  ? null
                  : () async {
                      final error = await passport.create();
                      if (!mounted) return;
                      if (error != null) {
                        ScaffoldMessenger.of(this.context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
              child: Text(passport.isLoading ? 'Creating…' : 'Create Passport'),
            ),
          ),
        ],
      );
    }

    // Blood type / allergies / primary contact come from ProfileProvider —
    // the same source already used by the Medical ID card (CC-02/CC-03),
    // not a second fetch.
    final profile  = context.watch<ProfileProvider>();
    final user     = profile.user;
    final contacts = profile.emergencyContacts;
    Map<String, dynamic>? primary;
    if (contacts.isNotEmpty) {
      primary = contacts.firstWhere(
        (c) => c['is_primary'] == true,
        orElse: () => contacts.first,
      );
    }

    final bloodType = (user?.bloodType?.trim().isNotEmpty ?? false)
        ? user!.bloodType!.trim()
        : 'Not provided';
    final allergies = (user?.allergies?.trim().isNotEmpty ?? false)
        ? user!.allergies!.trim()
        : 'Not provided';
    final contactText = (primary != null &&
            (primary['full_name'] as String?)?.trim().isNotEmpty == true)
        ? '${primary['full_name']} (${primary['phone'] ?? 'Not provided'})'
        : 'Not provided';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusPill(isActive: passport.isActive),
            const Spacer(),
            if (passport.updatedAt != null)
              Flexible(
                child: Text(
                  'Updated ${passport.updatedAt}',
                  textAlign: TextAlign.end,
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        _InfoRow('Blood Type', bloodType),
        _InfoRow('Allergies', allergies),
        _InfoRow('Primary Contact', contactText),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _ActionChip(
              icon: Icons.qr_code_rounded,
              label: 'Show QR',
              onTap: () => _showQr(passport),
            ),
            _ActionChip(
              icon: Icons.text_snippet_rounded,
              label: 'View as Text',
              onTap: passport.isSnapshotLoading
                  ? null
                  : () => _showAsText(passport),
            ),
            _ActionChip(
              icon: Icons.refresh_rounded,
              label: 'Regenerate',
              onTap: !passport.isActive || passport.isLoading
                  ? null
                  : () => _confirmAndRun(
                        title: 'Regenerate passport?',
                        message:
                            'The current QR code will stop working immediately.',
                        action: passport.regenerate,
                        successMessage: 'Passport regenerated.',
                      ),
            ),
            _ActionChip(
              icon: passport.isActive
                  ? Icons.block_rounded
                  : Icons.check_circle_outline_rounded,
              label: passport.isActive ? 'Disable' : 'Enable',
              onTap: passport.isLoading
                  ? null
                  : () => _confirmAndRun(
                        title: passport.isActive
                            ? 'Disable passport?'
                            : 'Enable passport?',
                        message: passport.isActive
                            ? 'Your passport will stop working until you '
                                'enable it again.'
                            : 'A new QR code will be issued. The previous '
                                'one stays invalid.',
                        action:
                            passport.isActive ? passport.disable : passport.enable,
                        successMessage: passport.isActive
                            ? 'Passport disabled.'
                            : 'Passport enabled.',
                      ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer : AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        isActive ? 'Active' : 'Disabled',
        style: AppTypography.labelSm.copyWith(
          color: isActive
              ? AppColors.onSecondaryContainer
              : AppColors.onErrorContainer,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodySm
                    .copyWith(color: AppColors.onSurface)),
          ),
        ],
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  const _TextRow(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? 'Not provided' : value!,
              style: AppTypography.bodySm.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8)
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: enabled ? AppColors.primary : AppColors.outline),
            const SizedBox(width: AppSpacing.xs),
            Text(label,
                style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.onSurface : AppColors.outline)),
          ],
        ),
      ),
    );
  }
}
