import 'dart:math';

import 'package:flutter/material.dart';

class DropletAnimation extends StatefulWidget {
  final bool trigger;

  const DropletAnimation({super.key, required this.trigger});

  @override
  State<DropletAnimation> createState() => _DropletAnimationState();
}

class _DropletAnimationState extends State<DropletAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 750),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _isVisible = false;
            });
          }
        });
  }

  @override
  void didUpdateWidget(covariant DropletAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      setState(() {
        _isVisible = true;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_controller.value);
          final dropY = -100 + (240 * t);
          final splashOpacity = (1 - (t - 0.6).clamp(0, 1) * 2).clamp(0, 1);

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: dropY,
                child: Opacity(
                  opacity: 1 - (t - 0.75).clamp(0, 1),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    size: 40,
                    color: Color(0xFF4FC3F7),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


