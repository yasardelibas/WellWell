import 'package:flutter/material.dart';

/// Where the soft WellWell wave bands sit within the available space.
enum WaveAnchor { top, bottom, both }

/// A subtle, brand-flavoured decorative background of soft flowing wave bands
/// (echoing the WellWell "wellness" identity). It is purely decorative: it
/// ignores pointers and paints faint, layered curves so foreground content stays
/// perfectly readable. Drop it behind content inside a [Stack].
class BrandWaves extends StatelessWidget {
  const BrandWaves({
    super.key,
    required this.color,
    this.opacity = 0.08,
    this.anchor = WaveAnchor.bottom,
  });

  /// Base colour of the waves; layers derive their own opacity from [opacity].
  final Color color;

  /// Peak opacity of the strongest layer (kept low for subtlety).
  final double opacity;

  final WaveAnchor anchor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WavePainter(color: color, opacity: opacity, anchor: anchor),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({required this.color, required this.opacity, required this.anchor});

  final Color color;
  final double opacity;
  final WaveAnchor anchor;

  @override
  void paint(Canvas canvas, Size size) {
    if (anchor == WaveAnchor.bottom || anchor == WaveAnchor.both) {
      _paintBand(canvas, size, fromBottom: true);
    }
    if (anchor == WaveAnchor.top || anchor == WaveAnchor.both) {
      _paintBand(canvas, size, fromBottom: false);
    }
  }

  /// Two overlapping wavy bands give a soft sense of depth without hard edges.
  void _paintBand(Canvas canvas, Size size, {required bool fromBottom}) {
    final w = size.width;
    final h = size.height;

    void layer(double heightFactor, double phase, double layerOpacity) {
      final paint = Paint()
        ..color = color.withValues(alpha: (opacity * layerOpacity).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final bandHeight = h * heightFactor;
      final path = Path();
      if (fromBottom) {
        final top = h - bandHeight;
        path.moveTo(0, h);
        path.lineTo(0, top + bandHeight * 0.35);
        path.cubicTo(
          w * (0.25 + phase), top,
          w * (0.55 + phase), top + bandHeight * 0.55,
          w, top + bandHeight * 0.2,
        );
        path.lineTo(w, h);
      } else {
        final bottom = bandHeight;
        path.moveTo(0, 0);
        path.lineTo(0, bottom * 0.65);
        path.cubicTo(
          w * (0.25 + phase), bottom,
          w * (0.55 + phase), bottom * 0.45,
          w, bottom * 0.8,
        );
        path.lineTo(w, 0);
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Back layer (larger, fainter) then front layer (smaller, slightly stronger).
    layer(0.42, -0.05, 0.6);
    layer(0.30, 0.08, 1.0);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity || oldDelegate.anchor != anchor;
}
