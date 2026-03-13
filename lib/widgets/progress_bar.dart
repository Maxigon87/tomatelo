import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const ProgressBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = total > 0 ? current / total : 0;
    if (percentage > 1.0) {
      percentage = 1.0;
    }
    return LinearProgressIndicator(
      value: percentage,
      minHeight: 10,
    );
  }
}
