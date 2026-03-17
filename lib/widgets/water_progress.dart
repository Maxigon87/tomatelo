import 'dart:math';

import 'package:flutter/material.dart';

class WaterProgress extends StatefulWidget {
  final int current;
  final int total;

  const WaterProgress({super.key, required this.current, required this.total});

  @override
  State<WaterProgress> createState() => _WaterProgressState();
}

class _WaterProgressState extends State<WaterProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.total == 0
        ? 0.0
        : (widget.current / widget.total).clamp(0.0, 1.0);

    return SizedBox(
      width: 210,
      height: 210,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF81D4FA), Color(0xFF1E88E5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              ClipOval(
                child: CustomPaint(
                  size: const Size(190, 190),
                  painter: _WavePainter(
                    phase: _waveController.value * 2 * pi,
                    progress: progress,
                  ),
                ),
              ),
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 3,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.current} / ${widget.total}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'glasses',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final double progress;

  _WavePainter({required this.phase, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final fillY = size.height * (1 - progress);

    final water = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FC3F7), Color(0xFF1E88E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    final path = Path()..moveTo(0, fillY);

    for (double x = 0; x <= size.width; x++) {
      final y = fillY + sin((x / size.width * 2 * pi) + phase) * 6;
      path.lineTo(x, y);
    }

    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, water);

    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    for (int i = 0; i < 6; i++) {
      final dx = (i * 31.0 + phase * 10) % size.width;
      final dy =
          fillY +
          20 +
          (i * 12.0) % (size.height - fillY).clamp(12.0, size.height);
      canvas.drawCircle(Offset(dx, dy), 2.8, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.progress != progress;
  }
}
