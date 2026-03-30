import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/pi_connection_service.dart' show PiConnectionState;
import '../services/routing_service.dart';
import '../services/geocoding_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  LatLng? _destinationPin;
  LatLng? _currentGps;
  bool _isNavigating = false;
  bool _locatingUser = false;
  bool _fetchingRoute = false;

  // Route data
  RouteResult? _route;
  int _currentStepIndex = 0;

  // Search state
  List<PlaceSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  Timer? _debounce;
  String? _selectedPlaceName;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text;
    if (query.length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final results = await searchPlaces(
      query,
      nearLat: _currentGps?.latitude,
      nearLon: _currentGps?.longitude,
    );
    if (mounted) {
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
        _isSearching = false;
      });
    }
  }

  void _selectPlace(PlaceSuggestion place) {
    setState(() {
      _destinationPin = place.location;
      _selectedPlaceName = place.shortName;
      _showSuggestions = false;
      _route = null;
      _searchController.text = place.shortName;
    });
    _searchFocus.unfocus();
    _mapController.move(place.location, 15.0);
    if (_currentGps != null) {
      _fetchRoutePreview();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locatingUser = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locatingUser = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentGps = LatLng(pos.latitude, pos.longitude);
        _locatingUser = false;
      });
      _mapController.move(_currentGps!, 15.0);
    } catch (e) {
      debugPrint('[Nav] GPS error: $e');
      setState(() => _locatingUser = false);
    }
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    if (_isNavigating) return;
    _searchFocus.unfocus();
    setState(() {
      _destinationPin = point;
      _selectedPlaceName = null;
      _route = null;
      _showSuggestions = false;
      _searchController.clear();
    });
    // Auto-fetch route preview when destination is set
    if (_currentGps != null) {
      _fetchRoutePreview();
    }
  }

  /// Fetch route for preview (before starting navigation).
  Future<void> _fetchRoutePreview() async {
    if (_currentGps == null || _destinationPin == null) return;
    setState(() => _fetchingRoute = true);

    final result = await fetchRoute(_currentGps!, _destinationPin!);
    if (mounted) {
      setState(() {
        _route = result;
        _fetchingRoute = false;
      });

      // Fit map to show the entire route
      if (result != null && result.polyline.isNotEmpty) {
        _fitMapToRoute(result.polyline);
      }
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  void _startNavigation(AppStateProvider state) {
    if (_currentGps == null) {
      _showSnack('Waiting for GPS fix...');
      return;
    }
    if (_destinationPin == null) {
      _showSnack('Long-press the map to set a destination');
      return;
    }
    if (!state.isConnected) {
      _showSnack('Connect to Pi first from the Home tab');
      return;
    }
    if (_route == null) {
      _showSnack('Fetching route...');
      _fetchRoutePreview();
      return;
    }

    // Send route to Pi
    state.piService.sendNavDestination(
      startLat: _currentGps!.latitude,
      startLon: _currentGps!.longitude,
      endLat: _destinationPin!.latitude,
      endLon: _destinationPin!.longitude,
    );
    state.piService.startGpsStream();
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });
  }

  void _stopNavigation(AppStateProvider state) {
    state.piService.stopGpsStream();
    setState(() {
      _isNavigating = false;
      _destinationPin = null;
      _route = null;
      _currentStepIndex = 0;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _arrowIcon(String maneuver) {
    final m = maneuver.toLowerCase();
    if (m.contains('left')) return Icons.turn_left;
    if (m.contains('right')) return Icons.turn_right;
    if (m.contains('uturn')) return Icons.u_turn_left;
    if (m.contains('arrive')) return Icons.flag;
    if (m.contains('depart')) return Icons.play_arrow;
    if (m.contains('roundabout')) return Icons.rotate_right;
    return Icons.arrow_upward;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(1)} km';
    return '${meters.toInt()} m';
  }

  String _formatDuration(double seconds) {
    final mins = (seconds / 60).round();
    if (mins < 60) return '$mins min';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Consumer<AppStateProvider>(
        builder: (context, state, _) {
          return Stack(
            children: [
              // ── Full-screen Map ──
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentGps ?? const LatLng(25.2048, 55.2708),
                  initialZoom: 14.0,
                  onLongPress: _onMapLongPress,
                  backgroundColor: const Color(0xFF1A1A2E),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.visar.app',
                  ),

                  // ── Route polyline ──
                  if (_route != null && _route!.polyline.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        // Outer glow
                        Polyline(
                          points: _route!.polyline,
                          strokeWidth: 8.0,
                          color: AppTheme.accentRed.withOpacity(0.25),
                        ),
                        // Main route line
                        Polyline(
                          points: _route!.polyline,
                          strokeWidth: 4.0,
                          color: AppTheme.accentRed,
                        ),
                      ],
                    ),

                  // ── Markers ──
                  MarkerLayer(
                    markers: [
                      // Current GPS
                      if (_currentGps != null)
                        Marker(
                          point: _currentGps!,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: const Center(
                              child: Icon(Icons.my_location, color: Colors.blue, size: 18),
                            ),
                          ),
                        ),
                      // Destination pin
                      if (_destinationPin != null)
                        Marker(
                          point: _destinationPin!,
                          width: 40,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: AppTheme.accentRed,
                            size: 40,
                          ),
                        ),
                      // Step markers (during navigation)
                      if (_isNavigating && _route != null)
                        ..._route!.steps.map((step) => Marker(
                              point: step.location,
                              width: 14,
                              height: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            )),
                    ],
                  ),
                ],
              ),

              // ── Top bar + search ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    bottom: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'NAVIGATE',
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.accentRed,
                              fontSize: 18,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          _connectionBadge(state),
                        ],
                      ),
                      if (!_isNavigating) ...[
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Search suggestions dropdown ──
              if (_showSuggestions && !_isNavigating)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 100,
                  left: 16,
                  right: 16,
                  child: _buildSuggestionsDropdown(),
                ),

              // ── GPS locate button ──
              Positioned(
                right: 16,
                bottom: _isNavigating ? 280 : (_route != null ? 240 : 200),
                child: FloatingActionButton(
                  heroTag: 'locate',
                  mini: true,
                  backgroundColor: AppTheme.cardDark,
                  onPressed: _locatingUser ? null : _getCurrentLocation,
                  child: _locatingUser
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentRed,
                          ),
                        )
                      : const Icon(Icons.my_location, color: AppTheme.accentRed, size: 22),
                ),
              ),

              // ── Bottom panel ──
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundBlack.withOpacity(0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: const Border(
                      top: BorderSide(color: AppTheme.borderGray, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Route loading indicator
                      if (_fetchingRoute)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.accentRed,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Fetching route...',
                                style: AppTheme.bodySmall.copyWith(color: Colors.amber),
                              ),
                            ],
                          ),
                        ),

                      // Route summary (before starting)
                      if (_route != null && !_isNavigating)
                        _buildRouteSummaryCard(),

                      // Destination card (no route yet)
                      if (_destinationPin != null && _route == null && !_fetchingRoute)
                        _buildDestinationCard(),

                      // Hint text
                      if (_destinationPin == null && !_isNavigating)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app, color: Colors.grey[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Long-press anywhere on the map to set your destination',
                                  style: AppTheme.bodySmall.copyWith(color: Colors.grey[500]),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Live navigation instruction
                      if (_isNavigating && _route != null) ...[
                        _buildLiveStepCard(),
                        const SizedBox(height: 10),
                        // Step list preview
                        if (_route!.steps.length > 1) _buildStepList(),
                        const SizedBox(height: 10),
                        // Pi telemetry row
                        if (state.isConnected)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _miniStat('FPS', state.piFps.toStringAsFixed(1)),
                              _miniStat('FCW', state.fcwStatus),
                              _miniStat('OBJ', '${state.detectionCount}'),
                              _miniStat('LANE', '${(state.laneConfidence * 100).toInt()}%'),
                            ],
                          ),
                        const SizedBox(height: 10),
                      ],

                      // Navigate button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isNavigating
                              ? () => _stopNavigation(state)
                              : (_destinationPin != null && !_fetchingRoute
                                  ? () => _startNavigation(state)
                                  : null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isNavigating
                                ? Colors.orange[800]
                                : AppTheme.accentRed,
                            disabledBackgroundColor: Colors.grey[900],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isNavigating ? 'STOP NAVIGATION' : 'START NAVIGATION',
                            style: GoogleFonts.orbitron(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Search Widgets ──────────────────────────────────────────── //

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search,
            color: _isSearching ? AppTheme.accentRed : Colors.grey[500],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: AppTheme.bodyMedium.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search for a place...',
                hintStyle: AppTheme.bodySmall.copyWith(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (q) {
                if (q.length >= 2) _performSearch(q);
              },
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.accentRed,
                ),
              ),
            )
          else if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _suggestions = [];
                  _showSuggestions = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.close, color: Colors.grey[500], size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppTheme.borderGray,
          ),
          itemBuilder: (context, index) {
            final place = _suggestions[index];
            return ListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _placeIcon(place.type),
                  size: 16,
                  color: AppTheme.accentRed,
                ),
              ),
              title: Text(
                place.shortName,
                style: AppTheme.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textWhite,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                place.displayName,
                style: AppTheme.bodySmall.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: place.distanceKm != null
                  ? Text(
                      _formatDistance(place.distanceKm! * 1000), // convert km to meters for formatter
                      style: AppTheme.label.copyWith(
                        fontSize: 10,
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
              onTap: () => _selectPlace(place),
            );
          },
        ),
      ),
    );
  }

  IconData _placeIcon(String type) {
    switch (type) {
      case 'restaurant' || 'cafe' || 'fast_food':
        return Icons.restaurant;
      case 'fuel' || 'charging_station':
        return Icons.local_gas_station;
      case 'hotel' || 'motel' || 'hostel':
        return Icons.hotel;
      case 'hospital' || 'clinic' || 'pharmacy':
        return Icons.local_hospital;
      case 'school' || 'university' || 'college':
        return Icons.school;
      case 'supermarket' || 'convenience' || 'mall':
        return Icons.shopping_cart;
      case 'parking':
        return Icons.local_parking;
      case 'city' || 'town' || 'village' || 'suburb':
        return Icons.location_city;
      case 'road' || 'residential' || 'motorway':
        return Icons.add_road;
      default:
        return Icons.place;
    }
  }

  // ─── Helper Widgets ──────────────────────────────────────────── //

  Widget _buildRouteSummaryCard() {
    final r = _route!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          // Route icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
            ),
            child: const Icon(Icons.route, color: AppTheme.accentRed, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUTE FOUND',
                  style: AppTheme.label.copyWith(
                    fontSize: 10,
                    color: AppTheme.accentRed,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.straighten, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDistance(r.distanceM),
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(r.durationS),
                      style: AppTheme.bodyLarge.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.steps.length} steps',
                  style: AppTheme.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _destinationPin = null;
              _route = null;
            }),
            child: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.accentRed, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DESTINATION', style: AppTheme.label.copyWith(fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  '${_destinationPin!.latitude.toStringAsFixed(5)}, '
                  '${_destinationPin!.longitude.toStringAsFixed(5)}',
                  style: AppTheme.bodyMedium.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _destinationPin = null),
            child: Icon(Icons.close, color: Colors.grey[600], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStepCard() {
    if (_route == null || _route!.steps.isEmpty) {
      return const SizedBox.shrink();
    }
    final step = _currentStepIndex < _route!.steps.length
        ? _route!.steps[_currentStepIndex]
        : _route!.steps.last;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentRed, width: 2),
            ),
            child: Icon(
              _arrowIcon(step.maneuver),
              color: AppTheme.accentRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction.isNotEmpty ? step.instruction : step.maneuver,
                  style: AppTheme.bodyMedium.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDistance(step.distanceM),
                  style: GoogleFonts.orbitron(
                    color: AppTheme.accentRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Next step button
          if (_currentStepIndex < _route!.steps.length - 1)
            GestureDetector(
              onTap: () => setState(() => _currentStepIndex++),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
                ),
                child: const Icon(Icons.skip_next, color: AppTheme.accentRed, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepList() {
    final steps = _route!.steps;
    final displaySteps = steps.skip(_currentStepIndex).take(3).toList();

    return Column(
      children: displaySteps.map((step) {
        final idx = steps.indexOf(step);
        final isCurrent = idx == _currentStepIndex;
        return GestureDetector(
          onTap: () => setState(() => _currentStepIndex = idx),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.accentRed.withOpacity(0.1)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AppTheme.accentRed.withOpacity(0.3)
                    : AppTheme.borderGray,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _arrowIcon(step.maneuver),
                  size: 16,
                  color: isCurrent ? AppTheme.accentRed : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.instruction.isNotEmpty ? step.instruction : step.maneuver,
                    style: AppTheme.bodySmall.copyWith(
                      fontSize: 11,
                      color: isCurrent ? AppTheme.textWhite : Colors.grey[400],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatDistance(step.distanceM),
                  style: AppTheme.bodySmall.copyWith(
                    fontSize: 10,
                    color: isCurrent ? AppTheme.accentRed : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _connectionBadge(AppStateProvider state) {
    final connected = state.isConnected;
    final connecting = state.connectionState == PiConnectionState.connecting ||
        state.connectionState == PiConnectionState.reconnecting;
    final color = connected
        ? Colors.green
        : (connecting ? Colors.amber : Colors.grey);
    final label = connected
        ? 'PI LINKED'
        : (connecting ? 'LINKING...' : 'PI OFFLINE');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            color: AppTheme.accentRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTheme.label.copyWith(fontSize: 9)),
      ],
    );
  }
}
