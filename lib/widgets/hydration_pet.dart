import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tomatelo/models/pet_state.dart';

class HydrationPet extends StatefulWidget {
  const HydrationPet({
    super.key,
    required this.mood,
    this.size = 120,
    this.progress = 1.0,
  });

  final PetMood mood;
  final double size;
  final double progress;

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
      duration: const Duration(milliseconds: 2000),
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
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _GotaBotBody(
        key: ValueKey(widget.mood),
        mood: widget.mood,
        size: widget.size,
        progress: widget.progress,
        animation: _controller,
      ),
    );
  }
}

class _GotaBotBody extends StatelessWidget {
  const _GotaBotBody({
    super.key,
    required this.mood,
    required this.size,
    required this.progress,
    required this.animation,
  });

  final PetMood mood;
  final double size;
  final double progress;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    // Dynamic crystalline colors based on mood
    final baseColors = switch (mood) {
      PetMood.optimal => [const Color(0xFF00E5FF), const Color(0xFF00838F)],
      PetMood.alert => [const Color(0xFF80DEEA), const Color(0xFF0097A7)],
      PetMood.critical => [const Color(0xFFB0BEC5), const Color(0xFF37474F)],
    };

    final scaleFactor = 0.88 + (progress.clamp(0.0, 1.0) * 0.22);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final tick = animation.value;
        final floatY = switch (mood) {
          PetMood.optimal => math.sin(tick * math.pi * 2) * 5,
          PetMood.alert => math.sin(tick * math.pi * 2) * 3,
          PetMood.critical => math.sin(tick * math.pi * 2) * 1.5 + 2,
        };

        return Transform.scale(
          scale: scaleFactor,
          child: Transform.translate(
            offset: Offset(0, floatY),
            child: SizedBox(
              width: size,
              height: size + 20,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Outer Aquatic Glow Ring
                  if (mood == PetMood.optimal)
                    Container(
                      width: size * 1.05,
                      height: size * 1.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),

                  // Floating Water Bubbles (for optimal state)
                  if (mood == PetMood.optimal)
                    ..._GotaBotBubbles.build(size: size, tick: tick),

                  // Robot Water Drop Body
                  CustomPaint(
                    size: Size.square(size),
                    painter: _GotaBotPainter(colors: baseColors, mood: mood),
                  ),

                  // Digital Visor Screen (Gota-Bot Face)
                  Positioned(
                    top: size * 0.32,
                    child: _DigitalVisor(mood: mood, size: size),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GotaBotPainter extends CustomPainter {
  _GotaBotPainter({required this.colors, required this.mood});

  final List<Color> colors;
  final PetMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.22,
        size.width * 0.98,
        size.height * 0.65,
        size.width / 2,
        size.height,
      )
      ..cubicTo(
        size.width * 0.02,
        size.height * 0.65,
        size.width * 0.12,
        size.height * 0.22,
        size.width / 2,
        0,
      )
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, fillPaint);

    // Tech Glare & Glass Highlight Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: mood == PetMood.critical ? 0.2 : 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, borderPaint);

    // Glossy curved glare
    final glarePath = Path()
      ..moveTo(size.width * 0.40, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.32,
        size.width * 0.28,
        size.height * 0.52,
      );

    canvas.drawPath(
      glarePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GotaBotPainter oldDelegate) => true;
}

class _DigitalVisor extends StatelessWidget {
  const _DigitalVisor({required this.mood, required this.size});

  final PetMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final visorWidth = size * 0.58;
    final visorHeight = size * 0.28;

    return Container(
      width: visorWidth,
      height: visorHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mood == PetMood.optimal
              ? const Color(0xFF00E5FF)
              : mood == PetMood.alert
                  ? const Color(0xFFFFC107)
                  : const Color(0xFFE53935),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (mood == PetMood.optimal
                    ? const Color(0xFF00E5FF)
                    : mood == PetMood.alert
                        ? const Color(0xFFFFC107)
                        : const Color(0xFFE53935))
                .withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: _VisorExpression(mood: mood),
      ),
    );
  }
}

class _VisorExpression extends StatelessWidget {
  const _VisorExpression({required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    switch (mood) {
      case PetMood.optimal:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text('◠', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
            Text('◠', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        );
      case PetMood.alert:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text('•', style: TextStyle(color: Color(0xFFFFC107), fontSize: 20)),
            Text('•', style: TextStyle(color: Color(0xFFFFC107), fontSize: 20)),
          ],
        );
      case PetMood.critical:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text('x', style: TextStyle(color: Color(0xFFE53935), fontSize: 16, fontWeight: FontWeight.bold)),
            Text('x', style: TextStyle(color: Color(0xFFE53935), fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        );
    }
  }
}

class _GotaBotBubbles {
  static List<Widget> build({required double size, required double tick}) {
    final particles = [
      (x: -size * 0.3, y: -size * 0.15, size: 8.0),
      (x: size * 0.28, y: -size * 0.25, size: 10.0),
      (x: size * 0.04, y: -size * 0.38, size: 6.0),
    ];

    return particles.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final offset = math.sin((tick * math.pi * 2) + i) * 6;
      return Positioned(
        left: size / 2 + p.x,
        top: size / 2 + p.y - offset,
        child: Container(
          width: p.size,
          height: p.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE0F7FA).withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
