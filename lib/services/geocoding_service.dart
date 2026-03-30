import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// A place suggestion returned from Nominatim search.
class PlaceSuggestion {
  final String displayName;
  final String shortName;
  final String type; // e.g. 'restaurant', 'city', 'road'
  final LatLng location;
  final double? distanceKm; // distance from user, null if GPS unavailable

  const PlaceSuggestion({
    required this.displayName,
    required this.shortName,
    required this.type,
    required this.location,
    this.distanceKm,
  });
}

/// Haversine distance in km between two lat/lon points.
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // Earth radius in km
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _deg2rad(double deg) => deg * math.pi / 180;

/// Search for places using the free Nominatim (OpenStreetMap) geocoding API.
///
/// [query] is the user's search text.
/// [nearLat]/[nearLon] optionally bias results towards the user's location.
/// Results are sorted nearest-first when location is available.
/// Returns up to 8 suggestions.
Future<List<PlaceSuggestion>> searchPlaces(
  String query, {
  double? nearLat,
  double? nearLon,
}) async {
  if (query.trim().length < 2) return [];

  final params = <String, String>{
    'q': query,
    'format': 'json',
    'limit': '8',
    'addressdetails': '1',
  };

  // Bias towards user location if available
  if (nearLat != null && nearLon != null) {
    params['viewbox'] = '${nearLon - 0.5},${nearLat + 0.5},${nearLon + 0.5},${nearLat - 0.5}';
    params['bounded'] = '0'; // prefer but don't restrict
  }

  final url = Uri.https('nominatim.openstreetmap.org', '/search', params);

  try {
    final response = await http.get(
      url,
      headers: {'User-Agent': 'VisAR-App/1.0'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      debugPrint('[Geocode] HTTP ${response.statusCode}');
      return [];
    }

    final results = jsonDecode(response.body) as List;
    final suggestions = results.map((r) {
      final addr = r['address'] as Map<String, dynamic>? ?? {};
      final name = r['name'] as String? ?? '';
      final road = addr['road'] as String? ?? '';
      final city = addr['city'] as String? ??
          addr['town'] as String? ??
          addr['village'] as String? ??
          '';
      final country = addr['country'] as String? ?? '';

      String short;
      if (name.isNotEmpty) {
        short = city.isNotEmpty ? '$name, $city' : name;
      } else if (road.isNotEmpty) {
        short = city.isNotEmpty ? '$road, $city' : road;
      } else {
        short = city.isNotEmpty ? '$city, $country' : r['display_name'] as String;
      }

      final lat = double.parse(r['lat'] as String);
      final lon = double.parse(r['lon'] as String);

      double? dist;
      if (nearLat != null && nearLon != null) {
        dist = _haversineKm(nearLat, nearLon, lat, lon);
      }

      return PlaceSuggestion(
        displayName: r['display_name'] as String,
        shortName: short,
        type: r['type'] as String? ?? 'place',
        location: LatLng(lat, lon),
        distanceKm: dist,
      );
    }).toList();

    // Sort nearest first when user location is available
    if (nearLat != null && nearLon != null) {
      suggestions.sort((a, b) =>
          (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
    }

    return suggestions;
  } catch (e) {
    debugPrint('[Geocode] Error: $e');
    return [];
  }
}
