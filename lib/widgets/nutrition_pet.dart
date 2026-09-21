import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

enum NutritionPetMood { happy, normal, tired }

class NutritionPet extends StatefulWidget {
  const NutritionPet({
    super.key,
    required this.mood,
    this.progress = 0.0,
    this.size = 130,
    this.speechMessage,
  });

  final NutritionPetMood mood;
  final double progress;
  final double size;
  final String? speechMessage;

  @override
  State<NutritionPet> createState() => _NutritionPetState();
}

class _NutritionPetState extends State<NutritionPet>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _squishController;
  bool _overrideTired = false;
  bool _isBlinking = false;
  Timer? _blinkTimer;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _squishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      lowerBound: 0.0,
      upperBound: 0.22,
    );

    _startBlinkTimer();
  }

  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
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
    _floatController.dispose();
    _squishController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _squishController.forward().then((_) {
      _squishController.reverse();
    });
    setState(() {
      _overrideTired = !_overrideTired;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMood = _overrideTired
        ? NutritionPetMood.tired
        : widget.mood;

    final defaultSpeech = switch (effectiveMood) {
      NutritionPetMood.happy => '¡Nutrido y con energía! ✨',
      NutritionPetMood.normal => '¡Vas por buen camino! 🍎',
      NutritionPetMood.tired => '¡Suma una frutita fresca! 🥑',
    };

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _squishController]),
      builder: (context, child) {
        final tick = _floatController.value;
        final floatOffset = math.sin(tick * math.pi * 2) * 4.5;
        final breathe = 1.0 + math.sin(tick * math.pi) * 0.02;

        final squish = _squishController.value;
        final scaleX = breathe * (1.0 + squish);
        final scaleY = breathe * (1.0 - squish);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scaleX: scaleX,
            scaleY: scaleY,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _handleTap,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Ambient Glow behind Manzanita
                      Container(
                        width: widget.size * (1.15 + tick * 0.06),
                        height: widget.size * (1.15 + tick * 0.06),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.secondaryCoral.withValues(
                            alpha: 0.18 + (tick * 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryCoral.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 30 + (tick * 10),
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: Size(widget.size, widget.size),
                        painter: _ManzanitaPainter(
                          mood: effectiveMood,
                          isBlinking: _isBlinking,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mood Badge Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHighest.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppTheme.tertiaryMint.withValues(alpha: 0.35),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sentiment_satisfied_rounded,
                            size: 14,
                            color: AppTheme.tertiaryMintBright,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.speechMessage ?? defaultSpeech,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.tertiaryMintBright,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Quick interactive toggle button
                    InkWell(
                      onTap: _handleTap,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppTheme.surfaceHighest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _ManzanitaPainter extends CustomPainter {
  final NutritionPetMood mood;
  final bool isBlinking;

  _ManzanitaPainter({required this.mood, this.isBlinking = false});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // --- Stem ---
    final stemPath = Path();
    stemPath.moveTo(width * 0.50, height * 0.20);
    stemPath.cubicTo(
      width * 0.50,
      height * 0.10,
      width * 0.49,
      height * 0.07,
      width * 0.57,
      height * 0.07,
    );

    final stemPaint = Paint()
      ..color = const Color(0xFF84532D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(stemPath, stemPaint);

    // --- Fresh Green Leaf ---
    final leafPath = Path();
    leafPath.moveTo(width * 0.51, height * 0.14);
    leafPath.cubicTo(
      width * 0.55,
      height * 0.10,
      width * 0.63,
      height * 0.08,
      width * 0.67,
      height * 0.11,
    );
    leafPath.cubicTo(
      width * 0.68,
      height * 0.15,
      width * 0.65,
      height * 0.21,
      width * 0.53,
      height * 0.18,
    );
    leafPath.close();

    final leafPaint = Paint()
      ..color = const Color(0xFF4EE6AA)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leafPath, leafPaint);

    // --- Apple Body Path ---
    final applePath = Path();
    applePath.moveTo(width * 0.50, height * 0.24);
    applePath.cubicTo(
      width * 0.34,
      height * 0.24,
      width * 0.18,
      height * 0.31,
      width * 0.18,
      height * 0.52,
    );
    applePath.cubicTo(
      width * 0.18,
      height * 0.74,
      width * 0.33,
      height * 0.89,
      width * 0.44,
      height * 0.90,
    );
    applePath.cubicTo(
      width * 0.49,
      height * 0.90,
      width * 0.50,
      height * 0.88,
      width * 0.50,
      height * 0.88,
    );
    applePath.cubicTo(
      width * 0.50,
      height * 0.88,
      width * 0.51,
      height * 0.90,
      width * 0.56,
      height * 0.90,
    );
    applePath.cubicTo(
      width * 0.67,
      height * 0.89,
      width * 0.82,
      height * 0.74,
      width * 0.82,
      height * 0.52,
    );
    applePath.cubicTo(
      width * 0.82,
      height * 0.31,
      width * 0.66,
      height * 0.24,
      width * 0.50,
      height * 0.24,
    );
    applePath.close();

    final appleGradient = switch (mood) {
      NutritionPetMood.happy => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF5C75), Color(0xFFDE2A48), Color(0xFF9E142B)],
      ),
      NutritionPetMood.normal => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF7E92), Color(0xFFE5405C), Color(0xFFB51A34)],
      ),
      NutritionPetMood.tired => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFC56D7A), Color(0xFF8F3E4C), Color(0xFF541B24)],
      ),
    };

    final applePaint = Paint()
      ..shader = appleGradient.createShader(
        Rect.fromLTWH(0, 0, width, height),
      )
      ..style = PaintingStyle.fill;

    canvas.drawShadow(
      applePath,
      AppTheme.secondaryCoral.withValues(alpha: 0.4),
      10.0,
      true,
    );
    canvas.drawPath(applePath, applePaint);

    // --- Specular Highlight ---
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.34, height * 0.36),
        width: width * 0.20,
        height: height * 0.10,
      ),
      highlightPaint,
    );

    // --- Cheeks ---
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8393).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(width * 0.31, height * 0.56), 6.5, blushPaint);
    canvas.drawCircle(Offset(width * 0.69, height * 0.56), 6.5, blushPaint);

    // --- Face Expression ---
    if (mood == NutritionPetMood.happy || mood == NutritionPetMood.normal) {
      if (isBlinking) {
        final blinkPaint = Paint()
          ..color = const Color(0xFF1A050B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;

        final leftBlink = Path()
          ..moveTo(width * 0.33, height * 0.46)
          ..quadraticBezierTo(
            width * 0.37,
            height * 0.50,
            width * 0.41,
            height * 0.46,
          );
        final rightBlink = Path()
          ..moveTo(width * 0.59, height * 0.46)
          ..quadraticBezierTo(
            width * 0.63,
            height * 0.50,
            width * 0.67,
            height * 0.46,
          );

        canvas.drawPath(leftBlink, blinkPaint);
        canvas.drawPath(rightBlink, blinkPaint);
      } else {
        // Curved Happy Eyes
        final eyePaint = Paint()
          ..color = const Color(0xFF1A050B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;

        final leftEye = Path()
          ..moveTo(width * 0.33, height * 0.48)
          ..quadraticBezierTo(
            width * 0.37,
            height * 0.43,
            width * 0.41,
            height * 0.48,
          );
        final rightEye = Path()
          ..moveTo(width * 0.59, height * 0.48)
          ..quadraticBezierTo(
            width * 0.63,
            height * 0.43,
            width * 0.67,
            height * 0.48,
          );

        canvas.drawPath(leftEye, eyePaint);
        canvas.drawPath(rightEye, eyePaint);
      }

      // Happy Smile
      final smile = Path()
        ..moveTo(width * 0.44, height * 0.54)
        ..quadraticBezierTo(
          width * 0.50,
          height * 0.62,
          width * 0.56,
          height * 0.54,
        );

      final smilePaint = Paint()
        ..color = const Color(0xFF1A050B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(smile, smilePaint);
    } else {

      // Sad Eyes
      final eyePaint = Paint()
        ..color = const Color(0xFF1A050B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(width * 0.36, height * 0.48), 3.0, eyePaint);
      canvas.drawCircle(Offset(width * 0.64, height * 0.48), 3.0, eyePaint);

      // Sad Mouth
      final sadMouth = Path()
        ..moveTo(width * 0.45, height * 0.58)
        ..quadraticBezierTo(
          width * 0.50,
          height * 0.53,
          width * 0.55,
          height * 0.58,
        );

      final mouthPaint = Paint()
        ..color = const Color(0xFF1A050B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(sadMouth, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ManzanitaPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
