import 'package:flutter/material.dart';

class WaterButton extends StatefulWidget {
  final VoidCallback onPressed;

  const WaterButton({super.key, required this.onPressed});

  @override
  State<WaterButton> createState() => _WaterButtonState();
}

class _WaterButtonState extends State<WaterButton> {
  double _scale = 1;

  void _animate() async {
    setState(() => _scale = 1.2);
    await Future.delayed(const Duration(milliseconds: 120));
    setState(() => _scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _scale,
      child: ElevatedButton(
        onPressed: () {
          _animate();
          widget.onPressed();
        },
        child: const Text("💧 I drank a glass"),
      ),
    );
  }
}
