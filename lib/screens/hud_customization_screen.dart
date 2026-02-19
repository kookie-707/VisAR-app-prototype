import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../models/hud_element.dart';
import '../widgets/visor_preview.dart';
import '../widgets/circuit_background.dart';

class HUDCustomizationScreen extends StatelessWidget {
  const HUDCustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Text(
                    'HUD CUSTOMIZATION',
                    style: AppTheme.heading1.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure your AR visor display',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textWhiteSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Safety warning banner
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      if (appState.safetyWarning == null) {
                        return const SizedBox.shrink();
                      }
                      return _buildWarningBanner(context, appState);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Visor preview
                  const VisorPreview(),
                  const SizedBox(height: 24),
                  // Safety guidelines card
                  _buildSafetyGuidelinesCard(),
                  const SizedBox(height: 24),
                  // HUD Element assignment
                  Text(
                    'DISPLAY ELEMENTS',
                    style: AppTheme.heading3.copyWith(
                      fontSize: 16,
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
                            context,
                            appState.hudElements[index],
                            index,
                            appState,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Sliders
                  Text(
                    'DISPLAY SETTINGS',
                    style: AppTheme.heading3.copyWith(
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      return Column(
                        children: [
                          _buildSlider(
                            context,
                            'Brightness',
                            appState.brightness,
                            (v) => appState.updateBrightness(v),
                            Icons.brightness_6,
                          ),
                          const SizedBox(height: 16),
                          _buildSlider(
                            context,
                            'Transparency',
                            appState.transparency,
                            (v) => appState.updateTransparency(v),
                            Icons.opacity,
                          ),
                        ],
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

  // ── Safety warning banner ──
  Widget _buildWarningBanner(BuildContext context, AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Colors.amber, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              appState.safetyWarning!,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => appState.clearSafetyWarning(),
            child: Icon(Icons.close, color: Colors.amber.withOpacity(0.6), size: 18),
          ),
        ],
      ),
    );
  }

  // ── Safety guidelines ──
  Widget _buildSafetyGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Colors.amber, width: 3),
          top: BorderSide(color: AppTheme.borderGray),
          right: BorderSide(color: AppTheme.borderGray),
          bottom: BorderSide(color: AppTheme.borderGray),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'SAFETY GUIDELINES',
                style: AppTheme.heading3.copyWith(fontSize: 13, color: Colors.amber),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _guideline(Icons.block, 'Center zone is reserved for AR lane guidance'),
          _guideline(Icons.grid_view, 'Max ${AppStateProvider.maxElementsPerZone} elements per zone to keep view clear'),
          _guideline(Icons.visibility, 'Max ${AppStateProvider.maxTotalActiveElements} total active elements for safe riding'),
          _guideline(Icons.space_bar, 'Elements auto-space to prevent overlap'),
        ],
      ),
    );
  }

  Widget _guideline(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[500], size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Element card with zone selector ──
  Widget _buildElementCard(
    BuildContext context,
    HUDElement element,
    int index,
    AppStateProvider appState,
  ) {
    final isActive = element.enabled && element.zone != VisorZone.unassigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppTheme.accentRed.withOpacity(0.5)
              : AppTheme.borderGray,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.accentRed.withOpacity(0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.accentRed.withOpacity(0.2)
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? AppTheme.accentRed : Colors.grey[700]!,
              ),
            ),
            child: Icon(
              element.type.iconData,
              size: 20,
              color: isActive ? AppTheme.accentRed : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          // Label + zone info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  element.type.label,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? '${element.zone.label} zone  •  Drag to reposition'
                      : 'Assign to a zone to enable',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          // Zone selector chips
          _buildZoneSelector(context, element, index, appState),
        ],
      ),
    );
  }

  Widget _buildZoneSelector(
    BuildContext context,
    HUDElement element,
    int index,
    AppStateProvider appState,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _zoneChip(context, 'L', VisorZone.left, element, index, appState),
        const SizedBox(width: 4),
        _zoneChip(context, 'R', VisorZone.right, element, index, appState),
        const SizedBox(width: 4),
        _zoneChip(context, '✕', VisorZone.unassigned, element, index, appState),
      ],
    );
  }

  Widget _zoneChip(
    BuildContext context,
    String label,
    VisorZone zone,
    HUDElement element,
    int index,
    AppStateProvider appState,
  ) {
    final isSelected = element.zone == zone && (zone == VisorZone.unassigned ? !element.enabled : element.enabled);

    return GestureDetector(
      onTap: () {
        if (zone == VisorZone.unassigned) {
          appState.moveElementToZone(index, VisorZone.unassigned);
        } else {
          if (!element.enabled) {
            final toggled = appState.toggleHUDElement(index);
            if (toggled) {
              appState.moveElementToZone(index, zone);
            }
          } else {
            appState.moveElementToZone(index, zone);
          }
        }
      },
      child: Container(
        width: 30,
        height: 30,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  // ── Slider ──
  Widget _buildSlider(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentRed, size: 20),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: AppTheme.heading3.copyWith(fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toInt()}%',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accentRed,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: AppTheme.accentRed,
              overlayColor: AppTheme.accentRed.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0.0,
              max: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
