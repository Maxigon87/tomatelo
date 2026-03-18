import 'dart:math';

import 'package:tomatelo/models/hydration_advice.dart';

export 'package:tomatelo/models/hydration_advice.dart';

class HydrationEngine {
  const HydrationEngine({
    this.maxMlPerHour = 800,
    this.defaultIntervalMinutes = 45,
    this.minIntervalMinutes = 20,
    this.maxIntervalMinutes = 120,
  });

  final double maxMlPerHour;
  final int defaultIntervalMinutes;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;
  static const double maxReasonableMlPerHour = 2000;

  int calculateDailyGoalInMl(double weight) {
    if (weight <= 0) {
      return 0;
    }
    return (weight * 35).round();
  }

  int calculateDailyGoalInGlasses(double dailyGoalInMl, int waterStep) {
    if (dailyGoalInMl <= 0 || waterStep <= 0) {
      return 0;
    }
    return (dailyGoalInMl / waterStep).round();
  }

  HydrationAdvice calculate({
    required double totalMl,
    required double consumedMl,
    required DateTime startTime,
    required DateTime endTime,
    required DateTime now,
  }) {
    final safeTotalMl = totalMl.isFinite ? max(0, totalMl) : 0;
    final safeConsumedMl = consumedMl.isFinite ? max(0, consumedMl) : 0;

    final totalActiveMinutes =
        endTime.difference(startTime).inMinutes.clamp(0, 24 * 60);

    if (totalActiveMinutes == 0 || safeTotalMl == 0) {
      return HydrationAdvice(
        idealMl: 0,
        remainingMl: 0,
        mlPerHourNeeded: 0,
        status: HydrationStatus.onTrack,
        message: 'Configurá un horario y meta válidos para recomendaciones.',
        recommendedMlNow: 0,
        recommendedIntervalMinutes: 60,
        unsafeToCatchUp: false,
      );
    }

    final elapsedMinutes =
        now.difference(startTime).inMinutes.clamp(0, totalActiveMinutes);

    final remainingMinutes = max(0, totalActiveMinutes - elapsedMinutes);
    final elapsedRatio = elapsedMinutes / totalActiveMinutes;
    final idealMl = safeTotalMl * elapsedRatio;
    final remainingMl = max(0, safeTotalMl - safeConsumedMl);
    final remainingHours = remainingMinutes / 60;

    final mlPerHourNeeded = remainingHours <= 0
        ? (remainingMl > 0 ? maxReasonableMlPerHour : 0)
        : remainingMl / remainingHours;

    final delayMl = idealMl - safeConsumedMl;
    final delayRatio = safeTotalMl == 0 ? 0 : delayMl / safeTotalMl;

    final status = _pickStatus(
      delayRatio: delayRatio.toDouble(),
      mlPerHourNeeded: mlPerHourNeeded.toDouble(),
    );
    final unsafeToCatchUp =
        mlPerHourNeeded.isFinite && mlPerHourNeeded > maxMlPerHour;

    final recommendedIntervalMinutes = _recommendedInterval(
      remainingMinutes,
      status,
    );
    final recommendedMlNow = _recommendedNow(
      remainingMl: remainingMl.toDouble(),
      remainingMinutes: remainingMinutes,
      status: status,
      mlPerHourNeeded: mlPerHourNeeded.toDouble(),
    );

    return HydrationAdvice(
      idealMl: idealMl.toDouble(),
      remainingMl: remainingMl.toDouble(),
      mlPerHourNeeded: mlPerHourNeeded.isFinite
          ? mlPerHourNeeded.toDouble()
          : maxReasonableMlPerHour,
      status: status,
      message: _messageFor(status),
      recommendedMlNow: recommendedMlNow.toDouble(),
      recommendedIntervalMinutes: recommendedIntervalMinutes,
      unsafeToCatchUp: unsafeToCatchUp,
      warning: unsafeToCatchUp
          ? 'No es recomendable intentar completar toda el agua restante hoy. Hidratate de forma progresiva.'
          : null,
    );
  }

  HydrationStatus _pickStatus({
    required double delayRatio,
    required double mlPerHourNeeded,
  }) {
    if (mlPerHourNeeded > maxMlPerHour) {
      return HydrationStatus.critical;
    }
    if (delayRatio <= 0.05 && mlPerHourNeeded <= maxMlPerHour * 0.6) {
      return HydrationStatus.onTrack;
    }
    if (delayRatio <= 0.15 && mlPerHourNeeded <= maxMlPerHour * 0.8) {
      return HydrationStatus.slightlyBehind;
    }
    if (delayRatio <= 0.28 && mlPerHourNeeded <= maxMlPerHour) {
      return HydrationStatus.behind;
    }
    return HydrationStatus.critical;
  }

  int _recommendedInterval(int remainingMinutes, HydrationStatus status) {
    if (remainingMinutes <= 0) {
      return defaultIntervalMinutes;
    }

    final base = switch (status) {
      HydrationStatus.onTrack => 60,
      HydrationStatus.slightlyBehind => 45,
      HydrationStatus.behind => 30,
      HydrationStatus.critical => 20,
    };

    return base.clamp(minIntervalMinutes, maxIntervalMinutes);
  }

  double _recommendedNow({
    required double remainingMl,
    required int remainingMinutes,
    required HydrationStatus status,
    required double mlPerHourNeeded,
  }) {
    if (remainingMl <= 0 || remainingMinutes <= 0) {
      return 0;
    }

    final interval = _recommendedInterval(remainingMinutes, status);
    final doses = max(1, (remainingMinutes / interval).ceil());
    final byDose = remainingMl / doses;

    final byRate = mlPerHourNeeded * (interval / 60);

    final capped = min(maxMlPerHour * 0.4, max(byDose, byRate));
    return max(120, min(capped, remainingMl));
  }

  String _messageFor(HydrationStatus status) {
    return switch (status) {
      HydrationStatus.onTrack => 'Vas bien, seguí así 💧',
      HydrationStatus.slightlyBehind =>
        'Vas un poco atrasado, tomá un vaso ahora.',
      HydrationStatus.behind =>
        'Estás atrasado con tu hidratación. Intentá tomar agua de forma más constante.',
      HydrationStatus.critical =>
        'Te queda mucha agua en poco tiempo. Evitá tomar todo junto, empezá ahora y distribuí lo que puedas.',
    };
  }
}