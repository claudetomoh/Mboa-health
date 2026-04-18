import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/security/security.dart';
import '../providers/health_records_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// Add Record Screen
// Design ref: add_record/code.html
// ────────────────────────────────────────────────────────────────────────────

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>(); // OWASP A03: form-level validation
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  String _selectedCategory = 'Prescription';
  DateTime? _selectedDate;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXxxl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.base),
            Text('Add Document',
                style: AppTypography.titleMd
                    .copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Category label → backend type slug
  static const _typeMap = {
    'Prescription': 'prescription',
    'Lab Report':   'lab_result',
    'Vaccination':  'vaccination',
    'Other':        'other',
  };

  Future<void> _save() async {
    // A03: validate and sanitize before saving.
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date for this record.')),
      );
      return;
    }
    final safeDesc = InputSanitizer.sanitize(_descCtrl.text.trim());
    final injectionError = InputSanitizer.detectInjection(safeDesc);
    if (injectionError != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(injectionError),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final d = _selectedDate!;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final error = await context.read<HealthRecordsProvider>().addRecord({
      'type':  _typeMap[_selectedCategory] ?? 'other',
      'title': _selectedCategory,
      'notes': safeDesc,
      'date':  dateStr,
    });
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
                  // ── Hero header ──────────────────────────────────────
                  Text('Add Record',
                      style: AppTypography.displaySm.copyWith(
                          color: AppColors.primary, letterSpacing: -1)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                      'Digitize your medical documents with a single scan.',
                      style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xl),
                  // ── Camera upload area ────────────────────────────────
                  _UploadArea(imageBytes: _imageBytes, onTap: _showImageSourceSheet),
                  const SizedBox(height: AppSpacing.xl),
                  // ── Form ─────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FormLabel(label: 'Document Description'),
                        const SizedBox(height: AppSpacing.sm),
                        // A03: TextFormField with validator + maxLength guard.
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 4,
                          maxLength: 2000, // OWASP A03: prevent oversized payloads
                          inputFormatters: [
                            // A03: block HTML tag openers at keyboard level.
                            FilteringTextInputFormatter.deny(RegExp(r'<')),
                          ],
                          decoration: InputDecoration(
                            hintText:
                                'E.g. Annual blood work results from Central Hospital...',
                            hintStyle: AppTypography.bodyMd
                                .copyWith(color: AppColors.outline),
                            filled: true,
                            fillColor: AppColors.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXl),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXl),
                              borderSide: const BorderSide(
                                  color: AppColors.primary),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusXl),
                              borderSide:
                                  const BorderSide(color: Colors.red),
                            ),
                            contentPadding:
                                const EdgeInsets.all(AppSpacing.base),
                            counterStyle: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                          validator: (v) =>
                              AppValidators.validateNote(v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // ── Category & date ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormLabel(label: 'Category'),
                            const SizedBox(height: AppSpacing.sm),
                            _CategoryDropdown(
                              value: _selectedCategory,
                              onChanged: (v) =>
                                  setState(() => _selectedCategory = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.base),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormLabel(label: 'Date'),
                            const SizedBox(height: AppSpacing.sm),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.all(
                                    AppSpacing.base),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusXl),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        color: AppColors.outline, size: 18),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      _selectedDate == null
                                          ? 'Pick date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                      style: AppTypography.bodyMd.copyWith(
                                          color: _selectedDate == null
                                              ? AppColors.outline
                                              : AppColors.onSurface),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                              color:
                                  AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8))
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
                                const Icon(Icons.cloud_upload_rounded,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Text('Save Record',
                                    style: AppTypography.titleLg.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                      'Records are encrypted and stored securely following clinical data protection standards.',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.7),
                          height: 1.5,
                          letterSpacing: 0)),
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

class _UploadArea extends StatelessWidget {
  const _UploadArea({required this.imageBytes, required this.onTap});
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 2,
                style: BorderStyle.none),
          ),
          child: imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes!, fit: BoxFit.cover),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // dot-grid background
                    CustomPaint(
                      painter: _DotGridPainter(),
                      child: const SizedBox.expand(),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_camera_rounded,
                                color: AppColors.onPrimaryFixed, size: 32),
                          ),
                          const SizedBox(height: AppSpacing.base),
                          Text('Upload or Scan',
                              style: AppTypography.titleMd.copyWith(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xs2),
                          Text('Capture prescription or lab results',
                              style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: AppSpacing.base),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                            child: Text('Select File',
                                style: AppTypography.labelLg.copyWith(
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.5));
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String?> onChanged;

  static const _options = [
    'Prescription',
    'Lab Report',
    'Vaccination',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded,
              color: AppColors.onSurfaceVariant),
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          onChanged: onChanged,
          items: _options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
        ),
      ),
    );
  }
}
