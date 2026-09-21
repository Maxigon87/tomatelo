import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

class QuickLogPillCard extends StatelessWidget {
  final Function(int ml) onAddWaterMl;
  final VoidCallback onUndo;
  final List<int> weeklyData;

  const QuickLogPillCard({
    super.key,
    required this.onAddWaterMl,
    required this.onUndo,
    required this.weeklyData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick-Log Pill Action Zone
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
                  const Row(
                    children: [
                      Icon(
                        Icons.add_circle_rounded,
                        color: AppTheme.primaryAqua,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Registro Rápido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onUndo,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.undo_rounded,
                            size: 14,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Deshacer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  // +100ml Sorbito
                  Expanded(
                    child: _QuickLogButton(
                      label: '+100 ml',
                      subtitle: 'Sorbito',
                      icon: Icons.water_drop_outlined,
                      isRecommended: false,
                      onTap: () => onAddWaterMl(100),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // +250ml Vaso (Recommended)
                  Expanded(
                    child: _QuickLogButton(
                      label: '+250 ml',
                      subtitle: '1 Vaso',
                      icon: Icons.local_cafe_rounded,
                      isRecommended: true,
                      onTap: () => onAddWaterMl(250),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // +500ml Botella
                  Expanded(
                    child: _QuickLogButton(
                      label: '+500 ml',
                      subtitle: 'Botella',
                      icon: Icons.sports_bar_rounded,
                      isRecommended: false,
                      onTap: () => onAddWaterMl(500),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Weekly Circadian Intake Window Card
        _WeeklyCircadianCard(weeklyData: weeklyData),
      ],
    );
  }
}

class _QuickLogButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isRecommended;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: widget.isRecommended
                    ? AppTheme.surfaceHigh
                    : AppTheme.surfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: widget.isRecommended
                    ? Border.all(
                        color: AppTheme.primaryAqua.withValues(alpha: 0.6),
                        width: 1.5,
                      )
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1,
                      ),
                boxShadow: widget.isRecommended
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryAqua.withValues(alpha: 0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  if (widget.isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAqua,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Habitual',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00354A),
                        ),
                      ),
                    ),
                  if (widget.isRecommended) const SizedBox(height: 4),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isRecommended
                          ? AppTheme.primaryAqua
                          : AppTheme.surfaceHighest,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isRecommended
                          ? const Color(0xFF00354A)
                          : AppTheme.primaryAqua,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: widget.isRecommended
                          ? AppTheme.primaryAqua
                          : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _WeeklyCircadianCard extends StatelessWidget {
  final List<int> weeklyData;

  const _WeeklyCircadianCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final safeData = weeklyData.length == 7 ? weeklyData : List.filled(7, 0);
    final maxVal = safeData.fold(3000, (prev, element) => element > prev ? element : prev);

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
                Icons.alarm_on_rounded,
                color: AppTheme.tertiaryMint,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Semana',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Spacer(),
              Text(
                '¡Completemos esta semana!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
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
              final ratio = (val / maxVal).clamp(0.08, 1.0);
              final isToday = index == (DateTime.now().weekday - 1);

              return Column(
                children: [
                  Container(
                    width: 12,
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
                              : AppTheme.primaryAquaDim,
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
