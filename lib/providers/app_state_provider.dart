import 'package:flutter/foundation.dart';
import '../models/hud_element.dart';

class AppStateProvider extends ChangeNotifier {
  // ── Connection State ──
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ── Ride Data ──
  double _currentSpeed = 0.0;
  int _helmetBattery = 85;
  bool _isRiding = false;

  double get currentSpeed => _currentSpeed;
  int get helmetBattery => _helmetBattery;
  bool get isRiding => _isRiding;

  // ── Safety Constants ──
  static const int maxElementsPerZone = 3;
  static const int maxTotalActiveElements = 4;
  static const double minElementSpacing = 0.18;

  // ── HUD Elements ──
  final List<HUDElement> _hudElements = [
    HUDElement(type: HUDElementType.speed, enabled: true, zone: VisorZone.left, x: 0.5, y: 0.25),
    HUDElement(type: HUDElementType.navigation, enabled: false, zone: VisorZone.unassigned, x: 0.5, y: 0.5),
    HUDElement(type: HUDElementType.notifications, enabled: true, zone: VisorZone.right, x: 0.5, y: 0.25),
    HUDElement(type: HUDElementType.battery, enabled: true, zone: VisorZone.right, x: 0.5, y: 0.7),
    HUDElement(type: HUDElementType.alerts, enabled: true, zone: VisorZone.left, x: 0.5, y: 0.7),
    HUDElement(type: HUDElementType.weather, enabled: false, zone: VisorZone.unassigned, x: 0.5, y: 0.5),
  ];

  List<HUDElement> get hudElements => _hudElements;

  // ── HUD Settings ──
  double _brightness = 0.8;
  double _transparency = 0.3;

  double get brightness => _brightness;
  double get transparency => _transparency;

  // ── Safety Warning ──
  String? _safetyWarning;
  String? get safetyWarning => _safetyWarning;

  void clearSafetyWarning() {
    _safetyWarning = null;
    notifyListeners();
  }

  // ── Analytics Data ──
  int _totalRides = 47;
  double _totalDistance = 2847.5;
  double _averageSpeed = 68.5;
  double _maxSpeed = 142.3;
  int _totalRidingTime = 1245;
  double _safetyScore = 87.5;

  int get totalRides => _totalRides;
  double get totalDistance => _totalDistance;
  double get averageSpeed => _averageSpeed;
  double get maxSpeed => _maxSpeed;
  int get totalRidingTime => _totalRidingTime;
  double get safetyScore => _safetyScore;

  // ── Derived ──
  int activeElementCount() =>
      _hudElements.where((e) => e.enabled && e.zone != VisorZone.unassigned).length;

  int elementsInZone(VisorZone zone) =>
      _hudElements.where((e) => e.enabled && e.zone == zone).length;

  int totalSafetyWeight() => _hudElements
      .where((e) => e.enabled && e.zone != VisorZone.unassigned)
      .fold(0, (sum, e) => sum + e.type.safetyWeight);

  double hudLoadPercent() {
    final maxWeight = maxTotalActiveElements * 2;
    return (totalSafetyWeight() / maxWeight).clamp(0.0, 1.0);
  }

  // ── Methods ──
  void toggleConnection() {
    _isConnected = !_isConnected;
    if (!_isConnected) {
      _isRiding = false;
      _currentSpeed = 0.0;
    }
    notifyListeners();
  }

  void startRide() {
    if (_isConnected && !_isRiding) {
      _isRiding = true;
      notifyListeners();
    }
  }

  void stopRide() {
    if (_isRiding) {
      _isRiding = false;
      _currentSpeed = 0.0;
      notifyListeners();
    }
  }

  void updateSpeed(double speed) {
    if (_isRiding) {
      _currentSpeed = speed;
      notifyListeners();
    }
  }

  void updateBattery(int battery) {
    _helmetBattery = battery;
    notifyListeners();
  }

  /// Toggle element on/off. Returns false + sets warning if blocked by safety.
  bool toggleHUDElement(int index) {
    final element = _hudElements[index];
    _safetyWarning = null;

    if (!element.enabled) {
      if (activeElementCount() >= maxTotalActiveElements) {
        _safetyWarning =
            'Maximum $maxTotalActiveElements active HUD elements allowed for safe riding. '
            'Disable another element first.';
        notifyListeners();
        return false;
      }
      element.enabled = true;
      if (element.zone == VisorZone.unassigned) {
        final leftCount = elementsInZone(VisorZone.left);
        final rightCount = elementsInZone(VisorZone.right);
        element.zone = leftCount <= rightCount ? VisorZone.left : VisorZone.right;
        _autoPositionInZone(index);
      }
    } else {
      element.enabled = false;
      element.zone = VisorZone.unassigned;
    }
    notifyListeners();
    return true;
  }

  /// Move element to a new zone. Returns false + sets warning if zone full.
  bool moveElementToZone(int index, VisorZone newZone) {
    final element = _hudElements[index];
    _safetyWarning = null;

    if (newZone == VisorZone.unassigned) {
      element.enabled = false;
      element.zone = VisorZone.unassigned;
      notifyListeners();
      return true;
    }

    if (element.zone == newZone) return true;

    if (elementsInZone(newZone) >= maxElementsPerZone) {
      _safetyWarning =
          'Maximum $maxElementsPerZone elements per zone for safe visibility. '
          'Remove an element from the ${newZone.label} zone first.';
      notifyListeners();
      return false;
    }

    element.zone = newZone;
    element.enabled = true;
    _autoPositionInZone(index);
    notifyListeners();
    return true;
  }

  /// Update position within zone, checking for overlap.
  bool updateHUDElementPosition(int index, double x, double y) {
    final element = _hudElements[index];

    final clampedX = x.clamp(0.1, 0.9);
    final clampedY = y.clamp(0.1, 0.9);

    for (int i = 0; i < _hudElements.length; i++) {
      if (i == index) continue;
      final other = _hudElements[i];
      if (!other.enabled || other.zone != element.zone) continue;

      final dx = (clampedX - other.x).abs();
      final dy = (clampedY - other.y).abs();
      final dist = (dx * dx + dy * dy);
      if (dist < minElementSpacing * minElementSpacing) {
        return false;
      }
    }

    element.x = clampedX;
    element.y = clampedY;
    notifyListeners();
    return true;
  }

  void _autoPositionInZone(int index) {
    final element = _hudElements[index];
    final sameZone = <int>[];
    for (int i = 0; i < _hudElements.length; i++) {
      if (i == index) continue;
      if (_hudElements[i].enabled && _hudElements[i].zone == element.zone) {
        sameZone.add(i);
      }
    }

    final slots = [0.2, 0.5, 0.8];
    for (final slotY in slots) {
      bool occupied = false;
      for (final i in sameZone) {
        if ((_hudElements[i].y - slotY).abs() < minElementSpacing) {
          occupied = true;
          break;
        }
      }
      if (!occupied) {
        element.x = 0.5;
        element.y = slotY;
        return;
      }
    }
    element.x = 0.5;
    element.y = 0.5;
  }

  void updateBrightness(double value) {
    _brightness = value;
    notifyListeners();
  }

  void updateTransparency(double value) {
    _transparency = value;
    notifyListeners();
  }
}
