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

class CatalogFoodItem {
  const CatalogFoodItem({
    required this.id,
    required this.name,
    required this.habitId,
    required this.categoryLabel,
    required this.portion,
    required this.emoji,
    required this.color,
  });

  final String id;
  final String name;
  final String habitId;
  final String categoryLabel;
  final String portion;
  final String emoji;
  final Color color;
}

const catalogFoodItems = [
  CatalogFoodItem(
    id: 'apple_fuji',
    name: 'Manzana fuji fresca',
    habitId: 'fruit',
    categoryLabel: '+1 Fruta',
    portion: '1 porción (150g)',
    emoji: '🍎',
    color: Color(0xFFFB7185),
  ),
  CatalogFoodItem(
    id: 'tea_green',
    name: 'Té verde jazmín',
    habitId: 'tea',
    categoryLabel: '+1 Infusión',
    portion: '1 taza (250ml)',
    emoji: '🍵',
    color: Color(0xFF2DD4BF),
  ),
  CatalogFoodItem(
    id: 'berries_mix',
    name: 'Mix de berries',
    habitId: 'fruit',
    categoryLabel: '+1 Fruta',
    portion: '1 porción (120g)',
    emoji: '🫐',
    color: Color(0xFFFB7185),
  ),
  CatalogFoodItem(
    id: 'nuts_mix',
    name: 'Nueces y almendras',
    habitId: 'snack',
    categoryLabel: '+1 Snack',
    portion: '1 puñado (30g)',
    emoji: '🌰',
    color: Color(0xFFFBBF24),
  ),
  CatalogFoodItem(
    id: 'yogurt_greek',
    name: 'Yogurt griego natural',
    habitId: 'yogurt',
    categoryLabel: '+1 Yogurt',
    portion: '1 vaso (200g)',
    emoji: '🥛',
    color: Color(0xFF38BDF8),
  ),
  CatalogFoodItem(
    id: 'banana_fresh',
    name: 'Plátano maduro',
    habitId: 'fruit',
    categoryLabel: '+1 Fruta',
    portion: '1 unidad (120g)',
    emoji: '🍌',
    color: Color(0xFFFB7185),
  ),
  CatalogFoodItem(
    id: 'tea_chamomile',
    name: 'Té de manzanilla',
    habitId: 'tea',
    categoryLabel: '+1 Infusión',
    portion: '1 taza (250ml)',
    emoji: '🌼',
    color: Color(0xFF2DD4BF),
  ),
  CatalogFoodItem(
    id: 'seeds_mix',
    name: 'Semillas y frutos secos',
    habitId: 'snack',
    categoryLabel: '+1 Snack',
    portion: '1 puñado (25g)',
    emoji: '🥜',
    color: Color(0xFFFBBF24),
  ),
];

