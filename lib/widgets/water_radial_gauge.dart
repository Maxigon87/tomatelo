import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

class WaterRadialGauge extends StatelessWidget {
  final int currentMl;
  final int targetMl;

  const WaterRadialGauge({
    super.key,
    required this.currentMl,
    required this.targetMl,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = targetMl <= 0 ? 3000 : targetMl;
    final progressRatio = (currentMl / safeTarget).clamp(0.0, 1.0);
    final percentage = (progressRatio * 100).toInt();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progressRatio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, animatedRatio, child) {
                  return CustomPaint(
                    size: const Size(240, 130),
                    painter: _ArcGaugePainter(
                      progressRatio: animatedRatio,
                    ),
                  );
                },
              ),
                  Positioned(
                    bottom: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Row(
                            key: ValueKey(currentMl),
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$currentMl',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.onSurface,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'ml',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.flag_rounded,
                              size: 14,
                              color: AppTheme.primaryAqua,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Meta: ${safeTarget >= 1000 ? '${(safeTarget / 1000).toStringAsFixed(1).replaceAll('.0', '')}.000' : safeTarget} ml',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryAqua,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAqua.withValues(
                                  alpha: 0.20,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$percentage%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryAqua,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double progressRatio;

  _ArcGaugePainter({
    required this.progressRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10);
    final radius = size.width / 2 - 20;

    const startAngle = pi;
    const sweepAngle = pi;

    final bgPaint = Paint()
      ..color = const Color(0xFF111C2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (progressRatio > 0) {
      final activeSweepAngle = sweepAngle * progressRatio;
      const blurRadius = 10.0;

      final glowPaint = Paint()
        ..color = AppTheme.primaryAqua.withValues(
          alpha: 0.40,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, blurRadius);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweepAngle,
        false,
        glowPaint,
      );

      final progressPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2563EB), AppTheme.primaryAqua, Color(0xFFA3E3FF)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.progressRatio != progressRatio;
  }
}

