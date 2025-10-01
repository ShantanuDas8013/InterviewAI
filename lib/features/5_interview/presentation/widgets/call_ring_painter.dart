import 'package:flutter/material.dart';

class CallRingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final int ringCount;

  CallRingPainter({
    required this.animation,
    required this.color,
    this.ringCount = 3,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < ringCount; i++) {
      // Calculate phase offset for each ring
      final phaseOffset = i * (1.0 / ringCount);
      final animationValue = (animation.value + phaseOffset) % 1.0;

      // Calculate radius and opacity based on animation value
      final radius = maxRadius * (0.5 + (animationValue * 0.5));
      final opacity = (1.0 - animationValue) * 0.7;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(CallRingPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.ringCount != ringCount;
  }
}
