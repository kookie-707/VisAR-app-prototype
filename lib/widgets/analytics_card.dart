import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final bool fullWidth;

  const AnalyticsCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.label.copyWith(
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                icon,
                size: 18,
                color: AppTheme.accentRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTheme.heading2.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit!,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
