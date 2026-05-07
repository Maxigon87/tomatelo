import 'package:flutter/material.dart';

class WaterTrackerCard extends StatefulWidget {
  final int currentGlasses;
  final int goalGlasses;
  final VoidCallback onAddWater;

  const WaterTrackerCard({
    super.key,
    required this.currentGlasses,
    required this.goalGlasses,
    required this.onAddWater,
  });

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  bool _isPressed = false;

  // Calculates completion percentage safely (0.0 to 1.0)
  double get _progress {
    if (widget.goalGlasses <= 0) return 0.0;
    return (widget.currentGlasses / widget.goalGlasses).clamp(0.0, 1.0);
  }

  // Dynamic motivational text based on progress
  String get _motivationalText {
    if (_progress == 0.0) return "¡Empecemos! 💧";
    if (_progress < 0.5) return "¡Sigue así! 💧";
    if (_progress < 1.0) return "¡Ya casi! 🌊";
    return "¡Meta cumplida! 🎉";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF56CCF2), // Light top
            Color(0xFF2F80ED), // Dark bottom
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Subtle highlight/reflection effect simulating water surface
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Progress Focus (Visual Hierarchy)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.currentGlasses} / ${widget.goalGlasses}',
                              style: const TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _motivationalText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated Action Button (+1 Drop)
                      GestureDetector(
                        onTapDown: (_) => setState(() => _isPressed = true),
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                          widget.onAddWater();
                        },
                        onTapCancel: () => setState(() => _isPressed = false),
                        child: AnimatedScale(
                          scale: _isPressed ? 0.92 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutBack,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            elevation: _isPressed ? 2 : 8,
                            shadowColor: Colors.black38,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: widget.onAddWater,
                              splashColor: const Color(0xFF56CCF2).withValues(alpha: 0.3),
                              highlightColor: Colors.transparent,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                child: Text(
                                  '+1 💧',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2F80ED),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Animated Horizontal Progress Bar
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
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
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.6),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
