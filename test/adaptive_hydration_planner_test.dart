import 'package:flutter_test/flutter_test.dart';
import 'package:tomatelo/services/adaptive_hydration_planner.dart';

void main() {
  const planner = AdaptiveHydrationPlanner();

  group('AdaptiveHydrationPlanner', () {
    test('aplica progresion estandar de forma gradual', () {
      final day1 = planner.buildPlan(weightKg: 70, dayIndex: 1);
      final day6 = planner.buildPlan(weightKg: 70, dayIndex: 6);
      final day10 = planner.buildPlan(weightKg: 70, dayIndex: 10);

      expect(day1.targetGoalMl, (day1.idealGoalMl * 0.60).round());
      expect(day6.targetGoalMl, (day6.idealGoalMl * 0.75).round());
      expect(day10.targetGoalMl, day10.idealGoalMl);
    });

    test('reduce objetivo ante baja adherencia y evita cambios bruscos', () {
      final lowAdherence = [
        const DailyHydrationRecord(targetMl: 2200, consumedMl: 900),
        const DailyHydrationRecord(targetMl: 2200, consumedMl: 1000),
        const DailyHydrationRecord(targetMl: 2200, consumedMl: 1200),
      ];

      final plan = planner.buildPlan(
        weightKg: 70,
        dayIndex: 10,
        recentHistory: lowAdherence,
      );

      expect(plan.adaptationFactor, 0.9);
      expect(plan.targetGoalMl, (plan.idealGoalMl * 0.9).round());
    });

    test('modo pro inicia al objetivo completo', () {
      final plan = planner.buildPlan(
        weightKg: 70,
        dayIndex: 1,
        mode: HydrationMode.pro,
      );

      expect(plan.progressionFactor, 1.0);
      expect(plan.targetGoalMl, plan.idealGoalMl);
    });

    test('distribuye agua restante y genera mensaje de urgencia', () {
      final distribution = planner.distributeRemaining(
        targetGoalMl: 2200,
        consumedMl: 1000,
        now: DateTime(2026, 1, 5, 19, 30),
        activeFrom: DateTime(2026, 1, 5, 8),
        activeUntil: DateTime(2026, 1, 5, 22),
      );

      expect(distribution.remainingMl, 1200);
      expect(distribution.remainingGlasses, 5);
      expect(distribution.message, contains('Si no tomás ahora'));
    });
  });
}
