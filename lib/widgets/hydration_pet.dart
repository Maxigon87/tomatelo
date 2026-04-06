import 'dart:math' as math;

import 'package:flutter/material.dart';

enum HydrationPetMood { happy, normal, tired }

class HydrationPet extends StatefulWidget {
  const HydrationPet({super.key, required this.mood, this.size = 122});

  final HydrationPetMood mood;
  final double size;

  @override
  State<HydrationPet> createState() => _HydrationPetState();
}

class _HydrationPetState extends State<HydrationPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: _PetBody(
        key: ValueKey(widget.mood),
        mood: widget.mood,
        size: widget.size,
        animation: _controller,
      ),
    );
  }
}

class _PetBody extends StatelessWidget {
  const _PetBody({
    super.key,
    required this.mood,
    required this.size,
    required this.animation,
  });

  final HydrationPetMood mood;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final dropColor = switch (mood) {
      HydrationPetMood.happy => const Color(0xFF38BDF8),
      HydrationPetMood.normal => const Color(0xFF60A5FA),
      HydrationPetMood.tired => const Color(0xFF94A3B8),
    };

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final tick = animation.value;
        final yOffset = switch (mood) {
          HydrationPetMood.happy => math.sin(tick * math.pi * 2) * 4,
          HydrationPetMood.normal => math.sin(tick * math.pi * 2) * 2.4,
          HydrationPetMood.tired => math.sin(tick * math.pi * 2) * 1.3 + 2,
        };
        final tilt = switch (mood) {
          HydrationPetMood.happy => math.sin(tick * math.pi * 2) * 0.02,
          HydrationPetMood.normal => math.sin(tick * math.pi * 2) * 0.01,
          HydrationPetMood.tired => -0.09,
        };

        return Transform.translate(
          offset: Offset(0, yOffset),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              width: size,
              height: size + 26,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (mood == HydrationPetMood.happy)
                    ..._HappyBubbles.build(size: size, tick: tick),
                  CustomPaint(
                    size: Size.square(size),
                    painter: _DropPainter(color: dropColor),
                  ),
                  _PetFace(mood: mood),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PetFace extends StatelessWidget {
  const _PetFace({required this.mood});

  final HydrationPetMood mood;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, 0.35),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Eye(mood: mood),
                _Eye(mood: mood),
              ],
            ),
            const SizedBox(height: 10),
            _Mouth(mood: mood),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.mood});

  final HydrationPetMood mood;

  @override
  Widget build(BuildContext context) {
    if (mood == HydrationPetMood.happy) {
      return const _Arc(stroke: 3, width: 18, height: 11);
    }
    if (mood == HydrationPetMood.tired) {
      return Container(
        width: 16,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Mouth extends StatelessWidget {
  const _Mouth({required this.mood});

  final HydrationPetMood mood;

  @override
  Widget build(BuildContext context) {
    return switch (mood) {
      HydrationPetMood.happy => const RotatedBox(
        quarterTurns: 2,
        child: _Arc(stroke: 3, width: 24, height: 12),
      ),
      HydrationPetMood.normal => Container(
        width: 16,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      HydrationPetMood.tired => const _Arc(stroke: 3, width: 20, height: 8),
    };
  }
}

class _Arc extends StatelessWidget {
  const _Arc({required this.stroke, required this.width, required this.height});

  final double stroke;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(width, height), painter: _ArcPainter(stroke));
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter(this.stroke);
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}

class _DropPainter extends CustomPainter {
  _DropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.2,
        size.width * 0.95,
        size.height * 0.62,
        size.width / 2,
        size.height,
      )
      ..cubicTo(
        size.width * 0.05,
        size.height * 0.62,
        size.width * 0.14,
        size.height * 0.2,
        size.width / 2,
        0,
      )
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.92), color.withOpacity(0.65)],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final glare = Path()
      ..moveTo(size.width * 0.43, size.height * 0.24)
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.34,
        size.width * 0.32,
        size.height * 0.55,
      );

    canvas.drawPath(
      glare,
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DropPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HappyBubbles {
  static List<Widget> build({required double size, required double tick}) {
    final particles = <({double x, double y, double s})>[
      (x: -size * 0.27, y: -size * 0.25, s: 9),
      (x: size * 0.24, y: -size * 0.34, s: 7),
      (x: size * 0.03, y: -size * 0.45, s: 5),
    ];

    return particles.asMap().entries.map((entry) {
      final i = entry.key;
      final bubble = entry.value;
      final pulse = (math.sin((tick * math.pi * 2) + i) + 1) / 2;
      return Positioned(
        left: size / 2 + bubble.x,
        top: size / 2 + bubble.y - pulse * 6,
        child: Opacity(
          opacity: 0.35 + pulse * 0.5,
          child: Container(
            width: bubble.s,
            height: bubble.s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ),
      );
    }).toList();
  }
}
