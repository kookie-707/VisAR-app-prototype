import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../widgets/analytics_card.dart';
import '../widgets/racing_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isWeekly = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Stack(
        children: [
          const RacingBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'RIDER PROFILE',
                    style: AppTheme.heading1.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 30),
                  // Profile Header
                  Consumer<AppStateProvider>(
                    builder: (context, appState, _) {
                      return _buildProfileHeader(appState);
                    },
                  ),
                  const SizedBox(height: 30),
                  // Analytics Cards Grid
                  _buildAnalyticsGrid(context),
                  const SizedBox(height: 30),
                  // Performance Graph Section
                  _buildPerformanceGraphSection(),
                  const SizedBox(height: 30),
                  // Riding Style Insight
                  _buildInsightCard(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentRed, width: 2),
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentRed.withOpacity(0.3),
                  AppTheme.accentRed.withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppTheme.accentRed,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RIDER',
                  style: AppTheme.heading2.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'SAFETY SCORE',
                      style: AppTheme.label.copyWith(fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.accentRed),
                      ),
                      child: Text(
                        '${appState.safetyScore.toInt()}',
                        style: AppTheme.heading3.copyWith(
                          color: AppTheme.accentRed,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    label: 'TOTAL RIDES',
                    value: '${appState.totalRides}',
                    icon: Icons.directions_bike,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    label: 'DISTANCE',
                    value: '${appState.totalDistance.toStringAsFixed(1)}',
                    unit: 'km',
                    icon: Icons.straighten,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AnalyticsCard(
                    label: 'AVG SPEED',
                    value: '${appState.averageSpeed.toStringAsFixed(1)}',
                    unit: 'km/h',
                    icon: Icons.speed,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AnalyticsCard(
                    label: 'MAX SPEED',
                    value: '${appState.maxSpeed.toStringAsFixed(1)}',
                    unit: 'km/h',
                    icon: Icons.speed_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnalyticsCard(
              label: 'RIDING TIME',
              value: '${(appState.totalRidingTime / 60).toStringAsFixed(1)}',
              unit: 'hours',
              icon: Icons.timer,
              fullWidth: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceGraphSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERFORMANCE',
                style: AppTheme.heading3.copyWith(fontSize: 16),
              ),
              // Week/Month Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundBlack,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderGray),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton('WEEK', true),
                    _buildToggleButton('MONTH', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              _buildChartData(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isWeekly = label == 'WEEK';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: isSelected ? AppTheme.textWhite : AppTheme.textWhiteSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData() {
    final spots = _isWeekly
        ? [
            const FlSpot(0, 65),
            const FlSpot(1, 72),
            const FlSpot(2, 68),
            const FlSpot(3, 75),
            const FlSpot(4, 70),
            const FlSpot(5, 78),
            const FlSpot(6, 73),
          ]
        : [
            const FlSpot(0, 68),
            const FlSpot(1, 72),
            const FlSpot(2, 70),
            const FlSpot(3, 75),
            const FlSpot(4, 73),
          ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.borderGray,
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                _isWeekly
                    ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt()]
                    : 'W${value.toInt() + 1}',
                style: AppTheme.bodySmall.copyWith(fontSize: 10),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: AppTheme.bodySmall.copyWith(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppTheme.borderGray),
      ),
      minX: 0,
      maxX: _isWeekly ? 6 : 4,
      minY: 60,
      maxY: 80,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.accentRed,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.accentRed.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: AppTheme.accentRed, width: 4),
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
              Icon(
                Icons.auto_awesome,
                color: AppTheme.accentRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'RIDING STYLE INSIGHT',
                style: AppTheme.heading3.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your braking patterns show consistent improvement. Consider maintaining smoother deceleration in corners for optimal safety scores.',
            style: AppTheme.bodyMedium.copyWith(
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundBlack,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.accentRed,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Safety score increased by 5% this week',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
