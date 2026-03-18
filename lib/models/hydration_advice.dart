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
  final HydrationStatus status;
  final String message;
  final double recommendedMlNow;
  final int recommendedIntervalMinutes;
  final bool unsafeToCatchUp;
  final String? warning;
}