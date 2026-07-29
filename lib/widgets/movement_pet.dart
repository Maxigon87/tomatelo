import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MovementPetMood { bored, walking, happy }

class MovementPet extends StatefulWidget {
  const MovementPet({
    super.key,
    required this.mood,
    this.size = 112,
  });

  final MovementPetMood mood;
  final double size;

  @override
  State<MovementPet> createState() => _MovementPetState();
}

class _MovementPetState extends State<MovementPet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Speed adjustments depending on state
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void didUpdateWidget(MovementPet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood != oldWidget.mood) {
      if (widget.mood == MovementPetMood.happy) {
        _controller.duration = const Duration(milliseconds: 900);
      } else if (widget.mood == MovementPetMood.walking) {
        _controller.duration = const Duration(milliseconds: 1000);
      } else {
        _controller.duration = const Duration(milliseconds: 2000);
      }
      _controller.repeat();
    }
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
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: _PetAnimationBody(
        key: ValueKey(widget.mood),
        mood: widget.mood,
        size: widget.size,
        animation: _controller,
      ),
    );
  }
}

class _PetAnimationBody extends StatelessWidget {
  const _PetAnimationBody({
    super.key,
    required this.mood,
    required this.size,
    required this.animation,
  });

  final MovementPetMood mood;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final tick = animation.value;

        // Kinematics calculations for animation states
        double bodyY = 0;
        double bodyRotation = 0;
        double leftLegAngle = 0;
        double rightLegAngle = 0;
        double leftArmAngle = 0;
        double rightArmAngle = 0;
        double leftLegY = 0;
        double rightLegY = 0;

        if (mood == MovementPetMood.bored) {
          // Slow breathing
          bodyY = math.sin(tick * math.pi * 2) * 2.5;
        } else if (mood == MovementPetMood.walking) {
          // Bobbing double frequency (down when legs pass/spread)
          bodyY = math.sin(tick * math.pi * 4) * 4.0;
          bodyRotation = math.sin(tick * math.pi * 2) * 0.05;

          // Leg swings
          leftLegAngle = math.sin(tick * math.pi * 2) * 0.45;
          rightLegAngle = -math.sin(tick * math.pi * 2) * 0.45;

          // Arm swings opposite to legs
          leftArmAngle = -math.sin(tick * math.pi * 2) * 0.5;
          rightArmAngle = math.sin(tick * math.pi * 2) * 0.5;
        } else if (mood == MovementPetMood.happy) {
          // Jumping up & down
          final jumpProgress = math.sin(tick * math.pi);
          bodyY = jumpProgress > 0 ? -jumpProgress * 22.0 : 0;
          bodyRotation = math.sin(tick * math.pi * 2) * 0.08;

          // Happy leg kicks
          leftLegAngle = math.sin(tick * math.pi * 4) * 0.15;
          rightLegAngle = -math.sin(tick * math.pi * 4) * 0.15;

          if (bodyY < -5) {
            leftLegY = 3.0;
            rightLegY = 1.0;
          }

          // Arms raised cheering
          leftArmAngle = 2.4 + math.sin(tick * math.pi * 4) * 0.2;
          rightArmAngle = -2.4 - math.sin(tick * math.pi * 4) * 0.2;
        }

