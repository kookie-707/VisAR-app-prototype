import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/racing_background.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          // Background Pattern
          const RacingBackground(),
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'VISAR',
                    style: AppTheme.heading1.copyWith(
                      color: AppTheme.accentRed,
                      fontSize: 42,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SMART HELMET',
                    style: AppTheme.label.copyWith(
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Connection Status
                  const ConnectionStatusWidget(),
                  const SizedBox(height: 40),
                  // Quick Stats Cards
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: 'PI FPS',
                                  value: appState.isConnected
                                      ? appState.piFps.toStringAsFixed(1)
                                      : '--',
                                  unit: 'fps',
                                  icon: Icons.speed,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  label: 'OBJECTS',
                                  value: appState.isConnected
                                      ? '${appState.detectionCount}'
                                      : '--',
                                  unit: 'detected',
                                  icon: Icons.visibility,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: StatCard(
                                  label: 'LEAN',
                                  value: appState.isConnected
                                      ? '${appState.esp32LeanDeg.toStringAsFixed(1)}°'
                                      : '--',
                                  unit: 'deg',
                                  icon: Icons.screen_rotation,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  label: 'ESP MODE',
                                  value: appState.isConnected
                                      ? appState.esp32Mode
                                      : '--',
                                  unit: '',
                                  icon: Icons.memory,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Blindspot Radar Visual
                          _buildBlindspotWidget(appState),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // Start Ride Button
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: appState.isConnected && !appState.isRiding
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.accentRed.withOpacity(
                                          0.3 + (_pulseController.value * 0.3),
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ElevatedButton(
                              onPressed: appState.isConnected
                                  ? () {
                                      if (appState.isRiding) {
                                        appState.stopRide();
                                      } else {
                                        appState.startRide();
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentRed,
                                disabledBackgroundColor: Colors.grey[900],
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                appState.isRiding ? 'STOP RIDE' : 'START RIDE',
                                style: AppTheme.heading3.copyWith(
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  // Additional Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGray),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.accentRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SYSTEM STATUS',
                              style: AppTheme.heading3.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Consumer<AppStateProvider>(
                          builder: (context, appState, _) {
                            return Column(
                              children: [
                                _buildStatusRow(
                                  'Helmet Connection',
                                  appState.isConnected ? 'Active' : 'Disconnected',
                                  appState.isConnected,
                                ),
                                const SizedBox(height: 8),
                                _buildStatusRow(
                                  'Ride Status',
                                  appState.isRiding ? 'In Progress' : 'Standby',
                                  appState.isRiding,
                                ),
                                const SizedBox(height: 8),
                                _buildStatusRow(
                                  'HUD Elements',
                                  '${appState.activeElementCount()}/${AppStateProvider.maxTotalActiveElements} Active',
                                  true,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isActive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.accentRed.withOpacity(0.2)
                : Colors.grey[900],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isActive ? AppTheme.accentRed : Colors.grey[700]!,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              color: isActive ? AppTheme.accentRed : Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
            softWrap: false,
            overflow: TextOverflow.fade,
          ),
        ),
      ],
    );
  }

  Widget _buildBlindspotWidget(AppStateProvider appState) {
    final left = appState.isConnected ? appState.esp32BlindspotLeft : 'CLEAR';
    final right = appState.isConnected ? appState.esp32BlindspotRight : 'CLEAR';
    final leftPresent = appState.isConnected ? appState.esp32LeftPresent : false;
    final rightPresent = appState.isConnected ? appState.esp32RightPresent : false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BLINDSPOT RADAR',
                style: AppTheme.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              Icon(Icons.radar, size: 18, color: AppTheme.accentRed),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Left Side
              Expanded(child: _buildRadarSide('LEFT', left, leftPresent)),
              // Center divider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_motorsports,
                      color: Colors.grey[400],
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey[700],
                    ),
                  ],
                ),
              ),
              // Right Side
              Expanded(child: _buildRadarSide('RIGHT', right, rightPresent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSide(String side, String zone, bool present) {
    Color zoneColor;
    String zoneLabel;
    IconData zoneIcon;

    switch (zone) {
      case 'BLIND':
        zoneColor = Colors.red;
        zoneLabel = 'DANGER';
        zoneIcon = Icons.warning;
        break;
      case 'APPROACH':
        zoneColor = Colors.orange;
        zoneLabel = 'APPROACH';
        zoneIcon = Icons.trending_flat;
        break;
      case 'FAR':
        zoneColor = Colors.blue;
        zoneLabel = 'FAR';
        zoneIcon = Icons.remove_circle_outline;
        break;
      default:
        zoneColor = Colors.green;
        zoneLabel = 'CLEAR';
        zoneIcon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: zoneColor.withOpacity(present ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: zoneColor.withOpacity(present ? 0.6 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            side,
            style: AppTheme.label.copyWith(
              fontSize: 10,
              letterSpacing: 1,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 6),
          Icon(zoneIcon, color: zoneColor, size: 24),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              zoneLabel,
              style: AppTheme.heading3.copyWith(
                fontSize: 14,
                color: zoneColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
