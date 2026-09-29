class AppConstants {
  static const dailyGoal = 2000; // ml

  static const waterStep = 250;
}

class GoalUtils {
  /// Normaliza cualquier valor guardado de meta diaria de agua a número de vasos (ej. 8 o 10 vasos)
  static int toGlasses(int storedGoal) {
    if (storedGoal <= 0) return 8; // Default 8 vasos (2000 ml)
    if (storedGoal > 50) {
      // Fue guardado en ML (ej. 2000 o 2500)
      return (storedGoal / AppConstants.waterStep).round();
    }
    return storedGoal;
  }

  /// Normaliza cualquier valor guardado de meta diaria de agua a ML totales (ej. 2000 o 2500 ml)
  static int toMl(int storedGoal) {
    return toGlasses(storedGoal) * AppConstants.waterStep;
  }
}
