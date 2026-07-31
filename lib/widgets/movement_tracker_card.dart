import 'package:flutter/material.dart';

class MovementTrackerCard extends StatefulWidget {
  final int currentMinutes;
  final int goalMinutes;
  final VoidCallback? onAddMinutes;
  final VoidCallback? onAdd15Minutes;
  final VoidCallback? onRemoveMinutes;
  final bool showManualControls;

  const MovementTrackerCard({
    super.key,
    required this.currentMinutes,
    required this.goalMinutes,
    this.onAddMinutes,
    this.onAdd15Minutes,
    this.onRemoveMinutes,
    this.showManualControls = true,
  });

  @override
  State<MovementTrackerCard> createState() => _MovementTrackerCardState();
}

class _MovementTrackerCardState extends State<MovementTrackerCard> {
  bool _isAddMinPressed = false;
  bool _isAdd15MinPressed = false;
  bool _isRemoveMinPressed = false;

  double get _progress {
    if (widget.goalMinutes <= 0) return 0.0;
    return (widget.currentMinutes / widget.goalMinutes).clamp(0.0, 1.0);
  }

  String get _motivationalText {
    final double pct = _progress * 100;
    if (pct >= 100) {
      return "¡Meta alcanzada! Tu cuerpo y tu mente te lo agradecen. 🌟";
    } else if (pct >= 80) {
      return "¡Casi lo logras! Unos minutos más de actividad. 🏁";
    } else if (pct >= 40) {
      return "¡Vas a excelente ritmo! Ya se siente la energía. 🏃‍♂️";
    } else {
      return "¡Buen inicio! Cada minuto activo cuenta para tu salud. ⏱️";
    }
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
            Color(0xFFFFB74D), // Soft Orange
            Color(0xFFE65100), // Rich Dark Orange
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withValues(alpha: 0.35),
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
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.14),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.currentMinutes} / ${widget.goalMinutes} min',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Tiempo activo hoy ⏱️',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _motivationalText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.showManualControls)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ActionButton(
                                  label: '-5m',
                                  icon: Icons.remove_rounded,
                                  isPressed: _isRemoveMinPressed,
                                  onPressed: widget.currentMinutes >= 5 && widget.onRemoveMinutes != null
                                      ? widget.onRemoveMinutes
                                      : null,
                                  onPressStateChanged: (isPressed) => setState(
                                    () => _isRemoveMinPressed = isPressed,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  label: '+5m',
                                  icon: Icons.add_rounded,
                                  isPressed: _isAddMinPressed,
                                  onPressed: widget.onAddMinutes,
                                  onPressStateChanged: (isPressed) => setState(
                                    () => _isAddMinPressed = isPressed,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.onAdd15Minutes != null) ...[
                              const SizedBox(height: 8),
                              _ActionButton(
                                label: '+15m ⏱️',
                                isPressed: _isAdd15MinPressed,
                                onPressed: widget.onAdd15Minutes,
                                onPressStateChanged: (isPressed) => setState(
                                  () => _isAdd15MinPressed = isPressed,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progress Bar
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

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isPressed;
  final VoidCallback? onPressed;
  final ValueChanged<bool> onPressStateChanged;

  const _ActionButton({
    required this.label,
    required this.isPressed,
    required this.onPressed,
    required this.onPressStateChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => onPressStateChanged(true),
      onTapUp: disabled ? null : (_) => onPressStateChanged(false),
      onTapCancel: disabled ? null : () => onPressStateChanged(false),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.diagonal3Values(isPressed ? 0.94 : 1.0, isPressed ? 0.94 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withValues(alpha: 0.1)
              : (isPressed
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: disabled ? Colors.white30 : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: disabled ? Colors.white30 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
