import 'package:flutter/material.dart';

class AppTheme {
  // --- Dynamic Color Identity Tokens ---
  // Hydration (Agua) - Cyan / Bright Blue
  static const Color hydrationPrimary = Color(0xFF00BCD4);
  static const Color hydrationSecondary = Color(0xFF0288D1);
  static const Color hydrationDark = Color(0xFF006064);
  static const Color hydrationContainerLight = Color(0xFFE0F7FA);

  // Nutrition (Frutas/Comida) - Organic Vibrant Green
  static const Color nutritionPrimary = Color(0xFF4CAF50);
  static const Color nutritionSecondary = Color(0xFF388E3C);
  static const Color nutritionDark = Color(0xFF1B5E20);
  static const Color nutritionContainerLight = Color(0xFFE8F5E9);

  // Movement (Caminar/Pasos) - Energetic Orange
  static const Color movementPrimary = Color(0xFFFF5722);
  static const Color movementSecondary = Color(0xFFE64A19);
  static const Color movementDark = Color(0xFFBF360C);
  static const Color movementContainerLight = Color(0xFFFBE9E7);

  // Dashboard Unified & Neutral Palette
  static const Color primaryBlue = Color(0xFF00BCD4);
  static const Color secondaryAqua = Color(0xFF26C6DA);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  static ThemeData lightTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: hydrationPrimary,
      brightness: Brightness.light,
      primary: hydrationPrimary,
      secondary: nutritionPrimary,
      tertiary: movementPrimary,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: hydrationPrimary.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: hydrationPrimary, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: hydrationPrimary.withValues(alpha: 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: hydrationDark, size: 26);
          }
          return IconThemeData(color: Colors.grey.shade500, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hydrationDark,
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          );
        }),
      ),
    );
  }

  static ThemeData darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: hydrationPrimary,
      brightness: Brightness.dark,
      primary: const Color(0xFF26C6DA),
      secondary: const Color(0xFF66BB6A),
      tertiary: const Color(0xFFFF7043),
      surface: surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: surfaceDark,
        indicatorColor: hydrationPrimary.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF80DEEA), size: 26);
          }
          return IconThemeData(color: Colors.grey.shade400, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF80DEEA),
            );
          }
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          );
        }),
      ),
    );
  }
}

/// Unified App Background Container with dynamic glass & gradients
class UnifiedBackground extends StatelessWidget {
  final Widget child;

  const UnifiedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)]
              : const [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}

class WaterBackground extends StatelessWidget {
  final Widget child;
  const WaterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => UnifiedBackground(child: child);
}

class NutritionBackground extends StatelessWidget {
  final Widget child;
  const NutritionBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => UnifiedBackground(child: child);
}

class AnimatedBubbles extends StatelessWidget {
  final bool isActive;
  const AnimatedBubbles({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
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
