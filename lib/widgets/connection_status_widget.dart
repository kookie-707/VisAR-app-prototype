import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({super.key});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return GestureDetector(
          onTap: () => appState.toggleConnection(),
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing Ring Animation
                    if (appState.isConnected)
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: GlowingRingPainter(
                              progress: _ringController.value,
                            ),
                          );
                        },
                      ),
                    // Helmet Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.cardDark,
                        border: Border.all(
                          color: appState.isConnected
                              ? AppTheme.accentRed
                              : Colors.grey[800]!,
                          width: 2,
                        ),
                        boxShadow: appState.isConnected
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentRed.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.sports_motorsports,
                        size: 50,
                        color: appState.isConnected
                            ? AppTheme.accentRed
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                appState.isConnected ? 'CONNECTED' : 'DISCONNECTED',
                style: AppTheme.heading3.copyWith(
                  color: appState.isConnected
                      ? AppTheme.accentRed
                      : Colors.grey[500],
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to ${appState.isConnected ? 'disconnect' : 'connect'}',
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GlowingRingPainter extends CustomPainter {
  final double progress;

  GlowingRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = AppTheme.accentRed.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw multiple rings with varying opacity
    for (int i = 0; i < 3; i++) {
      final adjustedProgress = (progress + (i * 0.33)) % 1.0;
      final currentRadius = radius + (adjustedProgress * 15);
      final opacity = 1.0 - adjustedProgress;

      paint.color = AppTheme.accentRed.withOpacity(opacity * 0.4);
      canvas.drawCircle(center, currentRadius, paint);
    }

    // Draw main pulsing ring
    final mainPaint = Paint()
      ..color = AppTheme.accentRed.withOpacity(0.6 + (math.sin(progress * 2 * math.pi) * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius + 5, mainPaint);
  }

  @override
  bool shouldRepaint(GlowingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
