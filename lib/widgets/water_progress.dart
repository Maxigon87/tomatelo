import 'package:flutter/material.dart';

class WaterProgress extends StatelessWidget {
  final int current;
  final int total;

  const WaterProgress({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "$current / $total",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Text("glasses"),
            ],
          ),
        ],
      ),
    );
  }
}
