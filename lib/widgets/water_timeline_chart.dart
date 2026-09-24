import 'package:flutter/material.dart';
import 'package:tomatelo/theme/app_theme.dart';
import 'package:tomatelo/utils/constants.dart';

/// Widget que visualiza la "Guía de Hidratación Diaria"
/// Muestra 2 líneas en sincronía a lo largo del día:
/// 1. Línea Objetivo ("Dónde debería estar" según el horario del día)
/// 2. Línea Real ("Por dónde voy realmente" según lo consumido)
class WaterTimelineChart extends StatefulWidget {
  final int dailyGoalMl;
  final int glassesToday;
  final DateTime? lastDrinkAt;
  final int startHour;
  final int endHour;

  const WaterTimelineChart({
    super.key,
    required this.dailyGoalMl,
    required this.glassesToday,
    this.lastDrinkAt,
    this.startHour = 7,
    this.endHour = 23,
  });

  @override
  State<WaterTimelineChart> createState() => _WaterTimelineChartState();
}

class _WaterTimelineChartState extends State<WaterTimelineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant WaterTimelineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.glassesToday != widget.glassesToday ||
        oldWidget.dailyGoalMl != widget.dailyGoalMl) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _actualMl => (widget.glassesToday * AppConstants.waterStep).round();

  double get _currentHourFraction {
    final now = DateTime.now();
    final hour = now.hour + (now.minute / 60.0);
    return hour.clamp(widget.startHour.toDouble(), widget.endHour.toDouble());
  }

  double get _dayTimeProgress {
    final range = widget.endHour - widget.startHour;
    if (range <= 0) return 1.0;
    return ((_currentHourFraction - widget.startHour) / range).clamp(0.0, 1.0);
  }

  int get _idealMlNow => (widget.dailyGoalMl * _dayTimeProgress).round();

  int get _diffMl => _actualMl - _idealMlNow;

  @override
  Widget build(BuildContext context) {
    final idealNow = _idealMlNow;
    final actual = _actualMl;
    final target = widget.dailyGoalMl > 0 ? widget.dailyGoalMl : 2000;
    final diff = _diffMl;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (actual >= target && target > 0) {
      statusText = '¡Meta diaria cumplida! 🎉';
      statusColor = AppTheme.tertiaryMint;
      statusIcon = Icons.stars_rounded;
    } else if (diff >= -100) {
      statusText = diff >= 0
          ? '¡Vas al día! +$diff ml de ventaja 💧'
          : '¡Excelente ritmo! A solo 1 sorbo de la meta ideal';
      statusColor = AppTheme.tertiaryMint;
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (diff >= -400) {
      statusText = 'Leve atraso (-${diff.abs()} ml). ¡Un vaso te pone al día! ⏱️';
      statusColor = AppTheme.primaryAqua;
      statusIcon = Icons.schedule_rounded;
    } else {
      statusText = 'Atrasado por ${diff.abs()} ml. Hidrátate a sorbos constantes 💡';
      statusColor = AppTheme.secondaryCoral;
      statusIcon = Icons.warning_amber_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado con Icono y Título
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryAqua.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppTheme.primaryAqua.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: AppTheme.primaryAqua,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guía de Hidratación',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Camino ideal vs. tu progreso actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${(actual * 100 / target).clamp(0, 100).round()}%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Leyenda de Caminos (Objetivo vs Real)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAqua.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Camino Ideal',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Tu Progreso Real',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Gráfico Canvas
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 120),
                painter: _TimelineChartPainter(
                  animValue: _progressAnim.value,
                  targetMl: target,
                  actualMl: actual,
                  idealMlNow: idealNow,
                  currentHourFraction: _currentHourFraction,
                  startHour: widget.startHour,
                  endHour: widget.endHour,
                  actualColor: statusColor,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Pie de estado dinámico
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
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

class _TimelineChartPainter extends CustomPainter {
  final double animValue;
  final int targetMl;
  final int actualMl;
  final int idealMlNow;
  final double currentHourFraction;
  final int startHour;
  final int endHour;
  final Color actualColor;

  _TimelineChartPainter({
    required this.animValue,
    required this.targetMl,
    required this.actualMl,
    required this.idealMlNow,
    required this.currentHourFraction,
    required this.startHour,
    required this.endHour,
    required this.actualColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paddingBottom = 22.0;
    final paddingTop = 10.0;
    final chartHeight = size.height - paddingBottom - paddingTop;
    final chartWidth = size.width;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final hourRange = endHour - startHour;
    double hourToX(double hour) {
      final ratio = ((hour - startHour) / hourRange).clamp(0.0, 1.0);
      return ratio * chartWidth;
    }

    double mlToY(double ml) {
      final ratio = (ml / (targetMl > 0 ? targetMl : 2000)).clamp(0.0, 1.2);
      return size.height - paddingBottom - (ratio * chartHeight);
    }

    // Dibujar líneas de cuadrícula horizontales
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int step = 0; step <= 3; step++) {
      final y = size.height - paddingBottom - (chartHeight * step / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 1. DIBUJAR LÍNEA OBJETIVO ("Dónde debería estar")
    final idealPaint = Paint()
      ..color = AppTheme.primaryAqua.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final idealFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryAqua.withValues(alpha: 0.12),
          AppTheme.primaryAqua.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, paddingTop, chartWidth, chartHeight));

    final idealPath = Path();
    idealPath.moveTo(0, mlToY(0));

    // Curva S suave para el objetivo ideal durante el día
    final stepsCount = 20;
    for (int i = 1; i <= stepsCount; i++) {
      final t = i / stepsCount;
      final hour = startHour + (hourRange * t);
      final currentIdealMl = targetMl * t;
      final x = hourToX(hour);
      final y = mlToY(currentIdealMl * animValue);
      idealPath.lineTo(x, y);
    }

    final idealFillPath = Path.from(idealPath)
      ..lineTo(chartWidth, size.height - paddingBottom)
      ..lineTo(0, size.height - paddingBottom)
      ..close();

    canvas.drawPath(idealFillPath, idealFillPaint);
    canvas.drawPath(idealPath, idealPaint);

    // 2. DIBUJAR LÍNEA REAL ("Por dónde voy realmente")
    final nowX = hourToX(currentHourFraction);
    final actualY = mlToY(actualMl * animValue);

    final actualPath = Path();
    actualPath.moveTo(0, mlToY(0));

    // Construimos una curva progresiva real hasta la hora actual
    final currentHourRatio = ((currentHourFraction - startHour) / hourRange).clamp(0.0, 1.0);
    final pointsCount = 10;
    for (int i = 1; i <= pointsCount; i++) {
      final t = (i / pointsCount) * currentHourRatio;
      final hour = startHour + (hourRange * t);
      final x = hourToX(hour);
      // Simula progresión gradual hacia el valor actual acumulado
      final currentActual = actualMl * (t / (currentHourRatio > 0 ? currentHourRatio : 1.0));
      final y = mlToY(currentActual * animValue);
      actualPath.lineTo(x, y);
    }

    final actualGlowPaint = Paint()
      ..color = actualColor.withValues(alpha: 0.6)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final actualLinePaint = Paint()
      ..color = actualColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final actualFillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          actualColor.withValues(alpha: 0.25),
          actualColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, paddingTop, nowX, chartHeight));

    final actualFillPath = Path.from(actualPath)
      ..lineTo(nowX, size.height - paddingBottom)
      ..lineTo(0, size.height - paddingBottom)
      ..close();

    canvas.drawPath(actualFillPath, actualFillPaint);
    canvas.drawPath(actualPath, actualGlowPaint);
    canvas.drawPath(actualPath, actualLinePaint);

    // 3. INDICADOR VERTICAL DE "AHORA"
    final nowLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(nowX, paddingTop),
      Offset(nowX, size.height - paddingBottom),
      nowLinePaint,
    );

    // Punto brillante de la posición actual
    final dotOuterPaint = Paint()
      ..color = actualColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(nowX, actualY), 6, dotOuterPaint);
    canvas.drawCircle(Offset(nowX, actualY), 3.5, dotInnerPaint);

    // 4. MARCADORES DE HORAS EN EL EJE X
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final hoursToShow = [startHour, 11, 15, 19, endHour];

    for (final hour in hoursToShow) {
      if (hour < startHour || hour > endHour) continue;
      final x = hourToX(hour.toDouble());
      final timeStr = '${hour.toString().padLeft(2, '0')}:00';

      textPainter.text = TextSpan(
        text: timeStr,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: (hour == currentHourFraction.round()) ? FontWeight.w800 : FontWeight.w500,
          color: (hour == currentHourFraction.round())
              ? AppTheme.primaryAqua
              : AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineChartPainter oldDelegate) {
    return oldDelegate.animValue != animValue ||
        oldDelegate.actualMl != actualMl ||
        oldDelegate.targetMl != targetMl ||
        oldDelegate.currentHourFraction != currentHourFraction;
  }
}