        return SizedBox(
          width: size + 40,
          height: size + 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Sitting bench if bored
              if (mood == MovementPetMood.bored)
                Positioned(
                  bottom: 12,
                  child: CustomPaint(
                    size: Size(size * 1.1, size * 0.35),
                    painter: _BenchPainter(),
                  ),
                ),

              // Character drawing containing body, legs, arms, face
              Positioned(
                bottom: 22,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      // Legs
                      Positioned(
                        bottom: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.translate(
                              offset: Offset(-size * 0.18, leftLegY),
                              child: Transform.rotate(
                                angle: leftLegAngle,
                                origin: const Offset(0, -10),
                                child: CustomPaint(
                                  size: Size(size * 0.14, size * 0.32),
                                  painter: _LimbsPainter(
                                    isArm: false,
                                    isSitting: mood == MovementPetMood.bored,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.translate(
                              offset: Offset(size * 0.18, rightLegY),
                              child: Transform.rotate(
                                angle: rightLegAngle,
                                origin: const Offset(0, -10),
                                child: CustomPaint(
                                  size: Size(size * 0.14, size * 0.32),
                                  painter: _LimbsPainter(
                                    isArm: false,
                                    isSitting: mood == MovementPetMood.bored,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arms & Body container (for bobbing & rotation)
                      Positioned(
                        bottom: size * 0.16,
                        child: Transform.translate(
                          offset: Offset(0, bodyY),
                          child: Transform.rotate(
                            angle: bodyRotation,
                            child: SizedBox(
                              width: size * 0.88,
                              height: size * 0.74,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Left Arm
                                  Positioned(
                                    left: -size * 0.08,
                                    top: size * 0.28,
                                    child: Transform.rotate(
                                      angle: leftArmAngle,
                                      origin: const Offset(8, -6),
                                      child: CustomPaint(
                                        size: Size(size * 0.14, size * 0.38),
                                        painter: _LimbsPainter(isArm: true, isSitting: false),
                                      ),
                                    ),
                                  ),

                                  // Right Arm
                                  Positioned(
                                    right: -size * 0.08,
                                    top: size * 0.28,
                                    child: Transform.rotate(
                                      angle: rightArmAngle,
                                      origin: const Offset(-8, -6),
                                      child: CustomPaint(
                                        size: Size(size * 0.14, size * 0.38),
                                        painter: _LimbsPainter(isArm: true, isSitting: false),
                                      ),
                                    ),
                                  ),

                                  // Body
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _BodyPainter(mood: mood),
                                    ),
                                  ),

                                  // Face
                                  Positioned(
                                    top: size * 0.24,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: _PetFace(mood: mood, size: size),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Zzz sleep bubbles
  List<Widget> _buildZzz(double size, double tick) {
    final particles = [
      (x: -size * 0.35, y: -size * 0.25, size: 13.0, delay: 0.0),
      (x: -size * 0.22, y: -size * 0.42, size: 17.0, delay: 0.33),
      (x: -size * 0.42, y: -size * 0.58, size: 22.0, delay: 0.66),
    ];

    return particles.map((p) {
      final progress = (tick + p.delay) % 1.0;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final floatY = -progress * 25.0;
      final floatX = math.sin(progress * math.pi * 2) * 5.0;

      return Positioned(
        left: size / 2 + p.x + floatX,
        top: size / 2 + p.y + floatY,
        child: Opacity(
          opacity: opacity * 0.75,
          child: Text(
            'Z',
            style: TextStyle(
              fontSize: p.size * (0.6 + progress * 0.5),
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade200,
            ),
          ),
        ),
      );
    }).toList();
  }

  // Floating celebration stars
  List<Widget> _buildStars(double size, double tick) {
    final particles = [
      (x: -size * 0.48, y: -size * 0.34, emoji: '⭐', size: 18.0, delay: 0.0),
      (x: size * 0.44, y: -size * 0.44, emoji: '✨', size: 16.0, delay: 0.25),
      (x: -size * 0.12, y: -size * 0.62, emoji: '🌟', size: 20.0, delay: 0.5),
      (x: size * 0.38, y: -size * 0.10, emoji: '✨', size: 14.0, delay: 0.75),
    ];

    return particles.map((p) {
      final progress = (tick + p.delay) % 1.0;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final floatY = -progress * 28.0;
      final floatX = math.cos(progress * math.pi * 2) * 4.0;

      return Positioned(
        left: size / 2 + p.x + floatX,
        top: size / 2 + p.y + floatY,
        child: Opacity(
          opacity: opacity,
          child: Text(
            p.emoji,
            style: TextStyle(
              fontSize: p.size,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _PetFace extends StatelessWidget {
  const _PetFace({required this.mood, required this.size});

  final MovementPetMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.5,
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
          const SizedBox(height: 6),
          _Mouth(mood: mood),
        ],
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye({required this.mood});

  final MovementPetMood mood;

  @override
  Widget build(BuildContext context) {
    if (mood == MovementPetMood.happy) {
      // ^ ^ squint
      return CustomPaint(
        size: const Size(12, 8),
        painter: _ArcPainter(strokeWidth: 3, flip: false),
      );
    } else if (mood == MovementPetMood.bored) {
      // - - lines
      return Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else {
      // standard dots
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
      );
    }
  }
}

class _Mouth extends StatelessWidget {
  const _Mouth({required this.mood});

  final MovementPetMood mood;

  @override
  Widget build(BuildContext context) {
    if (mood == MovementPetMood.happy) {
      // Big open smile
      return CustomPaint(
        size: const Size(16, 9),
        painter: _ArcPainter(strokeWidth: 3, flip: true),
      );
    } else if (mood == MovementPetMood.bored) {
      // Small yawning circle
      return Container(
        width: 8,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.black54, width: 2.2),
          shape: BoxShape.circle,
        ),
      );
    } else {
      // Gentle smile
      return CustomPaint(
        size: const Size(14, 6),
        painter: _ArcPainter(strokeWidth: 2.5, flip: true),
      );
    }
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.strokeWidth, required this.flip});

  final double strokeWidth;
  final bool flip;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (flip) {
      // U-shape smile
      path.moveTo(0, 0);
      path.quadraticBezierTo(size.width / 2, size.height * 1.5, size.width, 0);
    } else {
      // ^-shape arches
      path.moveTo(0, size.height);
      path.quadraticBezierTo(size.width / 2, -size.height * 0.5, size.width, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => false;
}

class _BodyPainter extends CustomPainter {
  const _BodyPainter({required this.mood});

  final MovementPetMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.44));

    // Base body color gradient: sunset gold / energetic orange
    final bodyColors = switch (mood) {
      MovementPetMood.happy => [const Color(0xFFFF9E00), const Color(0xFFFF6D00)],
      MovementPetMood.walking => [const Color(0xFFF77F00), const Color(0xFFD62828)],
      MovementPetMood.bored => [const Color(0xFFE29578), const Color(0xFF83C5BE)],
    };

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: bodyColors,
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);

    // Subtle glassmorphism highlight border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawRRect(rrect, borderPaint);

    // Glare circle on top left
    final glarePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.24), size.width * 0.08, glarePaint);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) => oldDelegate.mood != mood;
}

class _LimbsPainter extends CustomPainter {
  const _LimbsPainter({required this.isArm, required this.isSitting});

  final bool isArm;
  final bool isSitting;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4A4E69)
      ..style = PaintingStyle.fill;

    if (isSitting && !isArm) {
      // Sitting legs are drawn horizontal (projecting out)
      final rect = Rect.fromLTWH(0, 0, size.height, size.width);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.5));
      canvas.drawRRect(rrect, paint);
    } else {
      // Standard vertical pill shape
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.5));
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LimbsPainter oldDelegate) => false;
}

class _BenchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final woodPaint = Paint()
      ..color = const Color(0xFF8D5B4C)
      ..style = PaintingStyle.fill;

    final legPaint = Paint()
      ..color = const Color(0xFF4E3D30)
      ..style = PaintingStyle.fill;

    // Legs
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.35, 10, size.height * 0.65), legPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.75, size.height * 0.35, 10, size.height * 0.65), legPaint);

    // Plank
    final plankRect = Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.25);
    final rplank = RRect.fromRectAndRadius(plankRect, const Radius.circular(4));
    canvas.drawRRect(rplank, woodPaint);
  }

  @override
  bool shouldRepaint(covariant _BenchPainter oldDelegate) => false;
}
