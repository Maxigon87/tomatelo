import 'package:flutter/material.dart';
import 'package:tomatelo/models/nutrition_habit.dart';
import 'package:tomatelo/theme/app_theme.dart';

class NutritionTrackerCard extends StatelessWidget {
  const NutritionTrackerCard({
    super.key,
    required this.today,
    required this.goals,
    required this.completed,
    required this.totalGoal,
    required this.onAddHabit,
    required this.onOpenGoals,
    this.yesterdayData,
    this.weeklyData,
  });

  final Map<String, int> today;
  final Map<String, int> goals;
  final int completed;
  final int totalGoal;
  final ValueChanged<NutritionHabit> onAddHabit;
  final VoidCallback onOpenGoals;
  final Map<String, int>? yesterdayData;
  final List<int>? weeklyData;

  double get _progress {
    if (totalGoal <= 0) return 0;
    return (completed / totalGoal).clamp(0.0, 1.0);
  }

  String get _message {
    if (completed == 0) return 'Un hábito pequeño para empezar ✨';
    if (_progress < 0.5) return 'Vas sumando cuidado suave 🌱';
    if (_progress < 1) return '¡Buen equilibrio hoy! ✨';
    return 'Día liviano y completo 🎉';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TARJETA PRINCIPAL DE HÁBITOS DIARIOS
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completed / $totalGoal hábitos',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _message,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onOpenGoals,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        size: 18,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Progress Bar
              Container(
                width: double.infinity,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLowest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.tertiaryMint,
                          AppTheme.tertiaryMintBright,
                          AppTheme.primaryAqua,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.tertiaryMint.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quick Action Chips Grid (4 Habits)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: nutritionHabits.map((habit) {
                  final val = today[habit.id] ?? 0;
                  final goal = goals[habit.id] ?? habit.defaultGoal;
                  final isDone = val >= goal;

                  final color = switch (habit.id) {
                    'fruit' => AppTheme.secondaryCoral,
                    'yogurt' => AppTheme.primaryAqua,
                    'tea' => AppTheme.tertiaryMint,
                    _ => const Color(0xFFFBBF24),
                  };

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onAddHabit(habit),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppTheme.surfaceHighest
                              : AppTheme.surfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDone
                                ? color.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.05),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color.withValues(alpha: 0.20),
                              ),
                              child: Icon(habit.icon, size: 18, color: color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '+1 ${habit.label}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    '$val/$goal',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 18,
                              color: isDone ? color : AppTheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // TARJETA ASISTENTE INTELIGENTE
        _IntelligentAssistantCard(completed: completed, totalGoal: totalGoal),
        const SizedBox(height: 14),
        // TARJETA "AYER"
        _YesterdayHabitsCard(yesterdayData: yesterdayData, goals: goals),
        const SizedBox(height: 14),
        // TARJETA "TU SEMANA"
        _WeeklyHabitsCard(weeklyData: weeklyData),
      ],
    );
  }
}

class _IntelligentAssistantCard extends StatelessWidget {
  final int completed;
  final int totalGoal;

  const _IntelligentAssistantCard({
    required this.completed,
    required this.totalGoal,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalGoal <= 0 ? 0 : ((completed / totalGoal) * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.tertiaryMint,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Asistente inteligente',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHigh,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$pct% de equilibrio',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.tertiaryMint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🍎', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hace rato no registras fruta hoy. Una fruta puede sumar frescura y vitalidad a tu tarde.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YesterdayHabitsCard extends StatelessWidget {
  final Map<String, int>? yesterdayData;
  final Map<String, int> goals;

  const _YesterdayHabitsCard({
    required this.yesterdayData,
    required this.goals,
  });

  @override
  Widget build(BuildContext context) {
    final yData = yesterdayData ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: AppTheme.onSurfaceVariant,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Ayer',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: nutritionHabits.map((habit) {
              final val = yData[habit.id] ?? 0;
              final goal = goals[habit.id] ?? habit.defaultGoal;
              final isDone = val >= goal;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 16,
                      color: isDone ? AppTheme.tertiaryMint : AppTheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${habit.emoji} ${habit.label} $val/$goal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                          color: isDone ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyHabitsCard extends StatelessWidget {
  final List<int>? weeklyData;

  const _WeeklyHabitsCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    final safeData = (weeklyData != null && weeklyData!.length == 7)
        ? weeklyData!
        : List.filled(7, 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: AppTheme.tertiaryMint,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Tu semana',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Spacer(),
              Text(
                'Ritmo constante',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tertiaryMint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final val = safeData[index];
              final ratio = (val / 5).clamp(0.1, 1.0);
              final isToday = index == (DateTime.now().weekday - 1);

              return Column(
                children: [
                  Container(
                    width: 14,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppTheme.tertiaryMint
                              : AppTheme.secondaryCoral,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? AppTheme.tertiaryMint
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
