import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Route data returned from the OSRM routing API.
class RouteResult {
  /// Polyline points to draw on the map.
  final List<LatLng> polyline;

  /// Turn-by-turn steps.
  final List<RouteStep> steps;

  /// Total distance in meters.
  final double distanceM;

  /// Total estimated duration in seconds.
  final double durationS;

  const RouteResult({
    required this.polyline,
    required this.steps,
    required this.distanceM,
    required this.durationS,
  });
}

/// A single turn-by-turn navigation step.
class RouteStep {
  final String instruction;
  final String maneuver; // 'turn-left', 'turn-right', 'straight', etc.
  final double distanceM;
  final double durationS;
  final LatLng location;

  const RouteStep({
    required this.instruction,
    required this.maneuver,
    required this.distanceM,
    required this.durationS,
    required this.location,
  });
}

/// Fetches a driving route from the public OSRM demo server.
///
/// Returns null if the request fails or no route is found.
Future<RouteResult?> fetchRoute(LatLng start, LatLng end) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/'
    '${start.longitude},${start.latitude};'
    '${end.longitude},${end.latitude}'
    '?overview=full&geometries=polyline&steps=true',
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      debugPrint('[Route] HTTP ${response.statusCode}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
      debugPrint('[Route] No routes found');
      return null;
    }

    final route = (data['routes'] as List)[0] as Map<String, dynamic>;
    final geometry = route['geometry'] as String;
    final polyline = _decodePolyline(geometry);

    final legs = route['legs'] as List;
    final steps = <RouteStep>[];
    for (final leg in legs) {
      for (final step in (leg['steps'] as List)) {
        final maneuver = step['maneuver'] as Map<String, dynamic>;
        final location = maneuver['location'] as List;
        final modifier = maneuver['modifier'] as String? ?? '';
        final type = maneuver['type'] as String? ?? '';

        steps.add(RouteStep(
          instruction: step['name'] as String? ?? type,
          maneuver: modifier.isNotEmpty ? '$type-$modifier' : type,
          distanceM: (step['distance'] as num).toDouble(),
          durationS: (step['duration'] as num).toDouble(),
          location: LatLng(
            (location[1] as num).toDouble(),
            (location[0] as num).toDouble(),
          ),
        ));
      }
    }

    return RouteResult(
      polyline: polyline,
      steps: steps,
      distanceM: (route['distance'] as num).toDouble(),
      durationS: (route['duration'] as num).toDouble(),
    );
  } catch (e) {
    debugPrint('[Route] Fetch error: $e');
    return null;
  }
}

/// Decode a Google-encoded polyline string into LatLng coordinates.
List<LatLng> _decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0;
  int lat = 0;
  int lng = 0;

  while (index < encoded.length) {
    int result = 0;
    int shift = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    result = 0;
    shift = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1F) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
