import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  final List<int> waterWeekly;
  final List<int> nutritionWeekly;
  final List<int> movementWeekly;
  final int streakDays;

  const StatsScreen({
    super.key,
    required this.waterWeekly,
    required this.nutritionWeekly,
    required this.movementWeekly,
    required this.streakDays,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedCategoryIndex = 0; // 0: Agua, 1: Nutrición, 2: Movimiento
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.streakDays > 0) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<int> get _currentData {
    switch (_selectedCategoryIndex) {
      case 0:
        return widget.waterWeekly;
      case 1:
        return widget.nutritionWeekly;
      case 2:
      default:
        return widget.movementWeekly;
    }
  }

  Color get _currentCategoryColor {
    switch (_selectedCategoryIndex) {
      case 0:
        return AppTheme.hydrationPrimary;
      case 1:
        return AppTheme.nutritionPrimary;
      case 2:
      default:
        return AppTheme.movementPrimary;
    }
  }

  String get _currentCategoryTitle {
    switch (_selectedCategoryIndex) {
      case 0:
        return 'Hidratación (ml)';
      case 1:
        return 'Nutrición (hábitos)';
      case 2:
      default:
        return 'Movimiento (pasos)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _currentData;
    final maxVal = data.isEmpty
        ? 10.0
        : (data.reduce((a, b) => a > b ? a : b).toDouble() * 1.2).clamp(10.0, 15000.0);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Estadísticas & Racha'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Streak Card Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('🔥', style: TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.streakDays} Días en Racha',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.streakDays > 0
                                  ? '¡Excelente trabajo! Tus mascotas están radiantes.'
                                  : '¡Completa tus metas de hoy para iniciar tu racha!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Category Filter Chips
                const Text(
                  'Selecciona una Sección',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip(0, '💧 Agua', AppTheme.hydrationPrimary),
                    const SizedBox(width: 8),
                    _buildFilterChip(1, '🥗 Nutrición', AppTheme.nutritionPrimary),
                    const SizedBox(width: 8),
                    _buildFilterChip(2, '🏃 Pasos', AppTheme.movementPrimary),
                  ],
                ),

                const SizedBox(height: 24),

                // FL_Chart Bar Chart Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentCategoryTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _currentCategoryColor,
                            ),
                          ),
                          const Icon(Icons.bar_chart_rounded, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            maxY: maxVal,
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                                    final i = value.toInt();
                                    if (i < 0 || i >= 7) return const SizedBox.shrink();
                                    final date = DateTime.now().subtract(Duration(days: 6 - i));
                                    final label = labels[date.weekday - 1];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barGroups: List.generate(
                              data.length.clamp(0, 7),
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: data[i].toDouble(),
                                    width: 16,
                                    borderRadius: BorderRadius.circular(12),
                                    color: _currentCategoryColor,
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxVal,
                                      color: _currentCategoryColor.withValues(alpha: 0.12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(int index, String label, Color color) {
    final isSelected = _selectedCategoryIndex == index;
    return Expanded(
      child: FilterChip(
        selected: isSelected,
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          setState(() {
            _selectedCategoryIndex = index;
          });
        },
      ),
    );
  }
}
