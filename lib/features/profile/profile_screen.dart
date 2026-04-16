import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/routing/app_routes.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/profile_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Profile Screen
// Design ref: profile/code.html
// ─────────────────────────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Seed from auth then fetch full profile
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    if (auth.user != null) profile.seedFromAuth(auth.user!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfile();
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
                  // Profile header
                  const _ProfileHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  // Stats bento
                  const _StatsBento(),
                  const SizedBox(height: AppSpacing.xl),
                  // Emergency Contacts
                  const _EmergencyContactsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  // Settings
                  const _SettingsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  // Logout
                  const _LogoutSection(),
                  const SizedBox(height: AppSpacing.xl2),
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

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final provider = context.read<ProfileProvider>();
    final error = await provider.uploadAvatar(picked);
    if (!mounted) return;
    setState(() => _uploading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Avatar circle ─────────────────────────────────────────────
            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: Consumer<ProfileProvider>(
                builder: (context, p, _) {
                  final avatarUrl = p.user?.avatarUrl;
                  return Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXxl),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16)
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusXxl - 4),
                      child: _uploading
                          ? const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
                              ),
                            )
                          : avatarUrl != null
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.person_rounded,
                                    color: AppColors.onSurfaceVariant,
                                    size: 56,
                                  ),
                                )
                              : const Icon(Icons.person_rounded,
                                  color: AppColors.onSurfaceVariant, size: 56),
                    ),
                  );
                },
              ),
            ),
            // ── Camera button ─────────────────────────────────────────────
            Positioned(
              bottom: -6,
              right: -6,
              child: GestureDetector(
                onTap: _uploading ? null : _pickAndUpload,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<ProfileProvider>(
                builder: (_, p, _) => Text(
                  p.user?.fullName ?? 'Your Profile',
                  style: AppTypography.headlineMd.copyWith(
                      letterSpacing: -0.5),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Consumer<ProfileProvider>(
                builder: (_, p, _) {
                  final role = p.user?.role ?? 'patient';
                  final email = p.user?.email ?? '';
                  return Text(
                    '${role[0].toUpperCase()}${role.substring(1)} • $email',
                    style: AppTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w500),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              const Wrap(
                spacing: AppSpacing.xs,
                children: [
                  _Badge(label: 'Premium Member',
                      bg: AppColors.primaryFixed,
                      fg: AppColors.onPrimaryFixed),
                  _Badge(label: 'Verified Pro',
                      bg: AppColors.secondaryContainer,
                      fg: AppColors.onSecondaryContainer),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg, fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: AppTypography.labelSm.copyWith(
              color: fg, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
    );
  }
}

class _StatsBento extends StatelessWidget {
  const _StatsBento();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (_, p, _) {
        final stats = [
          ('Blood Type', p.user?.bloodType ?? '—', ''),
          ('Records', '${p.recordsCount}', ''),
          ('Reminders', '${p.remindersCount}', 'active'),
          ('Contacts', '${p.contactsCount}', ''),
        ];
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.6,
          children: stats
              .map((s) => Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$1,
                        style: AppTypography.labelSm.copyWith(
                            letterSpacing: 1.2)),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        text: s.$2,
                        style: AppTypography.headlineMd.copyWith(
                            color: AppColors.primary),
                        children: s.$3.isNotEmpty
                            ? [
                                TextSpan(
                                  text: ' ${s.$3}',
                                  style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.6)),
                                )
                              ]
                            : [],
                      ),
                    ),
                  ],
                ),
              ))
              .toList(),
        );
      },
    );
  }
}

