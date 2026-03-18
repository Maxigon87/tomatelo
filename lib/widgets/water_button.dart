import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class WaterButton extends StatefulWidget {
  final VoidCallback onPressed;

  const WaterButton({super.key, required this.onPressed});

  @override
  State<WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<WaterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _player = AudioPlayer();
  }

  Future<void> _handlePress() async {
    await _controller.reverse();
    _controller.forward();
    widget.onPressed();
    await _player.play(AssetSource('sounds/water_drop.wav'));
  }

  @override
  void dispose() {
    _player.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.45),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF4FC3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              splashColor: Colors.white.withValues(alpha: 0.35),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              onTap: _handlePress,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 8,
                    left: 18,
                    right: 18,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.water_drop_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Beber un vaso',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
