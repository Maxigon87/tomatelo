import 'package:flutter/material.dart';

enum PetMood {
  optimal,
  alert,
  critical,
}

extension PetMoodX on PetMood {
  String get displayName {
    switch (this) {
      case PetMood.optimal:
        return 'Óptimo';
      case PetMood.alert:
        return 'Alerta';
      case PetMood.critical:
        return 'Crítico';
    }
  }

  Color get color {
    switch (this) {
      case PetMood.optimal:
        return const Color(0xFF4CAF50);
      case PetMood.alert:
        return const Color(0xFFFFB300);
      case PetMood.critical:
        return const Color(0xFFE53935);
    }
  }
}

class PetStateEngine {
  /// Evaluates Hydration Pet Mood based on consumption vs goal.
  static PetMood evaluateHydration({
    required int currentMl,
    required int goalMl,
    int daysInactive = 0,
  }) {
    if (goalMl <= 0) return PetMood.alert;
    final ratio = currentMl / goalMl;
    if (daysInactive >= 2 && ratio < 0.3) {
      return PetMood.critical;
    }
    if (ratio >= 0.8) {
      return PetMood.optimal;
    } else if (ratio >= 0.4) {
      return PetMood.alert;
    } else {
      return daysInactive >= 1 ? PetMood.critical : PetMood.alert;
    }
  }

  /// Evaluates Nutrition Pet Mood based on habits logged vs total goals.
  static PetMood evaluateNutrition({
    required Map<String, int> todayHabits,
    required Map<String, int> goalHabits,
    int daysInactive = 0,
  }) {
    if (goalHabits.isEmpty) return PetMood.optimal;
    int totalGoal = 0;
    int totalDone = 0;
    for (final entry in goalHabits.entries) {
      totalGoal += entry.value;
      totalDone += (todayHabits[entry.key] ?? 0).clamp(0, entry.value);
    }
    if (totalGoal == 0) return PetMood.optimal;
    final ratio = totalDone / totalGoal;
    if (daysInactive >= 2 && ratio < 0.2) return PetMood.critical;
    if (ratio >= 0.7) return PetMood.optimal;
    if (ratio >= 0.3) return PetMood.alert;
    return daysInactive >= 1 ? PetMood.critical : PetMood.alert;
  }

  /// Evaluates Movement Pet Mood based on steps vs target goal.
  static PetMood evaluateMovement({
    required int currentSteps,
    required int goalSteps,
    int daysInactive = 0,
  }) {
    if (goalSteps <= 0) return PetMood.optimal;
    final ratio = currentSteps / goalSteps;
    if (daysInactive >= 2 && ratio < 0.2) return PetMood.critical;
    if (ratio >= 0.75) return PetMood.optimal;
    if (ratio >= 0.35) return PetMood.alert;
    return daysInactive >= 1 ? PetMood.critical : PetMood.alert;
  }
}
