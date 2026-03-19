import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/models/hydration_advice.dart';
import 'package:tomatelo/services/notification_service.dart';

void main() {
  final service = NotificationService.instance;

  group('NotificationService.buildSuggestion', () {
    test('usa fallback sanitizado cuando no hay advice', () {
      final suggestion = service.buildSuggestion(
        now: DateTime(2026, 1, 1, 10),
        fallbackMinutes: 10,
      );

      expect(suggestion.minutesUntilNextReminder, 15);
      expect(suggestion.suggestedAt, DateTime(2026, 1, 1, 10, 15));
    });

    test('acorta intervalo para estado crítico', () {
      const advice = HydrationAdvice(
        idealMl: 1600,
        remainingMl: 1700,
        mlPerHourNeeded: 900,
        status: HydrationStatus.critical,
        message: 'critical',
        recommendedMlNow: 250,
        recommendedIntervalMinutes: 20,
        unsafeToCatchUp: true,
      );

      final suggestion = service.buildSuggestion(
        now: DateTime(2026, 1, 1, 18),
        fallbackMinutes: 60,
        hydrationAdvice: advice,
      );

      expect(suggestion.minutesUntilNextReminder, 20);
      expect(suggestion.reason, contains('intensivo'));
    });
  });
}
