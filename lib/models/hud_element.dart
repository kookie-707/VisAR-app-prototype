import 'package:flutter/material.dart';

enum HUDElementType {
  speed,
  navigation,
  notifications,
  battery,
  alerts,
  weather,
}

enum VisorZone {
  left,
  right,
  unassigned,
}

extension VisorZoneExtension on VisorZone {
  String get label {
    switch (this) {
      case VisorZone.left:
        return 'Left';
      case VisorZone.right:
        return 'Right';
      case VisorZone.unassigned:
        return 'Off';
    }
  }
}

extension HUDElementTypeExtension on HUDElementType {
  String get label {
    switch (this) {
      case HUDElementType.speed:
        return 'Speed';
      case HUDElementType.navigation:
        return 'Navigation';
      case HUDElementType.notifications:
        return 'Notifications';
      case HUDElementType.battery:
        return 'Battery';
      case HUDElementType.alerts:
        return 'Alerts';
      case HUDElementType.weather:
        return 'Weather';
    }
  }

  IconData get iconData {
    switch (this) {
      case HUDElementType.speed:
        return Icons.speed;
      case HUDElementType.navigation:
        return Icons.navigation;
      case HUDElementType.notifications:
        return Icons.notifications_active;
      case HUDElementType.battery:
        return Icons.battery_charging_full;
      case HUDElementType.alerts:
        return Icons.warning_amber;
      case HUDElementType.weather:
        return Icons.cloud;
    }
  }

  int get safetyWeight {
    switch (this) {
      case HUDElementType.speed:
        return 1;
      case HUDElementType.navigation:
        return 1;
      case HUDElementType.battery:
        return 1;
      case HUDElementType.alerts:
        return 2;
      case HUDElementType.notifications:
        return 2;
      case HUDElementType.weather:
        return 1;
    }
  }
}

class HUDElement {
  final HUDElementType type;
  bool enabled;
  VisorZone zone;
  double x; // 0.0 to 1.0 within the zone
  double y; // 0.0 to 1.0 within the zone

  HUDElement({
    required this.type,
    required this.enabled,
    required this.zone,
    required this.x,
    required this.y,
  });
}
