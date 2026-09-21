import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

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
  final _random = math.Random();
  late List<_ParticleData> _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(8, (index) => _generateParticle());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isVisible = false;
          });
        }
      });
  }

  _ParticleData _generateParticle() {
    final angle = _random.nextDouble() * math.pi * 2;
    final speed = 80 + _random.nextDouble() * 120;
    final size = 16.0 + _random.nextDouble() * 18.0;
    return _ParticleData(
      dx: math.cos(angle) * speed,
      dy: math.sin(angle) * speed - 60,
      size: size,
      icon: _random.nextBool()
          ? Icons.water_drop_rounded
          : Icons.auto_awesome_rounded,
    );
  }

  @override
  void didUpdateWidget(covariant DropletAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      setState(() {
        _particles = List.generate(8, (index) => _generateParticle());
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
          final t = Curves.decelerate.transform(_controller.value);
          final opacity = (1.0 - _controller.value).clamp(0.0, 1.0);

          return Stack(
            alignment: Alignment.center,
            children: [
              for (final p in _particles)
                Positioned(
                  left: (MediaQuery.of(context).size.width / 2) + (p.dx * t) - (p.size / 2),
                  top: (MediaQuery.of(context).size.height * 0.35) + (p.dy * t) + (t * t * 80),
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: (1.2 - t * 0.5).clamp(0.2, 1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryAqua.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          p.icon,
                          size: p.size,
                          color: AppTheme.primaryAqua,
                        ),
                      ),
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

class _ParticleData {
  final double dx;
  final double dy;
  final double size;
  final IconData icon;

  _ParticleData({
    required this.dx,
    required this.dy,
    required this.size,
    required this.icon,
  });
}



