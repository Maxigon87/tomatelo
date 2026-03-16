import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyChart extends StatelessWidget {
  final List<int> data;

  const WeeklyChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
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
                  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(
            data.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].toDouble(),
                  width: 16,
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [primary.withValues(alpha: 0.75), const Color(0xFF4FC3F7)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
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
