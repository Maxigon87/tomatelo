import 'package:flutter/material.dart';

class NutritionHabit {
  const NutritionHabit({
    required this.id,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.defaultGoal,
  });

  final String id;
  final String label;
  final String emoji;
  final IconData icon;
  final int defaultGoal;

  String get name => '$emoji $label';
}

const nutritionHabits = [
  NutritionHabit(
    id: 'fruit',
    label: 'Fruta',
    emoji: '🍎',
    icon: Icons.eco_rounded,
    defaultGoal: 2,
  ),
  NutritionHabit(
    id: 'yogurt',
    label: 'Yogurt',
    emoji: '🥛',
    icon: Icons.local_drink_rounded,
    defaultGoal: 1,
  ),
  NutritionHabit(
    id: 'tea',
    label: 'Infusión',
    emoji: '🍵',
    icon: Icons.emoji_food_beverage_rounded,
    defaultGoal: 1,
  ),
  NutritionHabit(
    id: 'snack',
    label: 'Snack saludable',
    emoji: '🥜',
    icon: Icons.spa_rounded,
    defaultGoal: 1,
  ),
];

const defaultNutritionHabits = nutritionHabits;
