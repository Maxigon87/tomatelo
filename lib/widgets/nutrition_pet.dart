import 'dart:math' as math;

import 'package:flutter/material.dart';

enum NutritionPetMood { happy, normal, tired }

class NutritionPet extends StatefulWidget {
  const NutritionPet({
    super.key,
    required this.mood,
    required this.progress,
    this.size = 112,
  });

  final NutritionPetMood mood;
  final double progress;
  final double size;

  @override
  State<NutritionPet> createState() => _NutritionPetState();
}

class _NutritionPetState extends State<NutritionPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fruit = _fruitForToday(DateTime.now().weekday);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final tick = _controller.value;
        final breathing = 1 + math.sin(tick * math.pi) * 0.025;
        final yOffset = math.sin(tick * math.pi * 2) * 4;
        final tilt = math.sin(tick * math.pi * 2) * 0.025;

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(
              scale: breathing,
              child: SizedBox(
                width: widget.size,
                height: widget.size + 26,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ..._buildParticles(widget.size, tick),
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFF3C4).withValues(alpha: 0.75),
                            const Color(0xFFFFA94D).withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      fruit,
                      style: TextStyle(fontSize: widget.size * 0.68),
                    ),
                    Positioned(
                      top: widget.size * 0.52,
                      child: _FruitFace(mood: widget.mood),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles(double size, double tick) {
    const particles = ['🍃', '•', '✦', '•', '🍃'];
    return List.generate(particles.length, (index) {
      final angle = (index / particles.length) * math.pi * 2 + tick * 0.45;
      final radius = size * (0.46 + (index.isEven ? 0.08 : 0));
      final dx = math.cos(angle) * radius;
      final dy = math.sin(angle) * radius * 0.45;
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Opacity(
          opacity: 0.36 + math.sin(tick * math.pi + index) * 0.12,
          child: Text(
            particles[index],
            style: TextStyle(
              color: const Color(0xFF7CB342),
              fontSize: index.isEven ? 16 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    });
  }

  String _fruitForToday(int weekday) {
    return switch (weekday) {
      DateTime.monday => '🍎',
      DateTime.tuesday => '🍌',
      DateTime.wednesday => '🍓',
      DateTime.thursday => '🍊',
      DateTime.friday => '🥝',
      DateTime.saturday => '🍇',
      _ => '🍐',
    };
  }
}

class _FruitFace extends StatelessWidget {
  const _FruitFace({required this.mood});

  final NutritionPetMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [_Eye(), _Eye()],
          ),
          const SizedBox(height: 8),
          CustomPaint(
            size: const Size(22, 10),
            painter: _SmilePainter(mood: mood),
          ),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SmilePainter extends CustomPainter {
  const _SmilePainter({required this.mood});

  final NutritionPetMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    if (mood == NutritionPetMood.normal) {
      canvas.drawLine(
        Offset(size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.8, size.height * 0.5),
        paint,
      );
      return;
    }

    final isHappy = mood == NutritionPetMood.happy;
    final rect = Rect.fromLTWH(0, isHappy ? -size.height * 0.5 : 0, size.width, size.height);
    canvas.drawArc(rect, isHappy ? 0.12 : math.pi + 0.12, math.pi - 0.24, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SmilePainter oldDelegate) => oldDelegate.mood != mood;
}
