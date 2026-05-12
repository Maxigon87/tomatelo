import 'package:flutter/material.dart';

class WaterTrackerCard extends StatefulWidget {
  final int currentGlasses;
  final int goalGlasses;
  final VoidCallback onAddWater;
  final VoidCallback onRemoveWater;

  const WaterTrackerCard({
    super.key,
    required this.currentGlasses,
    required this.goalGlasses,
    required this.onAddWater,
    required this.onRemoveWater,
  });

  @override
  State<WaterTrackerCard> createState() => _WaterTrackerCardState();
}

class _WaterTrackerCardState extends State<WaterTrackerCard> {
  bool _isAddPressed = false;
  bool _isRemovePressed = false;

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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WaterActionButton(
                            label: '-1',
                            icon: Icons.remove_rounded,
                            isPressed: _isRemovePressed,
                            isCompact: true,
                            onPressed: widget.currentGlasses > 0
                                ? widget.onRemoveWater
                                : null,
                            onPressStateChanged: (isPressed) => setState(
                              () => _isRemovePressed = isPressed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _WaterActionButton(
                            label: '+1 💧',
                            isPressed: _isAddPressed,
                            onPressed: widget.onAddWater,
                            onPressStateChanged: (isPressed) => setState(
                              () => _isAddPressed = isPressed,
                            ),
                          ),
                        ],
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

class _WaterActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isPressed;
  final bool isCompact;
  final VoidCallback? onPressed;
  final ValueChanged<bool> onPressStateChanged;

  const _WaterActionButton({
    required this.label,
    required this.isPressed,
    required this.onPressed,
    required this.onPressStateChanged,
    this.icon,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return AnimatedScale(
      scale: isPressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.white.withValues(alpha: isEnabled ? 1 : 0.55),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        elevation: isPressed ? 2 : 8,
        shadowColor: Colors.black38,
        child: InkWell(
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
          onTapDown: isEnabled ? (_) => onPressStateChanged(true) : null,
          onTapUp: isEnabled ? (_) => onPressStateChanged(false) : null,
          onTapCancel: isEnabled ? () => onPressStateChanged(false) : null,
          onTap: onPressed,
          splashColor: const Color(0xFF56CCF2).withValues(alpha: 0.3),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 20,
              vertical: isCompact ? 14 : 18,
            ),
            child: icon == null
                ? Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F80ED),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: const Color(0xFF2F80ED).withValues(
                          alpha: isEnabled ? 1 : 0.45,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2F80ED).withValues(
                            alpha: isEnabled ? 1 : 0.45,
                          ),
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
