import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tomatelo/models/pet_state.dart';

class NutritionPet extends StatefulWidget {
  const NutritionPet({
    super.key,
    required this.mood,
    this.progress = 1.0,
    this.size = 115,
  });

  final PetMood mood;
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
      duration: const Duration(milliseconds: 2200),
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
      child: _BrotoBody(
        key: ValueKey(widget.mood),
        mood: widget.mood,
        progress: widget.progress,
        size: widget.size,
        animation: _controller,
      ),
    );
  }
}

class _BrotoBody extends StatelessWidget {
  const _BrotoBody({
    super.key,
    required this.mood,
    required this.progress,
    required this.size,
    required this.animation,
  });

  final PetMood mood;
  final double progress;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final bodyColors = switch (mood) {
      PetMood.optimal => [const Color(0xFF66BB6A), const Color(0xFF2E7D32)],
      PetMood.alert => [const Color(0xFFAED581), const Color(0xFF558B2F)],
      PetMood.critical => [const Color(0xFF8D6E63), const Color(0xFF4E3D30)],
    };

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final tick = animation.value;
        final floatY = math.sin(tick * math.pi * 2) * 4;
        final tilt = math.sin(tick * math.pi * 2) * 0.03;

        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.rotate(
            angle: tilt,
            child: SizedBox(
              width: size + 20,
              height: size + 35,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Aura glow for optimal healthy state
                  if (mood == PetMood.optimal)
                    Container(
                      width: size * 0.95,
                      height: size * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                            blurRadius: 22,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),

                  // Floating Nature Leaves
                  if (mood == PetMood.optimal)
                    ..._BrotoLeaves.build(size: size, tick: tick),

                  // Head Sprout / Flower on Top
                  Positioned(
                    top: -size * 0.12,
                    child: _SproutHead(mood: mood, size: size, tick: tick),
                  ),

                  // Broto Round Body
                  Positioned(
                    bottom: 10,
                    child: Container(
                      width: size * 0.88,
                      height: size * 0.82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: bodyColors,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bodyColors.last.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Belly Patch
                          Positioned(
                            bottom: 10,
                            child: Container(
                              width: size * 0.52,
                              height: size * 0.44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          // Face
                          Positioned(
                            top: size * 0.24,
                            child: _BrotoFace(mood: mood),
                          ),
                        ],
                      ),
                    ),
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

class _SproutHead extends StatelessWidget {
  const _SproutHead({
    required this.mood,
    required this.size,
    required this.tick,
  });

  final PetMood mood;
  final double size;
  final double tick;

  @override
  Widget build(BuildContext context) {
    final sproutAngle = switch (mood) {
      PetMood.optimal => math.sin(tick * math.pi * 2) * 0.1,
      PetMood.alert => -0.2,
      PetMood.critical => -0.45,
    };

    return Transform.rotate(
      angle: sproutAngle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood == PetMood.optimal ? '🌸' : mood == PetMood.alert ? '🌱' : '🥀',
                style: TextStyle(fontSize: size * 0.34),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrotoFace extends StatelessWidget {
  const _BrotoFace({required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
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

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    if (mood == PetMood.optimal) {
      return Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 8,
      height: mood == PetMood.critical ? 3 : 8,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Mouth extends StatelessWidget {
  const _Mouth({required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    return switch (mood) {
      PetMood.optimal => const Text('v', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      PetMood.alert => Container(width: 12, height: 3, color: Colors.white70),
      PetMood.critical => const Text('m', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11)),
    };
  }
}

class _BrotoLeaves {
  static List<Widget> build({required double size, required double tick}) {
    final particles = ['🍃', '🌿', '✨'];
    return List.generate(particles.length, (index) {
      final angle = (index / particles.length) * math.pi * 2 + tick * 0.5;
      final dx = math.cos(angle) * (size * 0.42);
      final dy = math.sin(angle) * (size * 0.3);
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Text(
          particles[index],
          style: TextStyle(fontSize: 16 + (index * 2)),
        ),
      );
    });
  }
}
