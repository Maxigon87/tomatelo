import 'package:flutter/material.dart';

class TomateloHomeWidgetCard extends StatefulWidget {
  final int currentGlasses;
  final int goalGlasses;
  final ValueChanged<int>? onChanged;

  const TomateloHomeWidgetCard({
    super.key,
    required this.currentGlasses,
    required this.goalGlasses,
    this.onChanged,
  });

  @override
  State<TomateloHomeWidgetCard> createState() => _TomateloHomeWidgetCardState();
}

class _TomateloHomeWidgetCardState extends State<TomateloHomeWidgetCard> {
  bool _isPressed = false;
  bool _showDrop = false;

  double get _progress {
    if (widget.goalGlasses <= 0) return 0;
    return (widget.currentGlasses / widget.goalGlasses).clamp(0.0, 1.0);
  }

  String get _encouragement {
    if (_progress >= 1) return 'Goal complete 🎉';
    if (_progress >= 0.75) return 'Almost there 💧';
    if (_progress >= 0.4) return 'Keep going 💧';
    return 'Great start 🚰';
  }

  Future<void> _onAddTap() async {
    setState(() {
      _isPressed = true;
      _showDrop = true;
    });

    widget.onChanged?.call((widget.currentGlasses + 1).clamp(0, widget.goalGlasses));

    await Future<void>.delayed(const Duration(milliseconds: 130));
    if (!mounted) return;
    setState(() => _isPressed = false);

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    setState(() => _showDrop = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6EC6FF), Color(0xFF1D74E8)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40104AA3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            left: 12,
            right: 12,
            child: IgnorePointer(
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.33),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.currentGlasses} / ${widget.goalGlasses}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 12,
                          color: Colors.white.withValues(alpha: 0.28),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 550),
                              curve: Curves.easeOutCubic,
                              width: constraints.maxWidth * value,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFFFFF), Color(0xFFCBE8FF)],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                _encouragement,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOut,
                      top: _showDrop ? -28 : -16,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 280),
                        opacity: _showDrop ? 1 : 0,
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _onAddTap,
                          splashColor: Colors.white.withValues(alpha: 0.22),
                          highlightColor: Colors.white.withValues(alpha: 0.09),
                          child: AnimatedScale(
                            scale: _isPressed ? 0.92 : 1,
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutBack,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Text(
                                '+1 💧',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
        ],
      ),
    );
  }
}
