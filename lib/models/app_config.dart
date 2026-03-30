import 'dart:convert';

/// HUD configuration preferences that get persisted locally
/// and synced to the Pi on connect.
class AppConfig {
  static const int schemaVersion = 1;

  // ── Blind-spot Settings ──
  final bool blindspotEnabled;
  final BlindspotSensitivity blindspotSensitivity;

  // ── HUD Display Settings ──
  final double hudBrightness; // 0.0 – 1.0
  final NavCueStyle navCueStyle;

  // ── FCW Settings ──
  final bool fcwEnabled;

  const AppConfig({
    this.blindspotEnabled = true,
    this.blindspotSensitivity = BlindspotSensitivity.standard,
    this.hudBrightness = 0.8,
    this.navCueStyle = NavCueStyle.detailed,
    this.fcwEnabled = true,
  });

  /// Safe defaults used on first launch or corrupted data.
  factory AppConfig.defaults() => const AppConfig();

  /// Deserialize from JSON stored in SharedPreferences.
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    // Schema version check – if missing or mismatched, merge with defaults.
    final version = json['schema_version'] as int? ?? 0;
    if (version != schemaVersion) {
      // Future migration logic goes here.
      // For now, just use defaults for missing keys.
    }

    return AppConfig(
      blindspotEnabled: json['blindspot_enabled'] as bool? ?? true,
      blindspotSensitivity: BlindspotSensitivity.fromString(
        json['blindspot_sensitivity'] as String? ?? 'standard',
      ),
      hudBrightness: (json['hud_brightness'] as num?)?.toDouble() ?? 0.8,
      navCueStyle: NavCueStyle.fromString(
        json['nav_cue_style'] as String? ?? 'detailed',
      ),
      fcwEnabled: json['fcw_enabled'] as bool? ?? true,
    );
  }

  /// Serialize to JSON for SharedPreferences and Pi sync.
  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'blindspot_enabled': blindspotEnabled,
        'blindspot_sensitivity': blindspotSensitivity.name,
        'hud_brightness': hudBrightness,
        'nav_cue_style': navCueStyle.name,
        'fcw_enabled': fcwEnabled,
      };

  /// Encode to a single JSON string for SharedPreferences storage.
  String encode() => jsonEncode(toJson());

  /// Decode from a JSON string stored in SharedPreferences.
  static AppConfig decode(String raw) {
    try {
      return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppConfig.defaults();
    }
  }

  /// Create a modified copy.
  AppConfig copyWith({
    bool? blindspotEnabled,
    BlindspotSensitivity? blindspotSensitivity,
    double? hudBrightness,
    NavCueStyle? navCueStyle,
    bool? fcwEnabled,
  }) {
    return AppConfig(
      blindspotEnabled: blindspotEnabled ?? this.blindspotEnabled,
      blindspotSensitivity: blindspotSensitivity ?? this.blindspotSensitivity,
      hudBrightness: hudBrightness ?? this.hudBrightness,
      navCueStyle: navCueStyle ?? this.navCueStyle,
      fcwEnabled: fcwEnabled ?? this.fcwEnabled,
    );
  }

  @override
  String toString() => 'AppConfig(${toJson()})';
}

/// Blind-spot radar sensitivity presets.
enum BlindspotSensitivity {
  minimal,   // Only DANGER triggers alerts
  standard,  // APPROACH + DANGER trigger alerts
  high;      // FAR + APPROACH + DANGER trigger alerts

  static BlindspotSensitivity fromString(String s) {
    switch (s) {
      case 'minimal':
        return BlindspotSensitivity.minimal;
      case 'high':
        return BlindspotSensitivity.high;
      default:
        return BlindspotSensitivity.standard;
    }
  }
}

/// Navigation cue display style.
enum NavCueStyle {
  minimal,   // Arrow only
  detailed;  // Arrow + distance + street name

  static NavCueStyle fromString(String s) {
    switch (s) {
      case 'minimal':
        return NavCueStyle.minimal;
      default:
        return NavCueStyle.detailed;
    }
  }
}
