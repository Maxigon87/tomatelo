import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tomatelo/models/pet_state.dart';

class MovementPet extends StatefulWidget {
  const MovementPet({
    super.key,
    required this.mood,
    this.size = 115,
  });

  final PetMood mood;
  final double size;

  @override
  State<MovementPet> createState() => _MovementPetState();
}

class _MovementPetState extends State<MovementPet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void didUpdateWidget(MovementPet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood != oldWidget.mood) {
      if (widget.mood == PetMood.optimal) {
        _controller.duration = const Duration(milliseconds: 750);
      } else if (widget.mood == PetMood.alert) {
        _controller.duration = const Duration(milliseconds: 1300);
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
      duration: const Duration(milliseconds: 400),
      child: _ZorroVelozBody(
        key: ValueKey(widget.mood),
        mood: widget.mood,
        size: widget.size,
        animation: _controller,
      ),
    );
  }
}

class _ZorroVelozBody extends StatelessWidget {
  const _ZorroVelozBody({
    super.key,
    required this.mood,
    required this.size,
    required this.animation,
  });

  final PetMood mood;
  final double size;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = switch (mood) {
      PetMood.optimal => [const Color(0xFFFF5722), const Color(0xFFE64A19)],
      PetMood.alert => [const Color(0xFFFF9800), const Color(0xFFF57C00)],
      PetMood.critical => [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
    };

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final tick = animation.value;

        double bodyY = 0;
        double bodyRotation = 0;
        if (mood == PetMood.optimal) {
          bodyY = -math.sin(tick * math.pi * 2).abs() * 12;
          bodyRotation = math.sin(tick * math.pi * 2) * 0.08;
        } else if (mood == PetMood.alert) {
          bodyY = math.sin(tick * math.pi * 2) * 3;
        } else {
          bodyY = 4;
        }

        return SizedBox(
          width: size + 30,
          height: size + 30,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Energy Aura for Optimal State
              if (mood == PetMood.optimal)
                Container(
                  width: size * 0.95,
                  height: size * 0.95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.45),
                        blurRadius: 26,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),

              // Speed Sparks / Stars
              if (mood == PetMood.optimal)
                ..._SpeedSparks.build(size: size, tick: tick),

              // Zorro Body
              Transform.translate(
                offset: Offset(0, bodyY),
                child: Transform.rotate(
                  angle: bodyRotation,
                  child: Container(
                    width: size * 0.88,
                    height: size * 0.85,
                    decoration: BoxDecoration(
                      color: colors.first,
                      borderRadius: BorderRadius.circular(size * 0.42),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: colors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.last.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Fox Ears on Top
                        Positioned(
                          top: -6,
                          left: size * 0.1,
                          right: size * 0.1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [_Ear(), _Ear()],
                          ),
                        ),

                        // Athletic Headband
                        Positioned(
                          top: size * 0.22,
                          child: Container(
                            width: size * 0.86,
                            height: 12,
                            decoration: BoxDecoration(
                              color: mood == PetMood.optimal
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),

                        // White Muzzle / Chest
                        Positioned(
                          bottom: 6,
                          child: Container(
                            width: size * 0.54,
                            height: size * 0.38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),

                        // Face
                        Positioned(
                          top: size * 0.36,
                          child: _ZorroFace(mood: mood),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Ear extends StatelessWidget {
  const _Ear();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFD84315),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
    );
  }
}

class _ZorroFace extends StatelessWidget {
  const _ZorroFace({required this.mood});

  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
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
      return const Text('⚡', style: TextStyle(fontSize: 12));
    } else if (mood == PetMood.alert) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.black87,
          shape: BoxShape.circle,
        ),
      );
    }
    return Container(
      width: 10,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(2),
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
      PetMood.optimal => const Text('▲', style: TextStyle(color: Colors.black87, fontSize: 10)),
      PetMood.alert => Container(width: 10, height: 2, color: Colors.black87),
      PetMood.critical => const Text('💦', style: TextStyle(fontSize: 10)),
    };
  }
}

class _SpeedSparks {
  static List<Widget> build({required double size, required double tick}) {
    final particles = ['⚡', '🔥', '⭐'];
    return List.generate(particles.length, (index) {
      final angle = (index / particles.length) * math.pi * 2 + tick * 0.8;
      final dx = math.cos(angle) * (size * 0.44);
      final dy = math.sin(angle) * (size * 0.32);
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Text(
          particles[index],
          style: const TextStyle(fontSize: 18),
        ),
      );
    });
  }
}
