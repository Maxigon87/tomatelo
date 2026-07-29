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
      child: child,
    );
  }
}

class AnimatedBubbles extends StatelessWidget {
  final bool isActive;
  const AnimatedBubbles({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
      child: child,
    );
  }
}

class NutritionParticles extends StatelessWidget {
  final bool isActive;
  const NutritionParticles({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class MovementParticles extends StatelessWidget {
  final bool isActive;
  const MovementParticles({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
