import 'dart:math';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color secondaryAqua = Color(0xFF4FC3F7);
  static const Color accentLightBlue = Color(0xFF81D4FA);

  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: secondaryAqua,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.82),
        elevation: 6,
        shadowColor: primaryBlue.withValues(alpha: 0.20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.86),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: secondaryAqua.withValues(alpha: 0.35)),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF64B5F6),
      secondary: const Color(0xFF4DD0E1),
      surface: const Color(0xFF0A2238),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: const Color(0xFF102A43).withValues(alpha: 0.85),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class WaterBackground extends StatelessWidget {
  final Widget child;

  const WaterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF071726), Color(0xFF0E3658), Color(0xFF164A73)]
              : const [Color(0xFFEFF8FF), Color(0xFFDDF2FF), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: AnimatedBubbles(isActive: true)),
          child,
        ],
      ),
    );
  }
}

class Bubble {
  double x;
  double y;
  double radius;
  double speed;
  double drift;
  
  Bubble({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.drift,
  });
}

class AnimatedBubbles extends StatefulWidget {
  final bool isActive;
  const AnimatedBubbles({super.key, this.isActive = true});

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();
  bool _initialized = false;
  Size _cachedSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedBubbles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  void _initBubbles(Size size) {
    if (_initialized) {
      return;
    }
    _cachedSize = size;
    _initialized = true;
    _bubbles.clear();
    
    // Create fewer groups for better performance
    for (int i = 0; i < 4; i++) {
      double groupX = _random.nextDouble() * size.width;
      double groupY = _random.nextDouble() * size.height;
      int bubblesInGroup = _random.nextInt(3) + 2; // 2 to 4 bubbles per group
      
      for (int j = 0; j < bubblesInGroup; j++) {
        _bubbles.add(Bubble(
          x: groupX + (_random.nextDouble() - 0.5) * 60,
          y: groupY + (_random.nextDouble() - 0.5) * 60,
          radius: _random.nextDouble() * 12 + 4,
          speed: _random.nextDouble() * 0.7 + 0.3,
          drift: (_random.nextDouble() - 0.5) * 0.2,
        ));
      }
    }
  }

  void _updateBubbles() {
    if (!_initialized || _cachedSize.height == 0) return;
    
    for (var bubble in _bubbles) {
      bubble.y -= bubble.speed;
      bubble.x += bubble.drift;
      
      // Add a slight sine wave drift to make it look like water
      bubble.x += sin(bubble.y * 0.015) * 0.4;

      // Reset if it goes off screen (to the bottom, as if coming from below)
      if (bubble.y < -50) {
        bubble.y = _cachedSize.height + 50;
        bubble.x = _random.nextDouble() * _cachedSize.width;
      }
      
      // Wrap horizontally
      if (bubble.x < -50) bubble.x = _cachedSize.width + 50;
      if (bubble.x > _cachedSize.width + 50) bubble.x = -50;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
          _initBubbles(Size(constraints.maxWidth, constraints.maxHeight));
        }
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            _updateBubbles();
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _BubblePainter(_bubbles, isDark),
            );
          },
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final bool isDark;

  _BubblePainter(this.bubbles, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF4FC3F7)).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = (isDark ? Colors.white : const Color(0xFF4FC3F7)).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var bubble in bubbles) {
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, paint);
      canvas.drawCircle(Offset(bubble.x, bubble.y), bubble.radius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}

class NutritionBackground extends StatelessWidget {
  final Widget child;

  const NutritionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF101F13), Color(0xFF27451F), Color(0xFF5B3A16)]
              : const [Color(0xFFF4FFE8), Color(0xFFFFF2CC), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: NutritionParticles(isActive: true)),
          child,
        ],
      ),
    );
  }
}

class NutritionParticles extends StatefulWidget {
  final bool isActive;
  const NutritionParticles({super.key, this.isActive = true});

  @override
  State<NutritionParticles> createState() => _NutritionParticlesState();
}

class _NutritionParticlesState extends State<NutritionParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<TextPainter> _painters = [];
  final fruits = ['🍎', '🍌', '🍓', '🍊', '🥝', '🍇', '🍐'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    for (final fruit in fruits) {
      final tp = TextPainter(
        text: TextSpan(
          text: fruit,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _painters.add(tp);
    }

    if (widget.isActive) _controller.repeat();
  }

  @override
  void didUpdateWidget(NutritionParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        painter: NutritionParticlesPainter(_controller.value, _painters),
        size: Size.infinite,
      ),
    );
  }
}

class NutritionParticlesPainter extends CustomPainter {
  const NutritionParticlesPainter(this.tick, this.painters);

  final double tick;
  final List<TextPainter> painters;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 8; i++) {
      final progress = (tick + i * 0.12) % 1;
      final x = (size.width * ((i * 47) % 100) / 100) +
          sin(progress * pi * 2 + i) * 15;
      final y = -40 + (size.height + 80) * progress;
      
      final tp = painters[i % painters.length];
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * pi * 0.4);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant NutritionParticlesPainter oldDelegate) =>
      oldDelegate.tick != tick;
}
