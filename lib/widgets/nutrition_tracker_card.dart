import 'package:flutter/material.dart';
import 'package:tomatelo/models/nutrition_habit.dart';

class NutritionTrackerCard extends StatelessWidget {
  const NutritionTrackerCard({
    super.key,
    required this.today,
    required this.goals,
    required this.completed,
    required this.totalGoal,
    required this.onAddHabit,
    required this.onOpenGoals,
  });

  final Map<String, int> today;
  final Map<String, int> goals;
  final int completed;
  final int totalGoal;
  final ValueChanged<NutritionHabit> onAddHabit;
  final VoidCallback onOpenGoals;

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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA8E063), Color(0xFFFFB74D)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB74D).withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -44,
              right: -34,
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
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
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _message,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      IconButton.filled(
                        onPressed: onOpenGoals,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          foregroundColor: const Color(0xFF689F38),
                        ),
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * _progress,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.62),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: nutritionHabits.map((habit) {
                      final count = today[habit.id] ?? 0;
                      final goal = goals[habit.id] ?? habit.defaultGoal;
                      return _HabitButton(
                        habit: habit,
                        count: count,
                        goal: goal,
                        onTap: () => onAddHabit(habit),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitButton extends StatefulWidget {
  const _HabitButton({
    required this.habit,
    required this.count,
    required this.goal,
    required this.onTap,
  });

  final NutritionHabit habit;
  final int count;
  final int goal;
  final VoidCallback onTap;

  @override
  State<_HabitButton> createState() => _HabitButtonState();
}

class _HabitButtonState extends State<_HabitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        elevation: _pressed ? 1 : 6,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.habit.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 7),
                Text(
                  '+1 ${widget.habit.label}',
                  style: const TextStyle(
                    color: Color(0xFF558B2F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  '${widget.count}/${widget.goal}',
                  style: TextStyle(
                    color: const Color(0xFF558B2F).withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
