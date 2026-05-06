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
          const Positioned.fill(child: AnimatedBubbles()),
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
  const AnimatedBubbles({super.key});

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
    )..addListener(() {
        _updateBubbles();
      })
      ..repeat();
  }

  void _initBubbles(Size size) {
    if (_initialized) {
      return;
    }
    _cachedSize = size;
    _initialized = true;
    _bubbles.clear();
    
    // Create groups of bubbles
    for (int i = 0; i < 7; i++) {
      double groupX = _random.nextDouble() * size.width;
      double groupY = _random.nextDouble() * size.height;
      int bubblesInGroup = _random.nextInt(4) + 3; // 3 to 6 bubbles per group
      
      for (int j = 0; j < bubblesInGroup; j++) {
        _bubbles.add(Bubble(
          x: groupX + (_random.nextDouble() - 0.5) * 60,
          y: groupY + (_random.nextDouble() - 0.5) * 60,
          radius: _random.nextDouble() * 10 + 4,
          speed: _random.nextDouble() * 0.8 + 0.4,
          drift: (_random.nextDouble() - 0.5) * 0.3,
        ));
      }
    }
  }

  void _updateBubbles() {
    if (!mounted || !_initialized || _cachedSize.height == 0) return;
    
    setState(() {
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
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 0 && constraints.maxHeight > 0) {
          _initBubbles(Size(constraints.maxWidth, constraints.maxHeight));
        }
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _BubblePainter(_bubbles, Theme.of(context).brightness == Brightness.dark),
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
