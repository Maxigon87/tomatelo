import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Tomátelo Official Brand Logo (Stitch Design System)
/// Renders the fused Tomato + Water Droplet vector logo with bioluminescent glow.
class TomateloLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const TomateloLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _TomateloLogoPainter(showGlow: showGlow),
      ),
    );
  }
}

class _TomateloLogoPainter extends CustomPainter {
  final bool showGlow;

  _TomateloLogoPainter({required this.showGlow});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Subtle Background Aura / Glow
    if (showGlow) {
      final glowPaint = Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(const Offset(100, 108), 70, glowPaint);
    }

    // 2. Tomato Body Path & Gradient
    final tomatoPath = Path();
    tomatoPath.moveTo(50, 115);
    tomatoPath.cubicTo(50, 78, 80, 62, 100, 65);
    tomatoPath.cubicTo(120, 62, 150, 78, 150, 115);
    tomatoPath.cubicTo(150, 152, 124, 168, 100, 168);
    tomatoPath.cubicTo(76, 168, 50, 152, 50, 115);
    tomatoPath.close();

    final tomatoPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF5364),
          Color(0xFFE11D48),
        ],
      ).createShader(const Rect.fromLTRB(20, 40, 180, 180));
    canvas.drawPath(tomatoPath, tomatoPaint);

    // 3. Tomato Highlight
    canvas.save();
    canvas.translate(78, 95);
    canvas.rotate(-25 * math.pi / 180);
    final tomatoHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 28, height: 48),
      tomatoHighlightPaint,
    );
    canvas.restore();

    // 4. Fused Water Droplet Path & Gradient
    final dropPath = Path();
    dropPath.moveTo(125, 78);
    dropPath.cubicTo(125, 78, 148, 108, 148, 126);
    dropPath.cubicTo(148, 142, 136, 154, 120, 154);
    dropPath.cubicTo(104, 154, 94, 142, 94, 126);
    dropPath.cubicTo(94, 108, 125, 78, 125, 78);
    dropPath.close();

    final dropPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(const Rect.fromLTRB(94, 78, 148, 154))
      ..color = const Color(0xFF38BDF8);
    canvas.drawPath(dropPath, dropPaint);

    // 5. Droplet Shine Highlight
    canvas.save();
    canvas.translate(112, 118);
    canvas.rotate(-20 * math.pi / 180);
    final dropShinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 8, height: 18),
      dropShinePaint,
    );
    canvas.restore();

    // 6. Botanical Stem & Leaf Shader
    final leafShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF34D399),
        Color(0xFF059669),
      ],
    ).createShader(const Rect.fromLTRB(70, 20, 130, 60));

    final stemPaint = Paint()
      ..shader = leafShader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final stemPath = Path();
    stemPath.moveTo(100, 65);
    stemPath.cubicTo(100, 48, 104, 38, 112, 32);
    canvas.drawPath(stemPath, stemPaint);

    final leafPaint = Paint()..shader = leafShader;

    // Left Leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(96, 46);
    leftLeafPath.cubicTo(84, 42, 75, 46, 72, 50);
    leftLeafPath.cubicTo(76, 56, 86, 54, 98, 50);
    leftLeafPath.close();
    canvas.drawPath(leftLeafPath, leafPaint);

    // Right Leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(105, 46);
    rightLeafPath.cubicTo(117, 40, 128, 44, 130, 50);
    rightLeafPath.cubicTo(125, 55, 114, 53, 103, 49);
    rightLeafPath.close();
    canvas.drawPath(rightLeafPath, leafPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TomateloLogoPainter oldDelegate) =>
      oldDelegate.showGlow != showGlow;
}
