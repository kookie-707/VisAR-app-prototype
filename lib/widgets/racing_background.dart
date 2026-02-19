import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class RacingBackground extends StatelessWidget {
  const RacingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RacingBackgroundPainter(),
      child: Container(),
    );
  }
}

class RacingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.patternGray
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Diagonal racing lines
    final spacing = 40.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Subtle grid pattern
    final gridPaint = Paint()
      ..color = AppTheme.patternGray.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    final gridSpacing = 60.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(RacingBackgroundPainter oldDelegate) => false;
}
