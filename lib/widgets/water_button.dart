import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

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
  final Random _random = Random();
  bool _isHandlingPress = false;

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
    _configurePlayer();
  }

  Future<void> _configurePlayer() async {
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> _playWaterDrop() async {
    final playbackRate = 0.92 + (_random.nextDouble() * 0.18);
    final volume = 0.78 + (_random.nextDouble() * 0.17);

    await _player.stop();
    await _player.setPlaybackRate(playbackRate);
    await _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
    await _player.play(AssetSource('sounds/water_drop.wav'));
  }

  Future<void> _handlePress() async {
    if (_isHandlingPress) {
      return;
    }
    _isHandlingPress = true;

    widget.onPressed();

    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50, amplitude: 100);
    }
    await _playWaterDrop();
    await _controller.forward();
    _isHandlingPress = false;
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.forward();
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
              color: const Color(0xFF4FC3F7).withOpacity(0.45),
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
              splashColor: Colors.white.withOpacity(0.5),
              highlightColor: Colors.white.withOpacity(0.25),
              onTapDown: _handleTapDown,
              onTapCancel: _handleTapCancel,
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
                        color: Colors.white.withOpacity(0.22),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Un vasito',
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
