import 'dart:async';

import 'package:flutter/material.dart';

class FriendlyMessage extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const FriendlyMessage({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<FriendlyMessage> createState() => _FriendlyMessageState();
}

class _FriendlyMessageState extends State<FriendlyMessage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _timer = Timer(const Duration(seconds: 4), () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _controller,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(_controller),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(color: Colors.white),
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
