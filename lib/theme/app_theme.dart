import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.dark);

class AppTheme {
  // === Dark Palette Tokens ===
  static const Color darkBackground = Color(0xFF081325); // Deep Oceanic Slate
  static const Color darkSurfaceLowest = Color(0xFF040E20);
  static const Color darkSurfaceLow = Color(0xFF111C2E);
  static const Color darkSurfaceContainer = Color(0xFF152032);
  static const Color darkSurfaceHigh = Color(0xFF202A3D);
  static const Color darkSurfaceHighest = Color(0xFF2B3548);
  static const Color darkSurfaceBright = Color(0xFF2F394D);

  static const Color darkOnSurface = Color(0xFFD8E2FC);
  static const Color darkOnSurfaceVariant = Color(0xFFBDC8D1);

  // === Light Palette Tokens ===
  // Fondo celeste agua claro para light:
  static const Color lightBackground = Color(0xFFDDF4FE); // Crisp celeste agua claro
  static const Color lightSurfaceLowest = Color(0xFFCCEAF9);
  static const Color lightSurfaceLow = Color(0xFFFFFFFF); // Clean white cards
  static const Color lightSurfaceContainer = Color(0xFFF4FAFE); // Soft light surface
  static const Color lightSurfaceHigh = Color(0xFFE0F1FA);
  static const Color lightSurfaceHighest = Color(0xFFD0E8F6);
  static const Color lightSurfaceBright = Color(0xFFFFFFFF);

  static const Color lightOnSurface = Color(0xFF0F2438); // High contrast oceanic dark slate text
  static const Color lightOnSurfaceVariant = Color(0xFF45637D); // Clear readable secondary text

  // === Dynamic Theme Mode Helper ===
  static bool get isLightMode => themeModeNotifier.value == ThemeMode.light;

  // === Adaptive Color Accessors ===
  static Color get background => isLightMode ? lightBackground : darkBackground;
  static Color get surfaceLowest => isLightMode ? lightSurfaceLowest : darkSurfaceLowest;
  static Color get surfaceLow => isLightMode ? lightSurfaceLow : darkSurfaceLow;
  static Color get surfaceContainer => isLightMode ? lightSurfaceContainer : darkSurfaceContainer;
  static Color get surfaceHigh => isLightMode ? lightSurfaceHigh : darkSurfaceHigh;
  static Color get surfaceHighest => isLightMode ? lightSurfaceHighest : darkSurfaceHighest;
  static Color get surfaceBright => isLightMode ? lightSurfaceBright : darkSurfaceBright;

  static Color get onSurface => isLightMode ? lightOnSurface : darkOnSurface;
  static Color get onSurfaceVariant => isLightMode ? lightOnSurfaceVariant : darkOnSurfaceVariant;

  // Brand Accents (const for compile-time performance)
  static const Color primaryAqua = Color(0xFF38BDF8);
  static const Color primaryAquaDim = Color(0xFF7BD0FF);
  static const Color secondaryCoral = Color(0xFFFB7185);
  static const Color tertiaryMint = Color(0xFF34D399);
  static const Color tertiaryMintBright = Color(0xFF4EE6AA);

  // Backward compatibility color aliases
  static const Color primaryBlue = primaryAqua;
  static const Color secondaryAqua = primaryAquaDim;

  // Adaptive Card Styles
  static Color get cardBorder => isLightMode
      ? const Color(0xFFBAE6FD).withValues(alpha: 0.6)
      : Colors.white.withValues(alpha: 0.08);

  static Color get cardShadow => isLightMode
      ? const Color(0xFF0284C7).withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.35);

  static ThemeData darkTheme() {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: darkBackground,
        primary: Color(0xFF38BDF8),
        secondary: Color(0xFFFB7185),
        tertiary: Color(0xFF34D399),
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: darkSurfaceContainer,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurfaceLow,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }

  static ThemeData lightTheme() {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        surface: lightBackground,
        primary: Color(0xFF0284C7),
        secondary: Color(0xFFE11D48),
        tertiary: Color(0xFF059669),
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: lightSurfaceLow,
        elevation: 2,
        shadowColor: const Color(0xFF0284C7).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurfaceLow,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: const Color(0xFFBAE6FD).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.2,
          colors: isDark
              ? const [
                  Color(0xFF0F2B48),
                  AppTheme.darkBackground,
                ]
              : const [
                  Color(0xFFCCEBFB),
                  AppTheme.lightBackground,
                ],
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
        color: isDark ? AppTheme.darkBackground : const Color(0xFFEBF7F2),
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.2,
          colors: isDark
              ? const [
                  Color(0xFF281322),
                  AppTheme.darkBackground,
                ]
              : const [
                  Color(0xFFD8F3E5),
                  Color(0xFFEBF7F2),
                ],
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
