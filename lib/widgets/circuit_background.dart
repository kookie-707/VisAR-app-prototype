import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class CircuitBackground extends StatelessWidget {
  const CircuitBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CircuitBackgroundPainter(),
      child: Container(),
    );
  }
}

class CircuitBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.patternGray.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Abstract circuit lines
    final path = Path();
    
    // Horizontal circuit lines
    for (double y = 100; y < size.height; y += 150) {
      path.reset();
      path.moveTo(0, y);
      path.lineTo(size.width * 0.3, y);
      path.moveTo(size.width * 0.7, y);
      path.lineTo(size.width, y);
      canvas.drawPath(path, paint);
    }

    // Vertical circuit lines
    for (double x = 100; x < size.width; x += 150) {
      path.reset();
      path.moveTo(x, 0);
      path.lineTo(x, size.height * 0.3);
      path.moveTo(x, size.height * 0.7);
      path.lineTo(x, size.height);
      canvas.drawPath(path, paint);
    }

    // Corner connections
    final cornerPaint = Paint()
      ..color = AppTheme.patternGray.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double y = 100; y < size.height; y += 150) {
      for (double x = 100; x < size.width; x += 150) {
        canvas.drawCircle(Offset(x, y), 3, cornerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CircuitBackgroundPainter oldDelegate) => false;
}
