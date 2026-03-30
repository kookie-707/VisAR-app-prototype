import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geolocator/geolocator.dart';

/// Connection lifecycle states.
enum PiConnectionState {
  disconnected,
  connecting,
  handshaking,
  connected,
  reconnecting,
}

/// Service that manages the WebSocket connection to the Raspberry Pi.
///
/// Implements:
///   - Structured message protocol (ts, seq on every message)
///   - Handshake + capability exchange
///   - Heartbeat / ping-pong (2s interval, 3 misses = reconnect)
///   - Exponential backoff reconnect (1s → 2s → 4s → 8s → max 30s)
///   - Enriched GPS stream (lat, lon, heading, speed, accuracy)
class PiConnectionService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  StreamSubscription<Position>? _gpsSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  // ── Protocol state ──
  int _seq = 0;
  int _missedHeartbeats = 0;
  int _reconnectAttempts = 0;
  static const int _maxMissedHeartbeats = 3;
  static const int _maxReconnectDelay = 30;

  // ── Connection state ──
  String _piAddress = '';
  PiConnectionState _connectionState = PiConnectionState.disconnected;
  Map<String, dynamic>? _lastRouteMessage;

  PiConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == PiConnectionState.connected;
  String get piAddress => _piAddress;

  // ── Latest telemetry from Pi ──
  double fps = 0;
  String fcwStatus = 'NORMAL';
  String navStep = '';
  String navArrow = 'STRAIGHT';
  double navDistM = 0;
  int detectionCount = 0;
  double laneConfidence = 0;
  String systemMode = 'DISCONNECTED';

  // ── ESP32 Telemetry ──
  double leanDeg = 0;
  String blindspotLeft = 'CLEAR';
  String blindspotRight = 'CLEAR';
  bool leftPresent = false;
  bool rightPresent = false;
  String esp32Mode = 'STILL';

  // ── Callbacks ──
  VoidCallback? onTelemetryUpdate;
  VoidCallback? onConnectionChanged;

  // ────────────────────────────────────────────────────────────────── //
  //  Connection lifecycle                                              //
  // ────────────────────────────────────────────────────────────────── //

  void connect(String ipAddress) {
    disconnect();
    _piAddress = ipAddress;
    _reconnectAttempts = 0;
    _attemptConnect();
  }

  void _attemptConnect() {
    _setConnectionState(PiConnectionState.connecting);
    final uri = Uri.parse('ws://$_piAddress:8765');

    try {
      _channel = WebSocketChannel.connect(uri);
      
      // Await connection before listening to catch immediate rejections
      _channel!.ready.then((_) {
        _subscription = _channel!.stream.listen(
          (message) => _handleMessage(message as String),
          onDone: () {
            debugPrint('[Pi] WebSocket closed');
            _onDisconnect();
          },
          onError: (error) {
            debugPrint('[Pi] WebSocket error: $error');
            _onDisconnect();
          },
        );

        // Send handshake immediately
        _setConnectionState(PiConnectionState.handshaking);
        _sendRaw({
          'type': 'handshake',
          'app_version': '0.2.0',
          'capabilities': ['gps', 'route', 'heading'],
          'ts': _now(),
          'seq': _nextSeq(),
        });

        // Start heartbeat timer
        _startHeartbeat();

        // Assume connected after handshake sent (Pi ack is best-effort)
        _setConnectionState(PiConnectionState.connected);
        _reconnectAttempts = 0;
        debugPrint('[Pi] Connected to $uri');
      }).catchError((e) {
        debugPrint('[Pi] Connection ready failed: $e');
        _scheduleReconnect();
      });

    } catch (e) {
      debugPrint('[Pi] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void _onDisconnect() {
    _stopHeartbeat();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;

    if (_connectionState != PiConnectionState.disconnected) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _setConnectionState(PiConnectionState.reconnecting);
    _reconnectAttempts++;
    final delay = _reconnectDelay();
    debugPrint('[Pi] Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), _attemptConnect);
  }

  int _reconnectDelay() {
    // Exponential backoff: 1, 2, 4, 8, 16, 30, 30, 30...
    final delay = (1 << (_reconnectAttempts - 1).clamp(0, 5));
    return delay.clamp(1, _maxReconnectDelay);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _stopHeartbeat();
    stopGpsStream();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    _setConnectionState(PiConnectionState.disconnected);
  }

  void _setConnectionState(PiConnectionState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    onConnectionChanged?.call();
  }

  // ────────────────────────────────────────────────────────────────── //
  //  Heartbeat                                                         //
  // ────────────────────────────────────────────────────────────────── //

  void _startHeartbeat() {
    _missedHeartbeats = 0;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_connectionState == PiConnectionState.connected) {
        _missedHeartbeats++;
        _sendRaw({
          'type': 'heartbeat',
          'ts': _now(),
          'seq': _nextSeq(),
        });
        if (_missedHeartbeats >= _maxMissedHeartbeats) {
          debugPrint('[Pi] $_maxMissedHeartbeats heartbeats missed → reconnecting');
          _onDisconnect();
        }
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ────────────────────────────────────────────────────────────────── //
  //  Inbound messages from Pi                                          //
  // ────────────────────────────────────────────────────────────────── //

  void _handleMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'heartbeat_ack':
          _missedHeartbeats = 0;
          break;

        case 'handshake_ack':
          _missedHeartbeats = 0;
          debugPrint('[Pi] Handshake acknowledged: ${data['pi_version'] ?? 'unknown'}');
          // Re-send cached route if reconnecting
          if (_lastRouteMessage != null) {
            _sendRaw(_lastRouteMessage!);
            debugPrint('[Pi] Re-sent cached route after reconnect');
          }
          break;

        case 'telemetry':
        case null: // Legacy format (no type field)
          fps = (data['fps'] as num?)?.toDouble() ?? 0;
          fcwStatus = data['fcw'] as String? ?? 'NORMAL';
          navStep = data['nav_step'] as String? ?? '';
          navArrow = data['nav_arrow'] as String? ?? 'STRAIGHT';
          navDistM = (data['nav_dist_m'] as num?)?.toDouble() ?? 0;
          detectionCount = (data['detections'] as num?)?.toInt() ?? 0;
          laneConfidence = (data['lane_confidence'] as num?)?.toDouble() ?? 0;
          systemMode = data['system_mode'] as String? ?? 'UNKNOWN';
          
          // ESP32 Telemetry
          leanDeg = (data['lean_deg'] as num?)?.toDouble() ?? 0;
          blindspotLeft = data['blindspot_left'] as String? ?? 'CLEAR';
          blindspotRight = data['blindspot_right'] as String? ?? 'CLEAR';
          leftPresent = data['left_present'] == true;
          rightPresent = data['right_present'] == true;
          esp32Mode = data['mode'] as String? ?? 'STILL';

          // Reset heartbeat counter on any valid telemetry
          _missedHeartbeats = 0;
          onTelemetryUpdate?.call();
          break;

        default:
          debugPrint('[Pi] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[Pi] Parse error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────── //
  //  Outbound commands to Pi                                           //
  // ────────────────────────────────────────────────────────────────── //

  int _nextSeq() => ++_seq;
  double _now() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  void _sendRaw(Map<String, dynamic> msg) {
    if (_channel != null &&
        (_connectionState == PiConnectionState.connected ||
         _connectionState == PiConnectionState.handshaking)) {
      try {
        _channel!.sink.add(jsonEncode(msg));
      } catch (e) {
        debugPrint('[Pi] Send error: $e');
      }
    }
  }

  /// Tell the Pi to fetch a route between two GPS points.
  void sendNavDestination({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    final msg = {
      'type': 'nav',
      'start_lat': startLat,
      'start_lon': startLon,
      'end_lat': endLat,
      'end_lon': endLon,
      'ts': _now(),
      'seq': _nextSeq(),
    };
    _lastRouteMessage = msg; // Cache for re-send on reconnect
    _sendRaw(msg);
  }

  /// Tell the Pi to advance to the next nav step.
  void advanceNavStep() {
    _sendRaw({
      'type': 'advance_nav',
      'ts': _now(),
      'seq': _nextSeq(),
    });
  }

  // ────────────────────────────────────────────────────────────────── //
  //  GPS streaming (enriched: heading, speed, accuracy)                //
  // ────────────────────────────────────────────────────────────────── //

  /// Start streaming the phone's GPS to the Pi continuously.
  Future<void> startGpsStream() async {
    // Ensure permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[GPS] Permission denied');
      return;
    }

    stopGpsStream();

    // Use position stream instead of polling — more efficient, gets heading/speed
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Minimum 3m movement to trigger update
      ),
    ).listen(
      (Position pos) {
        _sendRaw({
          'type': 'gps',
          'lat': pos.latitude,
          'lon': pos.longitude,
          'heading': pos.heading,
          'speed_mps': pos.speed,
          'accuracy_m': pos.accuracy,
          'ts': _now(),
          'seq': _nextSeq(),
        });
      },
      onError: (e) {
        debugPrint('[GPS] Stream error: $e');
      },
    );
    debugPrint('[GPS] Stream started');
  }

  void stopGpsStream() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
  }

  /// Called when app resumes from background — check and restore connection.
  void onAppResumed() {
    if (_connectionState == PiConnectionState.disconnected ||
        _connectionState == PiConnectionState.reconnecting) {
      // Already trying to reconnect or fully disconnected
      return;
    }
    // Send a ping to check if still alive
    _sendRaw({
      'type': 'heartbeat',
      'ts': _now(),
      'seq': _nextSeq(),
    });
  }

  // ────────────────────────────────────────────────────────────────── //
  //  Config Sync — pushes user preferences to the Pi                   //
  // ────────────────────────────────────────────────────────────────── //

  /// Send the full HUD config to the Pi. Call this:
  ///  - immediately after handshake completes
  ///  - whenever the user changes a setting
  void sendConfigSync(Map<String, dynamic> configJson) {
    final msg = {
      'type': 'config_update',
      ...configJson,
      'ts': _now(),
      'seq': _nextSeq(),
    };
    _sendRaw(msg);
    debugPrint('[Pi] Config sync sent: $configJson');
  }
}
