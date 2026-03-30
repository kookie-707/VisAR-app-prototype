import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/hud_element.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';
import '../widgets/visor_preview.dart';
import '../widgets/circuit_background.dart';

class HUDCustomizationScreen extends StatefulWidget {
  const HUDCustomizationScreen({super.key});

  @override
  State<HUDCustomizationScreen> createState() => _HUDCustomizationScreenState();
}

class _HUDCustomizationScreenState extends State<HUDCustomizationScreen> {
  bool _isFullScreen = false;

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return _FullScreenVisorEditor(
        onClose: () {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
          setState(() => _isFullScreen = false);
        },
      );
    }
    return _buildNormalView(context);
  }

  Widget _buildNormalView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          const CircuitBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HUD CONFIG',
                              style: AppTheme.heading1.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure your AR visor display',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textWhiteSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Full screen editor button
                      _buildFullScreenButton(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Safety warning
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      if (appState.safetyWarning == null) {
                        return const SizedBox.shrink();
                      }
                      return _buildWarningBanner(appState);
                    },
                  ),

                  // Visor preview (compact)
                  const VisorPreview(),
                  const SizedBox(height: 20),

                  // ── PI HUD SETTINGS (synced to Pi) ──
                  Text(
                    'PI HUD SETTINGS',
                    style: AppTheme.heading3.copyWith(
                      fontSize: 14,
                      letterSpacing: 1,
                      color: AppTheme.accentRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'These settings sync to the Pi in real-time',
                    style: AppTheme.bodySmall.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  _buildPiSettingsSection(),
                  const SizedBox(height: 24),

                  // ── ELEMENT PLACEMENT ──
                  Text(
                    'DISPLAY ELEMENTS',
                    style: AppTheme.heading3.copyWith(
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      return Column(
                        children: List.generate(
                          appState.hudElements.length,
                          (index) => _buildElementCard(
                            appState.hudElements[index],
                            index,
                            appState,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenButton() {
    return GestureDetector(
      onTap: () => setState(() => _isFullScreen = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentRed.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fullscreen, color: AppTheme.accentRed, size: 20),
            const SizedBox(width: 6),
            Text(
              'EDITOR',
              style: AppTheme.label.copyWith(
                fontSize: 11,
                color: AppTheme.accentRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pi Settings Section (backed by ConfigService) ──
  Widget _buildPiSettingsSection() {
    return Consumer<ConfigService>(
      builder: (context, configService, _) {
        final config = configService.config;
        return Column(
          children: [
            // Blindspot toggle + sensitivity
            _buildSettingsCard(
              icon: Icons.sensors,
              title: 'BLIND-SPOT ALERTS',
              subtitle: 'Side-edge gradient warnings',
              trailing: Switch(
                value: config.blindspotEnabled,
                activeColor: AppTheme.accentRed,
                onChanged: (v) {
                  configService.updateBlindspotEnabled(v);
                  _syncConfigToPi(context);
                },
              ),
              child: config.blindspotEnabled
                  ? _buildSensitivitySelector(configService, config)
                  : null,
            ),
            const SizedBox(height: 10),

            // FCW toggle
            _buildSettingsCard(
              icon: Icons.emergency,
              title: 'FORWARD COLLISION',
              subtitle: 'Pi-side FCW alerts',
              trailing: Switch(
                value: config.fcwEnabled,
                activeColor: AppTheme.accentRed,
                onChanged: (v) {
                  configService.updateFcwEnabled(v);
                  _syncConfigToPi(context);
                },
              ),
            ),
            const SizedBox(height: 10),

            // HUD Brightness
            _buildBrightnessSlider(configService, config),
            const SizedBox(height: 10),

            // Nav cue style
            _buildSettingsCard(
              icon: Icons.navigation,
              title: 'NAV CUE STYLE',
              subtitle: config.navCueStyle == NavCueStyle.detailed
                  ? 'Arrow + distance + street'
                  : 'Arrow only',
              trailing: SegmentedButton<NavCueStyle>(
                segments: const [
                  ButtonSegment(
                    value: NavCueStyle.minimal,
                    label: Text('MIN', style: TextStyle(fontSize: 10)),
                  ),
                  ButtonSegment(
                    value: NavCueStyle.detailed,
                    label: Text('FULL', style: TextStyle(fontSize: 10)),
                  ),
                ],
                selected: {config.navCueStyle},
                onSelectionChanged: (v) {
                  configService.updateNavCueStyle(v.first);
                  _syncConfigToPi(context);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.accentRed.withOpacity(0.3);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppTheme.accentRed;
                    }
                    return Colors.grey;
                  }),
                  side: WidgetStateProperty.all(
                    BorderSide(color: AppTheme.borderGray),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSensitivitySelector(ConfigService cs, AppConfig config) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          _sensitivityChip('MIN', BlindspotSensitivity.minimal, config, cs),
          const SizedBox(width: 6),
          _sensitivityChip('STD', BlindspotSensitivity.standard, config, cs),
          const SizedBox(width: 6),
          _sensitivityChip('HIGH', BlindspotSensitivity.high, config, cs),
        ],
      ),
    );
  }

  Widget _sensitivityChip(
      String label, BlindspotSensitivity value, AppConfig config, ConfigService cs) {
    final isSelected = config.blindspotSensitivity == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          cs.updateBlindspotSensitivity(value);
          _syncConfigToPi(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentRed.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppTheme.accentRed : AppTheme.borderGray,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTheme.label.copyWith(
                fontSize: 10,
                color: isSelected ? AppTheme.accentRed : Colors.grey,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessSlider(ConfigService cs, AppConfig config) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6, color: AppTheme.accentRed, size: 18),
              const SizedBox(width: 8),
              Text(
                'HUD BRIGHTNESS',
                style: AppTheme.label.copyWith(fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${(config.hudBrightness * 100).toInt()}%',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentRed,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: AppTheme.accentRed,
              overlayColor: AppTheme.accentRed.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 2,
            ),
            child: Slider(
              value: config.hudBrightness,
              onChanged: (v) => cs.updateHudBrightness(v),
              onChangeEnd: (_) => _syncConfigToPi(context),
              min: 0.1,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Widget? child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentRed, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.label.copyWith(fontSize: 11),
                    ),
                    Text(
                      subtitle,
                      style: AppTheme.bodySmall.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (child != null) child,
        ],
      ),
    );
  }

  // ── Element Card (for zone assignment) ──
  Widget _buildElementCard(HUDElement element, int index, AppStateProvider appState) {
    final isActive = element.enabled && element.zone != VisorZone.unassigned;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppTheme.accentRed.withOpacity(0.4) : AppTheme.borderGray,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.accentRed.withOpacity(0.2)
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              element.type.iconData,
              size: 18,
              color: isActive ? AppTheme.accentRed : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.type.label,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  isActive ? '${element.zone.label} zone' : 'Unassigned',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          _buildZoneSelector(element, index, appState),
        ],
      ),
    );
  }

  Widget _buildZoneSelector(HUDElement element, int index, AppStateProvider appState) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _zoneChip('L', VisorZone.left, element, index, appState),
        const SizedBox(width: 4),
        _zoneChip('R', VisorZone.right, element, index, appState),
        const SizedBox(width: 4),
        _zoneChip('✕', VisorZone.unassigned, element, index, appState),
      ],
    );
  }

  Widget _zoneChip(String label, VisorZone zone, HUDElement element,
      int index, AppStateProvider appState) {
    final isSelected = element.zone == zone &&
        (zone == VisorZone.unassigned ? !element.enabled : element.enabled);
    return GestureDetector(
      onTap: () {
        if (zone == VisorZone.unassigned) {
          appState.moveElementToZone(index, VisorZone.unassigned);
        } else if (!element.enabled) {
          if (appState.toggleHUDElement(index)) {
            appState.moveElementToZone(index, zone);
          }
        } else {
          appState.moveElementToZone(index, zone);
        }
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected
              ? (zone == VisorZone.unassigned
                  ? Colors.grey[800]
                  : AppTheme.accentRed)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (zone == VisorZone.unassigned
                    ? Colors.grey[600]!
                    : AppTheme.accentRed)
                : Colors.grey[700]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.textWhite : Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningBanner(AppStateProvider appState) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              appState.safetyWarning!,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => appState.clearSafetyWarning(),
            child: Icon(Icons.close, color: Colors.amber.withOpacity(0.6), size: 16),
          ),
        ],
      ),
    );
  }

  void _syncConfigToPi(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final configService = Provider.of<ConfigService>(context, listen: false);
    if (appState.isConnected) {
      appState.piService.sendConfigSync(configService.config.toJson());
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  FULL-SCREEN VISOR EDITOR
//  - Landscape-style visor covering the entire screen
//  - Draggable icon tray on the left
//  - Tap an icon to place it, drag to reposition
// ═══════════════════════════════════════════════════════════════════════

class _FullScreenVisorEditor extends StatefulWidget {
  final VoidCallback onClose;
  const _FullScreenVisorEditor({required this.onClose});

  @override
  State<_FullScreenVisorEditor> createState() => _FullScreenVisorEditorState();
}

class _FullScreenVisorEditorState extends State<_FullScreenVisorEditor>
    with SingleTickerProviderStateMixin {
  int? _draggingIndex;
  bool _showTray = true;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF020202),
          body: SafeArea(
            child: Stack(
              children: [
                // ── Full-screen visor canvas ──
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildVisorCanvas(
                        constraints.maxWidth,
                        constraints.maxHeight,
                        appState,
                      );
                    },
                  ),
                ),

                // ── Close button (top-right) ──
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.close, color: AppTheme.textWhite, size: 20),
                    ),
                  ),
                ),

                // ── Toggle tray button (top-left) ──
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _showTray = !_showTray),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Icon(
                        _showTray ? Icons.chevron_left : Icons.widgets,
                        color: AppTheme.textWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                // ── Element tray (left sidebar) ──
                if (_showTray)
                  Positioned(
                    left: 0,
                    top: 60,
                    bottom: 0,
                    width: 72,
                    child: _buildElementTray(appState),
                  ),

                // ── Status bar (bottom) ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStatusBar(appState),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisorCanvas(double w, double h, AppStateProvider appState) {
    final leftZoneW = w * 0.30;
    final centerW = w * 0.40;
    final rightStart = w * 0.70;

    return Stack(
      children: [
        // Background zones
        CustomPaint(
          painter: _FullScreenZonePainter(
            leftWidth: leftZoneW,
            centerWidth: centerW,
            rightStart: rightStart,
          ),
          size: Size(w, h),
        ),

        // Scan line
        AnimatedBuilder(
          animation: _scanController,
          builder: (_, __) => CustomPaint(
            painter: _ScanPainter(progress: _scanController.value),
            size: Size(w, h),
          ),
        ),

        // Zone labels
        Positioned(
          top: 12,
          left: leftZoneW / 2 - 16,
          child: _label('LEFT'),
        ),
        Positioned(
          top: 12,
          left: w / 2 - 40,
          child: _label('AR LANE', isCenter: true),
        ),
        Positioned(
          top: 12,
          right: (w - rightStart) / 2 - 20,
          child: _label('RIGHT'),
        ),

        // AR lane placeholder (center)
        Positioned(
          left: leftZoneW + centerW * 0.2,
          top: h * 0.15,
          width: centerW * 0.6,
          height: h * 0.6,
          child: _buildCenterLane(),
        ),

        // Draggable HUD elements
        ..._buildDraggableElements(
          appState, VisorZone.left, 0, leftZoneW, h,
        ),
        ..._buildDraggableElements(
          appState, VisorZone.right, rightStart, w - rightStart, h,
        ),

        // Subtle wireframe grid
        CustomPaint(
          painter: _GridPainter(),
          size: Size(w, h),
        ),
      ],
    );
  }

  List<Widget> _buildDraggableElements(
    AppStateProvider appState,
    VisorZone zone,
    double zoneLeft,
    double zoneWidth,
    double zoneHeight,
  ) {
    final widgets = <Widget>[];
    for (int i = 0; i < appState.hudElements.length; i++) {
      final el = appState.hudElements[i];
      if (!el.enabled || el.zone != zone) continue;

      final isDragging = _draggingIndex == i;
      final px = zoneLeft + el.x * zoneWidth - 24;
      final py = el.y * zoneHeight - 24;

      widgets.add(
        Positioned(
          left: px,
          top: py,
          child: GestureDetector(
            onPanStart: (_) => setState(() => _draggingIndex = i),
            onPanUpdate: (d) {
              final relX = (d.globalPosition.dx - zoneLeft) / zoneWidth;
              final relY = d.globalPosition.dy / zoneHeight;
              appState.updateHUDElementPosition(i, relX, relY);
            },
            onPanEnd: (_) => setState(() => _draggingIndex = null),
            child: AnimatedScale(
              scale: isDragging ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentRed.withOpacity(isDragging ? 0.35 : 0.15),
                  border: Border.all(
                    color: AppTheme.accentRed.withOpacity(isDragging ? 1.0 : 0.5),
                    width: isDragging ? 2.5 : 1.5,
                  ),
                  boxShadow: isDragging
                      ? [
                          BoxShadow(
                            color: AppTheme.accentRed.withOpacity(0.5),
                            blurRadius: 18,
                            spreadRadius: 4,
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(el.type.iconData, size: 18, color: AppTheme.accentRed),
                    Text(
                      el.type.label,
                      style: const TextStyle(
                        fontSize: 6,
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
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
    return widgets;
  }

  Widget _buildElementTray(AppStateProvider appState) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border(
          right: BorderSide(color: AppTheme.accentRed.withOpacity(0.3)),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: List.generate(appState.hudElements.length, (i) {
          final el = appState.hudElements[i];
          final isActive = el.enabled && el.zone != VisorZone.unassigned;
          return GestureDetector(
            onTap: () {
              if (!el.enabled) {
                appState.toggleHUDElement(i);
              } else {
                // Cycle zones: left -> right -> off
                if (el.zone == VisorZone.left) {
                  appState.moveElementToZone(i, VisorZone.right);
                } else if (el.zone == VisorZone.right) {
                  appState.moveElementToZone(i, VisorZone.unassigned);
                } else {
                  appState.moveElementToZone(i, VisorZone.left);
                }
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.accentRed.withOpacity(0.15)
                    : Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? AppTheme.accentRed.withOpacity(0.5)
                      : Colors.grey[800]!,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    el.type.iconData,
                    size: 20,
                    color: isActive ? AppTheme.accentRed : Colors.grey[500],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    el.type.label,
                    style: TextStyle(
                      fontSize: 8,
                      color: isActive ? AppTheme.textWhite : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isActive)
                    Text(
                      el.zone.label,
                      style: TextStyle(
                        fontSize: 7,
                        color: AppTheme.accentRed.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatusBar(AppStateProvider appState) {
    final active = appState.activeElementCount();
    final max = AppStateProvider.maxTotalActiveElements;
    final load = appState.hudLoadPercent();
    final color = load <= 0.5
        ? Colors.green
        : load <= 0.75
            ? Colors.amber
            : AppTheme.accentRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        border: Border(
          top: BorderSide(color: AppTheme.borderGray),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            'HUD LOAD: $active/$max',
            style: AppTheme.label.copyWith(fontSize: 10, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: load,
                backgroundColor: Colors.grey[900],
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Tap icon to toggle zone • Drag to reposition',
            style: AppTheme.bodySmall.copyWith(fontSize: 8, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterLane() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
        color: Colors.amber.withOpacity(0.03),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, color: Colors.amber.withOpacity(0.4), size: 32),
            const SizedBox(height: 4),
            Text(
              'AR LANE\nGUIDANCE',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: Colors.amber.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.lock_outline, color: Colors.amber.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool isCenter = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (isCenter ? Colors.amber : AppTheme.accentRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isCenter ? Colors.amber : AppTheme.accentRed).withOpacity(0.3),
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
}

// ── Painters for the full-screen editor ──

class _FullScreenZonePainter extends CustomPainter {
  final double leftWidth, centerWidth, rightStart;
  _FullScreenZonePainter({
    required this.leftWidth,
    required this.centerWidth,
    required this.rightStart,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF030303),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, leftWidth, size.height),
      Paint()..color = AppTheme.accentRed.withOpacity(0.03),
    );
    canvas.drawRect(
      Rect.fromLTWH(rightStart, 0, size.width - rightStart, size.height),
      Paint()..color = AppTheme.accentRed.withOpacity(0.03),
    );
    canvas.drawRect(
      Rect.fromLTWH(leftWidth, 0, centerWidth, size.height),
      Paint()..color = Colors.amber.withOpacity(0.015),
    );

    final dp = Paint()
      ..color = AppTheme.textWhite.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    _dashed(canvas, Offset(leftWidth, 0), Offset(leftWidth, size.height), dp);
    _dashed(canvas, Offset(rightStart, 0), Offset(rightStart, size.height), dp);
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint p) {
    final len = (b - a).distance;
    final dx = (b.dx - a.dx) / len;
    final dy = (b.dy - a.dy) / len;
    double d = 0;
    while (d < len) {
      final e = math.min(d + 6, len);
      c.drawLine(
        Offset(a.dx + dx * d, a.dy + dy * d),
        Offset(a.dx + dx * e, a.dy + dy * e),
        p,
      );
      d += 10;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanPainter extends CustomPainter {
  final double progress;
  _ScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 8, size.width, 16),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            AppTheme.accentRed.withOpacity(0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, y - 8, size.width, 16)),
    );
  }

  @override
  bool shouldRepaint(_ScanPainter o) => o.progress != progress;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppTheme.textWhite.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
