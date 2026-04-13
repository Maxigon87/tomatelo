import 'dart:math';

/// Modos de exigencia para ajustar la progresión y la presión de recordatorios.
enum HydrationMode { suave, estandar, pro, ahorro }

/// Configuración de progresión. Todo es configurable para iterar producto sin
/// tocar la lógica central.
class ProgressionConfig {
  const ProgressionConfig({
    this.days1To3Factor = 0.60,
    this.days4To7Factor = 0.75,
    this.week2OnwardFactor = 1.0,
    this.softModeRange = const RangeValues(0.50, 0.70),
    this.saverModeRange = const RangeValues(0.60, 0.80),
    this.nonComplianceThreshold = 0.70,
    this.consistentThreshold = 0.95,
    this.adaptationStep = 0.10,
    this.minAdaptationFactor = 0.70,
    this.maxAdaptationFactor = 1.0,
    this.defaultGlassSizeMl = 250,
  });

  final double days1To3Factor;
  final double days4To7Factor;
  final double week2OnwardFactor;
  final RangeValues softModeRange;
  final RangeValues saverModeRange;
  final double nonComplianceThreshold;
  final double consistentThreshold;
  final double adaptationStep;
  final double minAdaptationFactor;
  final double maxAdaptationFactor;
  final int defaultGlassSizeMl;
}

class RangeValues {
  const RangeValues(this.min, this.max) : assert(min <= max);

  final double min;
  final double max;

  double lerp(double t) {
    final safe = t.clamp(0.0, 1.0);
    return min + ((max - min) * safe);
  }
}

/// Registro diario para análisis de adherencia.
class DailyHydrationRecord {
  const DailyHydrationRecord({required this.targetMl, required this.consumedMl});

  final int targetMl;
  final int consumedMl;

  double get completionRatio {
    if (targetMl <= 0) return 0;
    return (consumedMl / targetMl).clamp(0.0, 2.0);
  }
}

/// Salida del cálculo inteligente.
class AdaptiveHydrationPlan {
  const AdaptiveHydrationPlan({
    required this.baseGoalMl,
    required this.idealGoalMl,
    required this.targetGoalMl,
    required this.targetGlasses,
    required this.mode,
    required this.progressionFactor,
    required this.adaptationFactor,
  });

  final int baseGoalMl;
  final int idealGoalMl;
  final int targetGoalMl;
  final int targetGlasses;
  final HydrationMode mode;
  final double progressionFactor;
  final double adaptationFactor;
}

class DistributionPlan {
  const DistributionPlan({
    required this.remainingMl,
    required this.remainingGlasses,
    required this.hoursLeft,
    required this.mlPerHourNeeded,
    required this.message,
  });

  final int remainingMl;
  final int remainingGlasses;
  final double hoursLeft;
  final double mlPerHourNeeded;
  final String message;
}


/// Ejemplo rápido de uso con datos reales:
///
/// final planner = AdaptiveHydrationPlanner();
/// final plan = planner.buildPlan(
///   weightKg: 72,
///   dayIndex: 5,
///   mode: HydrationMode.estandar,
///   recentHistory: const [
///     DailyHydrationRecord(targetMl: 2500, consumedMl: 1800),
///     DailyHydrationRecord(targetMl: 2500, consumedMl: 1900),
///   ],
/// );
/// final distribution = planner.distributeRemaining(
///   targetGoalMl: plan.targetGoalMl,
///   consumedMl: 900,
///   now: DateTime(2026, 1, 8, 16),
///   activeFrom: DateTime(2026, 1, 8, 8),
///   activeUntil: DateTime(2026, 1, 8, 22),
/// );
class AdaptiveHydrationPlanner {
  const AdaptiveHydrationPlanner({this.config = const ProgressionConfig()});

  final ProgressionConfig config;

  int calculateBaseGoalMl({required double weightKg, double mlPerKg = 35}) {
    if (weightKg <= 0 || mlPerKg <= 0) return 0;
    return (weightKg * mlPerKg).round();
  }

  int toGlasses(int ml, {int? glassSizeMl}) {
    final size = glassSizeMl ?? config.defaultGlassSizeMl;
    if (ml <= 0 || size <= 0) return 0;
    return (ml / size).ceil();
  }

