import 'package:flutter/foundation.dart';
import '../models/hud_element.dart';
import '../models/app_config.dart';
import '../services/pi_connection_service.dart';

class AppStateProvider extends ChangeNotifier {
  // ── Pi Connection Service ──
  final PiConnectionService piService = PiConnectionService();

  // ── Connection State ──
  PiConnectionState get connectionState => piService.connectionState;
  bool get isConnected => piService.isConnected;

  // ── Ride Data ──
  bool _isRiding = false;
  bool get isRiding => _isRiding;

  // ── Live Pi Telemetry ──
  double get piFps => piService.fps;
  String get fcwStatus => piService.fcwStatus;
  String get navStep => piService.navStep;
  String get navArrow => piService.navArrow;
  double get navDistM => piService.navDistM;
  int get detectionCount => piService.detectionCount;
  double get laneConfidence => piService.laneConfidence;
  String get systemMode => piService.systemMode;

  // ── ESP32 Telemetry ──
  double get esp32LeanDeg => piService.leanDeg;
  String get esp32BlindspotLeft => piService.blindspotLeft;
  String get esp32BlindspotRight => piService.blindspotRight;
  bool get esp32LeftPresent => piService.leftPresent;
  bool get esp32RightPresent => piService.rightPresent;
  String get esp32Mode => piService.esp32Mode;

  String piIpAddress = '192.168.1.70';

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

  // ── Analytics Data (Placeholder — will be replaced with local DB later) ──
  int get totalRides => 0;
  double get totalDistance => 0;
  double get averageSpeed => 0;
  double get maxSpeed => 0;
  int get totalRidingTime => 0;
  double get safetyScore => 0;

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
  void connectToPi(String ipAddress, {AppConfig? config}) {
    piIpAddress = ipAddress;
    piService.onTelemetryUpdate = () {
      notifyListeners();
    };
    piService.onConnectionChanged = () {
      if (!piService.isConnected) {
        _isRiding = false;
      } else if (piService.isConnected && config != null) {
        // Auto-sync config on every successful connection
        piService.sendConfigSync(config!.toJson());
      }
      notifyListeners();
    };
    piService.connect(ipAddress);
  }

  void disconnectPi() {
    piService.stopGpsStream();
    piService.disconnect();
    _isRiding = false;
    notifyListeners();
  }

  void toggleConnection({AppConfig? config}) {
    if (isConnected) {
      disconnectPi();
    } else {
      connectToPi(piIpAddress, config: config);
    }
  }

  void startRide() {
    if (isConnected && !_isRiding) {
      _isRiding = true;
      piService.startGpsStream();
      notifyListeners();
    }
  }

  void stopRide() {
    if (_isRiding) {
      _isRiding = false;
      piService.stopGpsStream();
      notifyListeners();
    }
  }

  /// Handle app lifecycle resume.
  void onAppResumed() {
    piService.onAppResumed();
  }

  // ── HUD Element management (unchanged) ──

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
