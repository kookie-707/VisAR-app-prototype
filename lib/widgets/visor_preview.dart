import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/hud_element.dart';

class VisorPreview extends StatefulWidget {
  const VisorPreview({super.key});

  @override
  State<VisorPreview> createState() => _VisorPreviewState();
}

class _VisorPreviewState extends State<VisorPreview>
    with SingleTickerProviderStateMixin {
  int? _selectedElementIndex;
  int? _draggingIndex;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return Column(
          children: [
            Container(
              height: 320,
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderGray, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    final leftZoneWidth = w * 0.30;
                    final centerWidth = w * 0.40;
                    final rightZoneStart = w * 0.70;
                    final rightZoneWidth = w * 0.30;

                    return Stack(
                      children: [
                        // Background
                        CustomPaint(
                          painter: VisorZonePainter(
                            leftWidth: leftZoneWidth,
                            centerWidth: centerWidth,
                            rightStart: rightZoneStart,
                          ),
                          size: Size(w, h),
                        ),
                        // Scan-line animation
                        AnimatedBuilder(
                          animation: _scanLineController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: ScanLinePainter(
                                progress: _scanLineController.value,
                              ),
                              size: Size(w, h),
                            );
                          },
                        ),
                        // Zone labels
                        Positioned(
                          top: 8,
                          left: leftZoneWidth / 2 - 16,
                          child: _zoneLabel('LEFT'),
                        ),
                        Positioned(
                          top: 8,
                          left: w / 2 - 32,
                          child: _zoneLabel('AR LANE', isCenter: true),
                        ),
                        Positioned(
                          top: 8,
                          right: rightZoneWidth / 2 - 20,
                          child: _zoneLabel('RIGHT'),
                        ),
                        // Center AR lane guidance placeholder
                        Positioned(
                          left: leftZoneWidth + centerWidth * 0.15,
                          top: h * 0.20,
                          width: centerWidth * 0.70,
                          height: h * 0.65,
                          child: _buildArLanePlaceholder(),
                        ),
                        // HUD elements in left zone
                        ..._buildZoneElements(
                          appState, VisorZone.left,
                          zoneLeft: 0,
                          zoneWidth: leftZoneWidth,
                          zoneHeight: h,
                        ),
                        // HUD elements in right zone
                        ..._buildZoneElements(
                          appState, VisorZone.right,
                          zoneLeft: rightZoneStart,
                          zoneWidth: rightZoneWidth,
                          zoneHeight: h,
                        ),
                        // Wireframe overlay
                        CustomPaint(
                          painter: WireframeGridPainter(),
                          size: Size(w, h),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Safety load indicator
            _buildSafetyLoadBar(appState),
          ],
        );
      },
    );
  }

  Widget _zoneLabel(String text, {bool isCenter = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCenter
            ? Colors.amber.withOpacity(0.15)
            : AppTheme.accentRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCenter
              ? Colors.amber.withOpacity(0.4)
              : AppTheme.accentRed.withOpacity(0.4),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.bodySmall.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: isCenter ? Colors.amber : AppTheme.accentRed,
        ),
      ),
    );
  }

  Widget _buildArLanePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1.5,
        ),
        color: Colors.amber.withOpacity(0.05),
      ),
      child: CustomPaint(
        painter: ArLanePainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.route,
                color: Colors.amber.withOpacity(0.5),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                'AR LANE\nGUIDANCE',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(
                  fontSize: 9,
                  color: Colors.amber.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.lock_outline,
                color: Colors.amber.withOpacity(0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildZoneElements(
    AppStateProvider appState,
    VisorZone zone, {
    required double zoneLeft,
    required double zoneWidth,
    required double zoneHeight,
  }) {
    final widgets = <Widget>[];
    for (int i = 0; i < appState.hudElements.length; i++) {
      final element = appState.hudElements[i];
      if (!element.enabled || element.zone != zone) continue;

      final isSelected = _selectedElementIndex == i;
      final isDragging = _draggingIndex == i;

      final elementX = zoneLeft + element.x * zoneWidth - 22;
      final elementY = element.y * zoneHeight - 22;

      widgets.add(
        Positioned(
          left: elementX,
          top: elementY,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedElementIndex =
                    _selectedElementIndex == i ? null : i;
              });
            },
            onPanStart: (_) {
              setState(() => _draggingIndex = i);
            },
            onPanUpdate: (details) {
              final RenderBox? box =
                  context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);

              final relX = (local.dx - zoneLeft) / zoneWidth;
              final relY = local.dy / zoneHeight;
              appState.updateHUDElementPosition(i, relX, relY);
            },
            onPanEnd: (_) {
              setState(() => _draggingIndex = null);
            },
            child: AnimatedScale(
              scale: isDragging ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentRed.withOpacity(0.3)
                      : AppTheme.accentRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentRed
                        : AppTheme.accentRed.withOpacity(0.5),
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.accentRed.withOpacity(0.6),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    if (isDragging)
                      BoxShadow(
                        color: AppTheme.accentRed.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                  ],
                ),
                child: Icon(
                  element.type.iconData,
                  size: 20,
                  color: isSelected
                      ? AppTheme.accentRed
                      : AppTheme.textWhite.withOpacity(0.8),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildSafetyLoadBar(AppStateProvider appState) {
    final load = appState.hudLoadPercent();
    final active = appState.activeElementCount();
    final max = AppStateProvider.maxTotalActiveElements;

    Color barColor;
    String label;
    if (load <= 0.5) {
      barColor = Colors.green;
      label = 'SAFE';
    } else if (load <= 0.75) {
      barColor = Colors.amber;
      label = 'MODERATE';
    } else {
      barColor = AppTheme.accentRed;
      label = 'HIGH LOAD';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.shield, color: barColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'HUD LOAD',
                    style: AppTheme.label.copyWith(fontSize: 11),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: barColor.withOpacity(0.5)),
                ),
                child: Text(
                  '$label  $active/$max',
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: barColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: load,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters ──

class VisorZonePainter extends CustomPainter {
  final double leftWidth;
  final double centerWidth;
  final double rightStart;

  VisorZonePainter({
    required this.leftWidth,
    required this.centerWidth,
    required this.rightStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF050505),
    );

    // Left zone tint
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftWidth, size.height),
      Paint()..color = AppTheme.accentRed.withOpacity(0.04),
    );

    // Right zone tint
    canvas.drawRect(
      Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
      Paint()..color = AppTheme.accentRed.withOpacity(0.04),
    );

    // Center zone tint (blocked)
    canvas.drawRect(
      Rect.fromLTWH(leftWidth, 0, centerWidth, size.height),
      Paint()..color = Colors.amber.withOpacity(0.02),
    );

    // Zone dividers
    final dividerPaint = Paint()
      ..color = AppTheme.textWhite.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Dashed lines for zone boundaries
    _drawDashedLine(canvas, Offset(leftWidth, 0), Offset(leftWidth, size.height), dividerPaint);
    _drawDashedLine(canvas, Offset(rightStart, 0), Offset(rightStart, size.height), dividerPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 6.0;
    const gapLength = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    double drawn = 0;
    while (drawn < length) {
      final segEnd = math.min(drawn + dashLength, length);
      canvas.drawLine(
        Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
        Offset(start.dx + unitX * segEnd, start.dy + unitY * segEnd),
        paint,
      );
      drawn += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(VisorZonePainter oldDelegate) => false;
}

class ArLanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Road perspective lines
    final cx = size.width / 2;
    final vanishY = size.height * 0.15;

    canvas.drawLine(
      Offset(cx, vanishY),
      Offset(size.width * 0.1, size.height * 0.95),
      paint,
    );
    canvas.drawLine(
      Offset(cx, vanishY),
      Offset(size.width * 0.9, size.height * 0.95),
      paint,
    );

    // Center dashes
    final dashPaint = Paint()
      ..color = Colors.amber.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double t = 0.3; t < 0.95; t += 0.15) {
      final y1 = vanishY + (size.height * 0.95 - vanishY) * t;
      final y2 = vanishY + (size.height * 0.95 - vanishY) * (t + 0.06);
      canvas.drawLine(Offset(cx, y1), Offset(cx, y2), dashPaint);
    }
  }

  @override
  bool shouldRepaint(ArLanePainter oldDelegate) => false;
}

class ScanLinePainter extends CustomPainter {
  final double progress;

  ScanLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppTheme.accentRed.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 10, size.width, 20));

    canvas.drawRect(Rect.fromLTWH(0, y - 10, size.width, 20), paint);
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class WireframeGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textWhite.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(WireframeGridPainter oldDelegate) => false;
}
