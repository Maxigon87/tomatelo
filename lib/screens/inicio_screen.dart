import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tomatelo/screens/setup_screen.dart';
import 'package:tomatelo/theme/app_theme.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _iconScale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WaterBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.95),
                            AppTheme.accentLightBlue.withValues(alpha: 0.45),
                            AppTheme.secondaryAqua.withValues(alpha: 0.10),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                            blurRadius: 34,
                            spreadRadius: 6,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: const Image(
                        image: AssetImage('assets/images/logo.png'),
                        height: 250,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final progress = _controller.value;
                      return Transform.translate(
                        offset: Offset(0, math.sin(progress * math.pi * 2) * 9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(270, 86),
                              painter: _TitleDropsPainter(progress),
                            ),
                            const _OutlinedAppTitle(),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: 260,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const SetupScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: const Text(
                        'Inicio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    'Design: EMGI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedAppTitle extends StatelessWidget {
  const _OutlinedAppTitle();

  static const String _title = 'Tomatelo';

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          _title,
          semanticsLabel: _title,
          style: TextStyle(
            fontSize: 46,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 9
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
            shadows: [
              Shadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFC62828), Color(0xFFFF6B5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            _title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleDropsPainter extends CustomPainter {
  final double progress;

  _TitleDropsPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final dropPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.88),
          AppTheme.accentLightBlue.withValues(alpha: 0.62),
          AppTheme.secondaryAqua.withValues(alpha: 0.36),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.74)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    const drops = [
      _DropSpec(0.07, 0.42, 7.0, 0.0),
      _DropSpec(0.16, 0.23, 4.8, 0.7),
      _DropSpec(0.27, 0.75, 5.5, 1.3),
      _DropSpec(0.74, 0.27, 6.0, 2.0),
      _DropSpec(0.86, 0.64, 4.7, 2.6),
      _DropSpec(0.94, 0.37, 6.8, 3.2),
    ];

    for (final drop in drops) {
      final wave = math.sin((progress * math.pi * 2) + drop.phase);
      final center = Offset(
        size.width * drop.x + math.cos(progress * math.pi * 2 + drop.phase) * 6,
        size.height * drop.y + wave * 8,
      );
      _drawDrop(canvas, center, drop.radius, dropPaint, outlinePaint);
    }
  }

  void _drawDrop(
    Canvas canvas,
    Offset center,
    double radius,
    Paint fill,
    Paint outline,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius * 1.45)
      ..cubicTo(
        center.dx + radius * 1.15,
        center.dy - radius * 0.25,
        center.dx + radius * 0.82,
        center.dy + radius * 1.1,
        center.dx,
        center.dy + radius * 1.25,
      )
      ..cubicTo(
        center.dx - radius * 0.82,
        center.dy + radius * 1.1,
        center.dx - radius * 1.15,
        center.dy - radius * 0.25,
        center.dx,
        center.dy - radius * 1.45,
      )
      ..close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant _TitleDropsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DropSpec {
  final double x;
  final double y;
  final double radius;
  final double phase;

  const _DropSpec(this.x, this.y, this.radius, this.phase);
}
