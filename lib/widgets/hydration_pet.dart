import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

enum HydrationPetMood { happy, normal, tired }

class HydrationPet extends StatefulWidget {
  const HydrationPet({
    super.key,
    required this.mood,
    this.size = 140,
    this.speechMessage,
  });

  final HydrationPetMood mood;
  final double size;
  final String? speechMessage;

  @override
  State<HydrationPet> createState() => _HydrationPetState();
}

class _HydrationPetState extends State<HydrationPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _squishController;
  bool _isBlinking = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.0,
      upperBound: 0.25,
    );

    _startBlinkTimer();
  }

  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        setState(() {
          _isBlinking = true;
        });
        Future.delayed(const Duration(milliseconds: 180), () {
          if (mounted) {
            setState(() {
              _isBlinking = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _squishController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _squishController.forward().then((_) {
      _squishController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMood = widget.mood;

    final defaultSpeech = switch (effectiveMood) {
      HydrationPetMood.happy => '¡Hidratado y feliz! ✨',
      HydrationPetMood.normal => '¡Buen ritmo de agua! 💧',
      HydrationPetMood.tired => '¡Gotita tiene sed! 🏜️',
    };

    return AnimatedBuilder(
      animation: _squishController,
      builder: (context, child) {
        final squish = _squishController.value;
        final scaleX = 1.0 + squish;
        final scaleY = 1.0 - squish;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _handleTap,
              child: Transform.scale(
                scaleX: scaleX,
                scaleY: scaleY,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Ambient Bioluminescent Water Glow behind Gotita
                    Container(
                      width: widget.size * 1.25,
                      height: widget.size * 1.25,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: effectiveMood == HydrationPetMood.tired
                            ? Colors.orange.withValues(alpha: 0.10)
                            : AppTheme.primaryAqua.withValues(alpha: 0.25),
                        boxShadow: [
                          BoxShadow(
                            color: effectiveMood == HydrationPetMood.tired
                                ? Colors.orange.withValues(alpha: 0.15)
                                : AppTheme.primaryAqua.withValues(alpha: 0.35),
                            blurRadius: 36,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Sparkles Particle Layer
                    if (effectiveMood != HydrationPetMood.tired) ...[
                      const Positioned(
                        top: -12,
                        left: -16,
                        child: Opacity(
                          opacity: 0.85,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppTheme.primaryAquaDim,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: -6,
                        right: -14,
                        child: Opacity(
                          opacity: 0.90,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: AppTheme.primaryAqua,
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 24,
                        left: -20,
                        child: Opacity(
                          opacity: 0.80,
                          child: Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppTheme.tertiaryMintBright,
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 30,
                        right: -18,
                        child: Opacity(
                          opacity: 0.85,
                          child: Icon(
                            Icons.auto_awesome,
                            size: 15,
                            color: AppTheme.primaryAquaDim,
                          ),
                        ),
                      ),
                    ],
                      // Vector Body
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _GotitaPainter(
                          mood: effectiveMood,
                          isBlinking: _isBlinking,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dynamic Mood Speech Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHighest.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: effectiveMood == HydrationPetMood.tired
                        ? Colors.orange.withValues(alpha: 0.4)
                        : AppTheme.primaryAqua.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.speechMessage ?? defaultSpeech,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: effectiveMood == HydrationPetMood.tired
                        ? Colors.orangeAccent
                        : AppTheme.primaryAqua,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }


class _GotitaPainter extends CustomPainter {
  final HydrationPetMood mood;
  final bool isBlinking;

  _GotitaPainter({required this.mood, this.isBlinking = false});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // --- Droplet Path ---
    final path = Path();
    path.moveTo(width * 0.5, height * 0.08);
    path.cubicTo(
      width * 0.5,
      height * 0.08,
      width * 0.78,
      height * 0.46,
      width * 0.78,
      height * 0.66,
    );
    path.cubicTo(
      width * 0.78,
      height * 0.82,
      width * 0.65,
      height * 0.92,
      width * 0.5,
      height * 0.92,
    );
    path.cubicTo(
      width * 0.35,
      height * 0.92,
      width * 0.22,
      height * 0.82,
      width * 0.22,
      height * 0.66,
    );
    path.cubicTo(
      width * 0.22,
      height * 0.46,
      width * 0.5,
      height * 0.08,
      width * 0.5,
      height * 0.08,
    );
    path.close();

    final bodyGradient = switch (mood) {
      HydrationPetMood.happy => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA3E3FF), Color(0xFF38BDF8), Color(0xFF0284C7)],
      ),
      HydrationPetMood.normal => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF93C5FD), Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ),
      HydrationPetMood.tired => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF94A3B8), Color(0xFF64748B), Color(0xFF334155)],
      ),
    };

    final bodyPaint = Paint()
      ..shader = bodyGradient.createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    // Shadow
    canvas.drawShadow(
      path,
      AppTheme.primaryAqua.withValues(alpha: 0.5),
      12.0,
      true,
    );
    canvas.drawPath(path, bodyPaint);

    // Inner Rim Specular Highlight
    final highlightPath = Path();
    highlightPath.moveTo(width * 0.5, height * 0.12);
    highlightPath.cubicTo(
      width * 0.5,
      height * 0.12,
      width * 0.73,
      height * 0.47,
      width * 0.73,
      height * 0.64,
    );
    highlightPath.cubicTo(
      width * 0.73,
      height * 0.72,
      width * 0.70,
      height * 0.78,
      width * 0.66,
      height * 0.82,
    );

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(highlightPath, highlightPaint);

    // Dewdrop Crown Shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.49, height * 0.24), 3.2, shinePaint);

    // --- Face Details ---
    if (mood == HydrationPetMood.happy || mood == HydrationPetMood.normal) {
      // Rosy Blush Cheeks
      final blushPaint = Paint()
        ..color = const Color(0xFFFF97A3).withValues(alpha: 0.75)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(width * 0.33, height * 0.68),
          width: 10,
          height: 6,
        ),
        blushPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(width * 0.67, height * 0.68),
          width: 10,
          height: 6,
        ),
        blushPaint,
      );

      if (isBlinking) {
        // Blinking closed eye arcs
        final blinkPaint = Paint()
          ..color = const Color(0xFF002114)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round;

        final leftBlink = Path()
          ..moveTo(width * 0.34, height * 0.61)
          ..quadraticBezierTo(
            width * 0.38,
            height * 0.65,
            width * 0.42,
            height * 0.61,
          );
        final rightBlink = Path()
          ..moveTo(width * 0.58, height * 0.61)
          ..quadraticBezierTo(
            width * 0.62,
            height * 0.65,
            width * 0.66,
            height * 0.61,
          );

        canvas.drawPath(leftBlink, blinkPaint);
        canvas.drawPath(rightBlink, blinkPaint);
      } else {
        // Sparkly Eyes
        final eyePaint = Paint()
          ..color = const Color(0xFF002114)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(width * 0.38, height * 0.61), 4.5, eyePaint);
        canvas.drawCircle(Offset(width * 0.62, height * 0.61), 4.5, eyePaint);

        // Eye White Reflections
        final eyeReflect = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(width * 0.36, height * 0.59), 1.6, eyeReflect);
        canvas.drawCircle(Offset(width * 0.60, height * 0.59), 1.6, eyeReflect);
      }

      // Curved Smile
      final smilePath = Path();
      smilePath.moveTo(width * 0.42, height * 0.67);
      smilePath.quadraticBezierTo(
        width * 0.50,
        height * 0.75,
        width * 0.58,
        height * 0.67,
      );

      final smilePaint = Paint()
        ..color = const Color(0xFF002114)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(smilePath, smilePaint);
    } else {
      // Thirsty Sad Face
      final eyePaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      final leftEye = Path()
        ..moveTo(width * 0.33, height * 0.64)
        ..quadraticBezierTo(
          width * 0.38,
          height * 0.59,
          width * 0.43,
          height * 0.63,
        );
      final rightEye = Path()
        ..moveTo(width * 0.57, height * 0.63)
        ..quadraticBezierTo(
          width * 0.62,
          height * 0.59,
          width * 0.67,
          height * 0.64,
        );

      canvas.drawPath(leftEye, eyePaint);
      canvas.drawPath(rightEye, eyePaint);

      // Sad Downturned Mouth
      final sadMouth = Path()
        ..moveTo(width * 0.44, height * 0.73)
        ..quadraticBezierTo(
          width * 0.50,
          height * 0.68,
          width * 0.56,
          height * 0.73,
        );

      final mouthPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;


      canvas.drawPath(sadMouth, mouthPaint);

      // Sweat Drip
      final sweatPath = Path();
      sweatPath.moveTo(width * 0.72, height * 0.44);
      sweatPath.cubicTo(
        width * 0.72,
        height * 0.44,
        width * 0.75,
        height * 0.49,
        width * 0.75,
        height * 0.51,
      );
      sweatPath.cubicTo(
        width * 0.75,
        height * 0.53,
        width * 0.73,
        height * 0.54,
        width * 0.71,
        height * 0.54,
      );
      sweatPath.cubicTo(
        width * 0.69,
        height * 0.54,
        width * 0.67,
        height * 0.53,
        width * 0.67,
        height * 0.51,
      );
      sweatPath.close();

      final sweatPaint = Paint()
        ..color = const Color(0xFF7BD0FF)
        ..style = PaintingStyle.fill;
      canvas.drawPath(sweatPath, sweatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GotitaPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
