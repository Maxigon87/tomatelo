import 'dart:math';

import 'package:flutter/material.dart';

class DropletAnimation extends StatefulWidget {
  final bool trigger;

  const DropletAnimation({super.key, required this.trigger});

  @override
  State<DropletAnimation> createState() => _DropletAnimationState();
}

class _DropletAnimationState extends State<DropletAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 750),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _isVisible = false;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant DropletAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final dropY = -100 + (240 * t);
          final splashOpacity = (1 - (t - 0.6).clamp(0, 1) * 2).clamp(0, 1);

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: dropY,
                child: Opacity(
                  opacity: 1 - (t - 0.75).clamp(0, 1),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 40,
                    color: Color(0xFF4FC3F7),
                  ),
                ),
              ),
              if (t > 0.55)
                Positioned(
                  top: 150,
                  child: Opacity(
                    opacity: splashOpacity.toDouble(),
                    child: CustomPaint(
                      size: const Size(120, 40),
                      painter: _SplashPainter(progress: (t - 0.55) / 0.45),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SplashPainter extends CustomPainter {
  final double progress;

  _SplashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFF81D4FA).withValues(alpha: (1 - p) * 0.8)
      ..style = PaintingStyle.fill;

    final width = size.width * (0.2 + (p * 0.8));
    final height = size.height * (0.25 + p * 0.6);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.75),
      width: width,
      height: height,
    );

    canvas.drawOval(rect, paint);

    final dropPaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.5 * (1 - p))
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final x = size.width / 2 + cos(i * pi / 3) * (12 + p * 40);
      final y = size.height * 0.72 - sin(i * pi / 3) * (8 + p * 12);
      canvas.drawCircle(Offset(x, y), 3 + 2 * (1 - p), dropPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