class _EmergencyContactsSection extends StatelessWidget {
  const _EmergencyContactsSection();

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _delete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        title: const Text('Remove Contact'),
        content: const Text(
            'Are you sure you want to remove this emergency contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final err =
        await context.read<ProfileProvider>().deleteEmergencyContact(id);
    if (context.mounted && err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade700),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profile, _) {
        final contacts = profile.emergencyContacts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emergency Contacts',
                    style: AppTypography.headlineSm.copyWith(
                        fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _showAddContactSheet(context),
                      icon: const Icon(Icons.add_circle_rounded,
                          color: AppColors.primary),
                      tooltip: 'Add Contact',
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.emergencyPortal),
                      child: Text('Manage All',
                          style: AppTypography.labelMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (profile.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (contacts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    'No emergency contacts added yet.',
                    style: AppTypography.labelMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...contacts.asMap().entries.map((entry) {
                final i = entry.key;
                final c = entry.value;
                final id = (c['id'] as num?)?.toInt() ?? -1;
                final isPrimary = c['is_primary'] as bool? ?? false;
                final relation =
                    '${c['relationship'] ?? ''}  \u2022  ${isPrimary ? 'Primary' : 'Secondary'} Contact';
                return Padding(
                  padding: i > 0
                      ? const EdgeInsets.only(top: AppSpacing.sm)
                      : EdgeInsets.zero,
                  child: _ContactTile(
                    name: c['full_name'] as String? ?? '\u2014',
                    relation: relation,
                    phone: c['phone'] as String? ?? '',
                    bg: isPrimary
                        ? AppColors.tertiaryContainer.withValues(alpha: 0.05)
                        : AppColors.surfaceContainerLow,
                    callBg: isPrimary
                        ? AppColors.tertiaryContainer
                        : AppColors.surfaceContainerHighest,
                    callFg: isPrimary
                        ? AppColors.onTertiary
                        : AppColors.primary,
                    onCall: _call,
                    onDelete: () => _delete(context, id),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.name,
    required this.relation,
    required this.phone,
    required this.bg,
    required this.callBg,
    required this.callFg,
    required this.onCall,
    this.onDelete,
  });
  final String name, relation, phone;
  final Color bg, callBg, callFg;
  final Future<void> Function(String phone) onCall;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.onSurfaceVariant, size: 24),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs2),
                Text(relation, style: AppTypography.labelSm),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onCall(phone),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: callBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.call_rounded, color: callFg, size: 18),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: AppSpacing.xs),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade700, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          sub: 'Update your medical records & profile',
          onTap: () => _showPersonalInfoSheet(context)),
      _SettingItem(
          icon: Icons.notifications_active_rounded,
          title: 'Notification Settings',
          sub: 'Manage medical alerts & reminders',
          onTap: () =>
              Navigator.pushNamed(context, AppRoutes.notifications)),
      _SettingItem(
          icon: Icons.security_rounded,
          title: 'Privacy & Security',
          sub: 'Biometric lock & data permissions',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy & Security — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              )),
      _SettingItem(
          icon: Icons.language_rounded,
          title: 'Language',
          sub: 'English (US)',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language & Region — coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              )),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings',
            style:
                AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12)
            ],
          ),
          child: Column(
            children: items
                .map((item) => Column(
                      children: [
                        _SettingRow(item: item),
                        if (item != items.last)
                          const Divider(indent: 72, height: 0),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingItem {
  const _SettingItem({
    required this.icon,
    required this.title,
    required this.sub,
    this.onTap,
  });
  final IconData icon;
  final String title, sub;
  final VoidCallback? onTap;
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.item});
  final _SettingItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(item.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(item.sub, style: AppTypography.labelSm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutSection extends StatelessWidget {
  const _LogoutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.login, (_) => false);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
              boxShadow: [
                BoxShadow(
                    color: AppColors.tertiaryContainer.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('LOGOUT SECURELY',
                    style: AppTypography.labelLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Version 2.4.1 (Clinical Build)',
            textAlign: TextAlign.center,
            style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Emergency Contact Sheet
// ─────────────────────────────────────────────────────────────────────────────

void _showAddContactSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddContactSheet(
      provider: context.read<ProfileProvider>(),
    ),
  );
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet({required this.provider});
  final ProfileProvider provider;

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _nameCtrl     = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _relationCtrl = TextEditingController();
  bool _isPrimary = false;
  bool _saving    = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Name and phone are required.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final err = await widget.provider.addEmergencyContact({
      'full_name':    _nameCtrl.text.trim(),
      'phone':        _phoneCtrl.text.trim(),
      'relationship': _relationCtrl.text.trim(),
      'is_primary':   _isPrimary ? 1 : 0,
    });
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _error = err; });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal, AppSpacing.xl,
        AppSpacing.screenHorizontal, AppSpacing.xl + bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Add Emergency Contact',
                style: AppTypography.headlineSm
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('This person will be alerted in emergencies.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),
            _SheetField(
                label: 'Full Name',
                controller: _nameCtrl,
                hint: 'e.g. Marie Nguemo'),
            const SizedBox(height: AppSpacing.base),
            _SheetField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                hint: '+237 6XX XXX XXX',
                keyboardType: TextInputType.phone),
            const SizedBox(height: AppSpacing.base),
            _SheetField(
                label: 'Relationship (optional)',
                controller: _relationCtrl,
                hint: 'e.g. Spouse, Parent, Friend'),
            const SizedBox(height: AppSpacing.base),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Primary Contact',
                  style: AppTypography.labelMd
                      .copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text('Will appear first in emergencies',
                  style: AppTypography.labelSm
                      .copyWith(color: AppColors.onSurfaceVariant)),
              value: _isPrimary,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
              onChanged: (v) => setState(() => _isPrimary = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: AppTypography.labelSm
                      .copyWith(color: Colors.red.shade700)),
            ],
            const SizedBox(height: AppSpacing.xl),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: _saving
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                      )
                    : Text('Save Contact',
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMd.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Personal Information Sheet
// ─────────────────────────────────────────────────────────────────────────────

void _showPersonalInfoSheet(BuildContext context) {
  final provider = context.read<ProfileProvider>();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PersonalInfoSheet(provider: provider),
  );
}

class _PersonalInfoSheet extends StatefulWidget {
  const _PersonalInfoSheet({required this.provider});
  final ProfileProvider provider;

  @override
  State<_PersonalInfoSheet> createState() => _PersonalInfoSheetState();
}

class _PersonalInfoSheetState extends State<_PersonalInfoSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _allergiesCtrl;
  String? _bloodType;
  bool _saving = false;
  String? _saveError;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.provider.user;
    _nameCtrl      = TextEditingController(text: u?.fullName ?? '');
    _phoneCtrl     = TextEditingController(text: u?.phone ?? '');
    _allergiesCtrl = TextEditingController(text: u?.allergies ?? '');
    _bloodType     = u?.bloodType;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _saveError = 'Full name is required');
      return;
    }
    setState(() { _saving = true; _saveError = null; });
    final err = await widget.provider.updateProfile({
      'full_name':  _nameCtrl.text.trim(),
      'phone':      _phoneCtrl.text.trim(),
      'blood_type': _bloodType,
      'allergies':  _allergiesCtrl.text.trim(),
    });
    if (!mounted) return;
    if (err != null) {
      setState(() { _saving = false; _saveError = err; });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal, AppSpacing.xl,
        AppSpacing.screenHorizontal, AppSpacing.xl + bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxl)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Personal Information',
                style: AppTypography.headlineSm
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text('Update your profile details below.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xl),
            // Full name
            _SheetField(
                label: 'Full Name',
                controller: _nameCtrl,
                hint: 'e.g. Jean-Baptiste Nkoa'),
            const SizedBox(height: AppSpacing.base),
            // Phone
            _SheetField(
                label: 'Phone',
                controller: _phoneCtrl,
                hint: '+237 6XX XXX XXX',
                keyboardType: TextInputType.phone),
            const SizedBox(height: AppSpacing.base),
            // Blood type
            Text('Blood Type',
                style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: _bloodTypes.map((bt) {
                final selected = _bloodType == bt;
                return ChoiceChip(
                  label: Text(bt),
                  selected: selected,
                  onSelected: (_) => setState(() => _bloodType = bt),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.onSurface,
                  ),
                  backgroundColor: AppColors.surfaceContainerLow,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.base),
            // Allergies
            _SheetField(
                label: 'Allergies / Intolerances',
                controller: _allergiesCtrl,
                hint: 'e.g. Penicillin, Peanuts',
                maxLines: 2),
            if (_saveError != null) ...
              [
                const SizedBox(height: AppSpacing.sm),
                Text(_saveError!,
                    style: AppTypography.bodyMd.copyWith(
                        color: AppColors.tertiaryContainer)),
              ],
            const SizedBox(height: AppSpacing.xl),
            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: _saving
                      ? AppColors.surfaceContainerHigh
                      : AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text('Save Changes',
                          style: AppTypography.labelLg.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelMd.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.base),
          ),
        ),
      ],
    );
  }
}
