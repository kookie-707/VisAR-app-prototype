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
                                  label: 'SPEED',
                                  value: appState.isConnected && appState.isRiding
                                      ? '${appState.currentSpeed.toInt()}'
                                      : '--',
                                  unit: 'km/h',
                                  icon: Icons.speed,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: StatCard(
                                  label: 'BATTERY',
                                  value: '${appState.helmetBattery}',
                                  unit: '%',
                                  icon: Icons.battery_charging_full,
                                ),
                              ),
                            ],
                          ),
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
        Text(
          label,
          style: AppTheme.bodyMedium,
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
          ),
        ),
      ],
    );
  }
}
