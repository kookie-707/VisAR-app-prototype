import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

/// Manages loading, saving, and broadcasting HUD configuration changes.
///
/// This service is the ONLY place that touches SharedPreferences for config.
/// Widgets interact with [AppConfig] through this service, never directly.
class ConfigService extends ChangeNotifier {
  static const String _storageKey = 'visar_hud_prefs_v1';

  AppConfig _config = AppConfig.defaults();
  AppConfig get config => _config;

  /// Must be called once during app startup (before runApp or inside main).
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _config = AppConfig.decode(raw);
        debugPrint('[ConfigService] Loaded: $_config');
      } else {
        debugPrint('[ConfigService] No saved config, using defaults');
      }
    } catch (e) {
      debugPrint('[ConfigService] Init error, using defaults: $e');
      _config = AppConfig.defaults();
    }
  }

  /// Update the config, persist it, and notify listeners.
  Future<void> update(AppConfig newConfig) async {
    _config = newConfig;
    notifyListeners();
    await _persist();
  }

  /// Convenience: update a single field via copyWith.
  Future<void> updateBlindspotEnabled(bool value) =>
      update(_config.copyWith(blindspotEnabled: value));

  Future<void> updateBlindspotSensitivity(BlindspotSensitivity value) =>
      update(_config.copyWith(blindspotSensitivity: value));

  Future<void> updateHudBrightness(double value) =>
      update(_config.copyWith(hudBrightness: value));

  Future<void> updateNavCueStyle(NavCueStyle value) =>
      update(_config.copyWith(navCueStyle: value));

  Future<void> updateFcwEnabled(bool value) =>
      update(_config.copyWith(fcwEnabled: value));

  /// Write current config to SharedPreferences.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _config.encode());
      debugPrint('[ConfigService] Saved config');
    } catch (e) {
      debugPrint('[ConfigService] Persist error: $e');
    }
  }
}
