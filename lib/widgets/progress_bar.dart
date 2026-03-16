import 'dart:math';

import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final int current;
  final int total;

  const ProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.total > 0 ? (widget.current / widget.total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.white.withValues(alpha: 0.35)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return FractionallySizedBox(
                  widthFactor: percentage,
                  alignment: Alignment.centerLeft,
                  child: CustomPaint(
                    painter: _LinearWavePainter(phase: _controller.value * 2 * pi),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LinearWavePainter extends CustomPainter {
  final double phase;

  _LinearWavePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF81D4FA), Color(0xFF1E88E5)],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, bgPaint);

    final path = Path()..moveTo(0, size.height * 0.45);
    for (double x = 0; x <= size.width; x++) {
      path.lineTo(x, size.height * 0.45 + sin(x / size.width * 2 * pi + phase) * 2.0);
    }
    path
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(covariant _LinearWavePainter oldDelegate) => oldDelegate.phase != phase;
}