  AdaptiveHydrationPlan buildPlan({
    required double weightKg,
    required int dayIndex,
    HydrationMode mode = HydrationMode.estandar,
    List<DailyHydrationRecord> recentHistory = const [],
    int? customIdealGoalMl,
  }) {
    final baseGoalMl = calculateBaseGoalMl(weightKg: weightKg);
    final idealGoalMl = max(baseGoalMl, customIdealGoalMl ?? baseGoalMl);

    final progressionFactor = _progressionFactor(dayIndex: dayIndex, mode: mode);
    final adaptationFactor = _adaptationFactor(recentHistory);

    final rawTarget = idealGoalMl * progressionFactor * adaptationFactor;
    final boundedTarget = rawTarget.clamp(
      idealGoalMl * config.minAdaptationFactor,
      idealGoalMl.toDouble(),
    );

    final targetGoalMl = boundedTarget.round();
    return AdaptiveHydrationPlan(
      baseGoalMl: baseGoalMl,
      idealGoalMl: idealGoalMl,
      targetGoalMl: targetGoalMl,
      targetGlasses: toGlasses(targetGoalMl),
      mode: mode,
      progressionFactor: progressionFactor,
      adaptationFactor: adaptationFactor,
    );
  }

  DistributionPlan distributeRemaining({
    required int targetGoalMl,
    required int consumedMl,
    required DateTime now,
    required DateTime activeFrom,
    required DateTime activeUntil,
    int? glassSizeMl,
  }) {
    final remainingMl = max(0, targetGoalMl - consumedMl);
    final totalWindowHours = max(
      0.0,
      activeUntil.difference(activeFrom).inMinutes / 60,
    );

    final hoursLeft = max(0.0, activeUntil.difference(now).inMinutes / 60);
    final mlPerHourNeeded = hoursLeft == 0
        ? (remainingMl > 0 ? remainingMl.toDouble() : 0)
        : (remainingMl / hoursLeft);

    final remainingGlasses = toGlasses(remainingMl, glassSizeMl: glassSizeMl);

    final message = _buildReminderMessage(
      remainingGlasses: remainingGlasses,
      hoursLeft: hoursLeft,
      mlPerHourNeeded: mlPerHourNeeded,
      totalWindowHours: totalWindowHours,
    );

    return DistributionPlan(
      remainingMl: remainingMl,
      remainingGlasses: remainingGlasses,
      hoursLeft: hoursLeft,
      mlPerHourNeeded: mlPerHourNeeded,
      message: message,
    );
  }

  double _progressionFactor({required int dayIndex, required HydrationMode mode}) {
    if (mode == HydrationMode.pro) return 1.0;

    final defaultFactor = switch (dayIndex) {
      <= 3 => config.days1To3Factor,
      <= 7 => config.days4To7Factor,
      _ => config.week2OnwardFactor,
    };

    return switch (mode) {
      HydrationMode.suave => config.softModeRange.lerp((dayIndex / 14)),
      HydrationMode.estandar => defaultFactor,
      HydrationMode.pro => 1.0,
      HydrationMode.ahorro => config.saverModeRange.lerp((dayIndex / 14)),
    };
  }

  double _adaptationFactor(List<DailyHydrationRecord> recentHistory) {
    if (recentHistory.isEmpty) return 1.0;

    final average = recentHistory
            .map((e) => e.completionRatio)
            .reduce((a, b) => a + b) /
        recentHistory.length;

    if (average < config.nonComplianceThreshold) {
      return (1.0 - config.adaptationStep).clamp(
        config.minAdaptationFactor,
        config.maxAdaptationFactor,
      );
    }

    if (average >= config.consistentThreshold) {
      return (1.0 + (config.adaptationStep / 2)).clamp(
        config.minAdaptationFactor,
        config.maxAdaptationFactor,
      );
    }

    return 1.0;
  }

  String _buildReminderMessage({
    required int remainingGlasses,
    required double hoursLeft,
    required double mlPerHourNeeded,
    required double totalWindowHours,
  }) {
    final roundedHours = hoursLeft.ceil();
    final hasLowTime = totalWindowHours > 0 && hoursLeft <= totalWindowHours * 0.25;

    if (remainingGlasses <= 0) {
      return '¡Objetivo del día cumplido! Mantené sorbos pequeños para estabilidad.';
    }

    if (hasLowTime && remainingGlasses >= 2) {
      return 'Te faltan $remainingGlasses vasos y quedan $roundedHours horas. Si no tomás ahora, no llegás al objetivo.';
    }

    return 'Te faltan $remainingGlasses vasos y quedan $roundedHours horas. Ritmo recomendado: ${mlPerHourNeeded.round()} ml/h.';
  }
}
