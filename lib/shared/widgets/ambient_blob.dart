import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Decorative ambient tonal blob used as background ornamentation.
///
/// Replicates the CSS blur blobs seen in every Mboa Health screen:
/// ```css
/// .absolute.top-[-10%] { background: secondary-container/10%; blur: 100px }
/// ```
///
/// Per design system: "Decorative Ambient Tonal Layers — Tonal Depth"
///
/// Usage — place inside a [Stack], always with [IgnorePointer]:
/// ```dart
/// Stack(children: [
///   AmbientBlob(color: AppColors.secondaryContainer, opacity: 0.10,
///               size: 300, alignment: Alignment.topRight),
///   AmbientBlob(color: AppColors.primaryFixed, opacity: 0.15,
///               size: 220, alignment: Alignment.bottomLeft),
///   // ... real UI content
/// ])
/// ```
class AmbientBlob extends StatelessWidget {
  const AmbientBlob({
    super.key,
    required this.color,
    this.opacity = 0.10,
    this.size = 300,
    this.sigma = 60.0,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
  });

  /// Base color of the blob.
  final Color color;

  /// Opacity 0–1. Keep ≤ 0.20 for ambient subtlety.
  final double opacity;

  /// Diameter of the blob container in logical pixels.
  final double size;

  /// Gaussian blur sigma — higher = softer edge.
  final double sigma;

  final Alignment alignment;

  /// Fine-tune position beyond alignment.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Transform.translate(
          offset: offset,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: color.withOpacity(opacity),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
