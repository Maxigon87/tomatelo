import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === Stitch Design System Color Tokens ===
  static const Color background = Color(0xFF081325); // Deep Oceanic Slate
  static const Color surfaceLowest = Color(0xFF040E20);
  static const Color surfaceLow = Color(0xFF111C2E);
  static const Color surfaceContainer = Color(0xFF152032);
  static const Color surfaceHigh = Color(0xFF202A3D);
  static const Color surfaceHighest = Color(0xFF2B3548);
  static const Color surfaceBright = Color(0xFF2F394D);

  static const Color onSurface = Color(0xFFD8E2FC);
  static const Color onSurfaceVariant = Color(0xFFBDC8D1);

  // Backward compatibility color aliases
  static const Color primaryBlue = primaryAqua;
  static const Color secondaryAqua = primaryAquaDim;
  static const Color primaryAqua = Color(0xFF38BDF8); // Water (Electric Aqua)
  static const Color primaryAquaDim = Color(0xFF7BD0FF);
  static const Color secondaryCoral = Color(0xFFFB7185); // Nutrition & Fruit (Fresh Botanical Coral)
  static const Color tertiaryMint = Color(0xFF34D399); // Activity / Tea (Mint Infusion)
  static const Color tertiaryMintBright = Color(0xFF4EE6AA);

  // === Light Palette Tokens ===
  static const Color lightBackground = Color(0xFFF0F6FF);
  static const Color lightSurfaceLow = Color(0xFFFFFFFF);
  static const Color lightSurfaceContainer = Color(0xFFE5F1FF);
  static const Color lightSurfaceHigh = Color(0xFFD4E5F9);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceVariant = Color(0xFF475569);

  static ThemeData darkTheme() {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: primaryAqua,
        secondary: secondaryCoral,
        tertiary: tertiaryMint,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: surfaceContainer,
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
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.2,
          colors: [
            Color(0xFF0F2B48),
            AppTheme.background,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        gradient: RadialGradient(
          center: Alignment(0, -0.5),
          radius: 1.2,
          colors: [
            Color(0xFF281322),
            AppTheme.background,
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

