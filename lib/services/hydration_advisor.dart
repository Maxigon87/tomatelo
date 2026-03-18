import 'dart:math';

/// Estados del sistema de hidratación.
enum HydrationStatus {
  onTrack('on_track'),
  slightlyBehind('slightly_behind'),
  behind('behind'),
  critical('critical');

  const HydrationStatus(this.value);
  final String value;
}

class HydrationAdvice {
  const HydrationAdvice({
    required this.idealMl,
    required this.remainingMl,
    required this.mlPerHourNeeded,
    required this.status,
    required this.message,
    required this.recommendedMlNow,
    required this.recommendedIntervalMinutes,
    required this.unsafeToCatchUp,
    this.warning,
  });

  final double idealMl;
  final double remainingMl;
  final double mlPerHourNeeded;
  final String status;
  final String message;
  final double recommendedMlNow;
  final int recommendedIntervalMinutes;
  final bool unsafeToCatchUp;
  final String? warning;
}

/// Servicio reusable que calcula progreso ideal y recomendaciones dinámicas.
class HydrationAdvisor {
  const HydrationAdvisor({
    this.maxMlPerHour = 800,
    this.defaultIntervalMinutes = 45,
    this.minIntervalMinutes = 20,
    this.maxIntervalMinutes = 120,
  });

  final double maxMlPerHour;
  final int defaultIntervalMinutes;
  final int minIntervalMinutes;
  final int maxIntervalMinutes;

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
      return const HydrationAdvice(
        idealMl: 0,
        remainingMl: 0,
        mlPerHourNeeded: 0,
        status: 'on_track',
        message: 'Configurá un horario y meta válidos para recomendaciones.',
        recommendedMlNow: 0,
        recommendedIntervalMinutes: 60,
        unsafeToCatchUp: false,
      );
    }

    final elapsedMinutes = now
        .difference(startTime)
        .inMinutes
        .clamp(0, totalActiveMinutes);

    final remainingMinutes = max(0, totalActiveMinutes - elapsedMinutes);
    final elapsedRatio = elapsedMinutes / totalActiveMinutes;
    final idealMl = safeTotalMl * elapsedRatio;
    final remainingMl = max(0, safeTotalMl - safeConsumedMl);
    final remainingHours = remainingMinutes / 60;

    final mlPerHourNeeded = remainingHours <= 0
        ? (remainingMl > 0 ? double.infinity : 0)
        : remainingMl / remainingHours;

    final delayMl = idealMl - safeConsumedMl;
    final delayRatio = safeTotalMl == 0 ? 0 : delayMl / safeTotalMl;

    final status = _pickStatus(delayRatio: delayRatio, mlPerHourNeeded: mlPerHourNeeded);
    final unsafeToCatchUp = mlPerHourNeeded.isFinite && mlPerHourNeeded > maxMlPerHour;

    final recommendedIntervalMinutes = _recommendedInterval(remainingMinutes, status);
    final recommendedMlNow = _recommendedNow(
      remainingMl: remainingMl,
      remainingMinutes: remainingMinutes,
      status: status,
    );

    return HydrationAdvice(
      idealMl: idealMl,
      remainingMl: remainingMl,
      mlPerHourNeeded: mlPerHourNeeded.isFinite ? mlPerHourNeeded : maxMlPerHour,
      status: status.value,
      message: _messageFor(status),
      recommendedMlNow: recommendedMlNow,
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
  }) {
    if (remainingMl <= 0 || remainingMinutes <= 0) {
      return 0;
    }

    final interval = _recommendedInterval(remainingMinutes, status);
    final remainingHours = remainingMinutes / 60;
    final doses = max(1, (remainingMinutes / interval).ceil());

    final byDose = remainingMl / doses;
    final byRate = remainingHours <= 0 ? remainingMl : (remainingMl / remainingHours) * (interval / 60);

    // Evitamos sugerir bolos demasiado grandes en una sola toma.
    final capped = min(maxMlPerHour * 0.5, max(byDose, byRate));
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
