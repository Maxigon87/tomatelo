import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/services/hydration_engine.dart';

void main() {
  const engine = HydrationEngine();

  group('HydrationEngine', () {
    test('calcula progreso ideal y estado on_track', () {
      final advice = engine.calculate(
        totalMl: 2000,
        consumedMl: 1100,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 22),
        now: DateTime(2026, 1, 1, 15),
      );

      expect(advice.idealMl, closeTo(1000, 0.01));
      expect(advice.status, HydrationStatus.onTrack);
      expect(advice.unsafeToCatchUp, isFalse);
    });

    test('detecta estado crítico y advertencia de seguridad', () {
      final advice = engine.calculate(
        totalMl: 2800,
        consumedMl: 600,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 22),
        now: DateTime(2026, 1, 1, 20, 30),
      );

      expect(advice.status, HydrationStatus.critical);
      expect(advice.unsafeToCatchUp, isTrue);
      expect(advice.warning, isNotNull);
    });

    test('evita divisiones inválidas con ventana de tiempo cero', () {
      final advice = engine.calculate(
        totalMl: 2500,
        consumedMl: 300,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 8),
        now: DateTime(2026, 1, 1, 8, 30),
      );

      expect(advice.idealMl, 0);
      expect(advice.remainingMl, 0);
      expect(advice.status, HydrationStatus.onTrack);
    });

    test('maneja tiempo restante cero con agua pendiente', () {
      final advice = engine.calculate(
        totalMl: 2000,
        consumedMl: 1000,
        startTime: DateTime(2026, 1, 1, 8),
        endTime: DateTime(2026, 1, 1, 20),
        now: DateTime(2026, 1, 1, 20),
      );

      expect(advice.status, HydrationStatus.critical);
      expect(advice.mlPerHourNeeded, HydrationEngine.maxReasonableMlPerHour);
      expect(advice.unsafeToCatchUp, isTrue);
    });
  });
}
