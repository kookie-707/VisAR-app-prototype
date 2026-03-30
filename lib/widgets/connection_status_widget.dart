import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/pi_connection_service.dart' show PiConnectionState;
import '../services/config_service.dart';

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

  Color _stateColor(PiConnectionState state) {
    switch (state) {
      case PiConnectionState.connected:
        return AppTheme.accentRed;
      case PiConnectionState.connecting:
      case PiConnectionState.handshaking:
        return Colors.amber;
      case PiConnectionState.reconnecting:
        return Colors.orange;
      case PiConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String _stateLabel(PiConnectionState state) {
    switch (state) {
      case PiConnectionState.connected:
        return 'CONNECTED';
      case PiConnectionState.connecting:
        return 'CONNECTING...';
      case PiConnectionState.handshaking:
        return 'HANDSHAKING...';
      case PiConnectionState.reconnecting:
        return 'RECONNECTING...';
      case PiConnectionState.disconnected:
        return 'DISCONNECTED';
    }
  }

  String _stateHint(PiConnectionState state) {
    switch (state) {
      case PiConnectionState.connected:
        return 'Tap to disconnect';
      case PiConnectionState.connecting:
      case PiConnectionState.handshaking:
        return 'Establishing link...';
      case PiConnectionState.reconnecting:
        return 'Tap to cancel';
      case PiConnectionState.disconnected:
        return 'Tap to connect';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final state = appState.connectionState;
        final color = _stateColor(state);
        final isActive = state == PiConnectionState.connected;
        final isAnimating = state == PiConnectionState.connecting ||
            state == PiConnectionState.handshaking ||
            state == PiConnectionState.reconnecting;

        return GestureDetector(
          onTap: () {
            final configService = Provider.of<ConfigService>(context, listen: false);
            appState.toggleConnection(config: configService.config);
          },
          child: Column(
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glowing Ring Animation
                    if (isActive || isAnimating)
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: GlowingRingPainter(
                              progress: _ringController.value,
                              color: color,
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
                          color: isActive ? color : Colors.grey[800]!,
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.sports_motorsports,
                        size: 50,
                        color: (isActive || isAnimating)
                            ? color
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _stateLabel(state),
                  style: AppTheme.heading3.copyWith(
                    color: (isActive || isAnimating) ? color : Colors.grey[500],
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _stateHint(state),
                  style: AppTheme.bodySmall.copyWith(fontSize: 11),
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
  final Color color;

  GlowingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < 3; i++) {
      final adjustedProgress = (progress + (i * 0.33)) % 1.0;
      final currentRadius = radius + (adjustedProgress * 15);
      final opacity = 1.0 - adjustedProgress;
      paint.color = color.withOpacity(opacity * 0.4);
      canvas.drawCircle(center, currentRadius, paint);
    }

    final mainPaint = Paint()
      ..color = color.withOpacity(0.6 + (math.sin(progress * 2 * math.pi) * 0.2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius + 5, mainPaint);
  }

  @override
  bool shouldRepaint(GlowingRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
