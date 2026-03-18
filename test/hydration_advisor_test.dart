import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/services/hydration_advisor.dart';

void main() {
  const advisor = HydrationAdvisor();

  group('HydrationAdvisor', () {
    test('calcula progreso ideal y estado on_track', () {
      final advice = advisor.calculate(
        totalMl: 2000,
        consumedMl: 1100,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 22),
        now: DateTime(2026, 1, 1, 15),
      );

      expect(advice.idealMl, closeTo(1000, 0.01));
      expect(advice.status, 'on_track');
      expect(advice.unsafeToCatchUp, isFalse);
    });

    test('detecta estado crítico y advertencia de seguridad', () {
      final advice = advisor.calculate(
        totalMl: 2800,
        consumedMl: 600,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 22),
        now: DateTime(2026, 1, 1, 20, 30),
      );

      expect(advice.status, 'critical');
      expect(advice.unsafeToCatchUp, isTrue);
      expect(advice.warning, isNotNull);
    });

    test('evita divisiones inválidas con ventana de tiempo cero', () {
      final advice = advisor.calculate(
        totalMl: 2500,
        consumedMl: 300,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 8),
        now: DateTime(2026, 1, 1, 8, 30),
      );

      expect(advice.idealMl, 0);
      expect(advice.remainingMl, 0);
      expect(advice.status, 'on_track');
    });
  });
}
