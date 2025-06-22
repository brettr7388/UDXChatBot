import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../widgets/chatbot_dialog.dart';
import '../services/location_service.dart';
import 'dart:math' as math;
import '../services/recommendation_service.dart';
import '../services/directions_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isLocationLoading = true;
  bool _mapReady = false;
  String? _mapError;
  BitmapDescriptor? _lighthouseIcon;
  BitmapDescriptor? _globeIcon;
  
  // Direction path variables
  Set<Polyline> _polylines = {};
  String? _currentDirectionFrom;
  String? _currentDirectionTo;
  
  // Directions panel variables
  String? _selectedFromRide;
  String? _selectedToRide;
  bool _showDirectionsPanel = false;
  
  // Universal Orlando coordinates
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(28.4744, -81.4687), // Universal Orlando Resort center
    zoom: 13.0,
  );

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
    _checkLocationStatus();
  }

  Future<void> _createCustomMarkers() async {
    try {
      _lighthouseIcon = await _createEmojiMarker('🦕', Colors.green[700]!);
      _globeIcon = await _createEmojiMarker('🌍', Colors.blue[600]!);
      if (mounted) {
        setState(() {}); // Refresh to show new icons
      }
    } catch (e) {
      debugPrint('Error creating custom markers: $e');
      // Continue without custom markers - will use default markers
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<BitmapDescriptor> _createEmojiMarker(String emoji, Color backgroundColor) async {
    try {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      const double size = 120;
      const double emojiSize = 48;

      // Draw circle background
      final Paint backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      
      final Paint borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;

      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 3,
        backgroundPaint,
      );
      
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 3,
        borderPaint,
      );

      // Draw emoji
      final textPainter = TextPainter(
        text: TextSpan(
          text: emoji,
          style: const TextStyle(
            fontSize: emojiSize,
            fontFamily: 'AppleColorEmoji',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size - textPainter.width) / 2,
          (size - textPainter.height) / 2 - 4,
        ),
      );

      final ui.Picture picture = pictureRecorder.endRecording();
      final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(uint8List);
    } catch (e) {
      debugPrint('Error creating emoji marker for $emoji: $e');
      // Return default marker as fallback
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Park markers
  Set<Marker> get _markers => {
    Marker(
      markerId: const MarkerId('islands_of_adventure'),
      position: const LatLng(28.4722, -81.4708),
      icon: _lighthouseIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: 'Islands of Adventure',
        snippet: 'Tap to explore rides',
      ),
      onTap: () => _onMarkerTapped(const MarkerId('islands_of_adventure')),
    ),
    Marker(
      markerId: const MarkerId('universal_studios'),
      position: const LatLng(28.4766, -81.4677),
      icon: _globeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Universal Studios Florida',
        snippet: 'Tap to explore rides',
      ),
      onTap: () => _onMarkerTapped(const MarkerId('universal_studios')),
    ),
  };

  void _checkLocationStatus() {
    // Listen to location updates to stop loading indicator once location is found
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    });
    
    // Add a safety timeout for map loading
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_mapReady) {
        debugPrint('Map loading timeout - forcing map ready state');
        setState(() {
          _mapReady = true;
          _mapError = 'Map loading timeout. Tap to refresh.';
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    debugPrint('Google Map created successfully');
    
    // Add a small delay to ensure the map is fully initialized
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _mapReady = true;
        });
        debugPrint('Map ready state set to true');
      }
    });
  }

  void _onMarkerTapped(MarkerId markerId) {
    // Zoom into the selected park
    LatLng target;
    double zoom = 15.5;
    
    switch (markerId.value) {
      case 'islands_of_adventure':
        target = const LatLng(28.4722, -81.4708);
        break;
      case 'universal_studios':
        target = const LatLng(28.4766, -81.4677);
        break;
      default:
        return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void _zoomIn() async {
    if (_mapController != null) {
      final currentZoom = await _mapController!.getZoomLevel();
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(currentZoom + 1),
      );
    }
  }

  void _zoomOut() async {
    if (_mapController != null) {
      final currentZoom = await _mapController!.getZoomLevel();
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(currentZoom - 1),
      );
    }
  }

  void _centerOnUserLocation() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final userLocation = locationService.currentLocationLatLng;
    
    if (userLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLocation,
            zoom: 17.0,
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Centered on your location: ${userLocation.latitude.toStringAsFixed(4)}, ${userLocation.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Try to refresh location first
      _refreshLocationAndCenter();
    }
  }

  void _refreshLocationAndCenter() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // Try to refresh location
    await locationService.refreshLocation();
    
    // Wait a moment for the location to update
    await Future.delayed(const Duration(milliseconds: 500));
    
    final userLocation = locationService.currentLocationLatLng;
    if (userLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLocation,
            zoom: 17.0,
          ),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found your location: ${userLocation.latitude.toStringAsFixed(4)}, ${userLocation.longitude.toStringAsFixed(4)}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // As a last resort, use the camera position if user has moved the map
      _getCameraLocationAsFallback();
    }
  }

  void _getCameraLocationAsFallback() async {
    if (_mapController != null) {
      try {
        final cameraPosition = await _mapController!.getVisibleRegion();
        final center = LatLng(
          (cameraPosition.northeast.latitude + cameraPosition.southwest.latitude) / 2,
          (cameraPosition.northeast.longitude + cameraPosition.southwest.longitude) / 2,
        );
        
        // Check if the center is within Universal Orlando area
        if (center.latitude >= 28.46 && center.latitude <= 28.49 &&
            center.longitude >= -81.48 && center.longitude <= -81.46) {
          
          final locationService = Provider.of<LocationService>(context, listen: false);
          locationService.setManualLocation(center.latitude, center.longitude);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Using map center as location: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
          // For simulator testing, center on Universal Orlando
          final locationService = Provider.of<LocationService>(context, listen: false);
          locationService.setManualLocation(28.479581, -81.467916);
          
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: const LatLng(28.479581, -81.467916),
                zoom: 15.0,
              ),
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Set location to Universal Orlando center. In Simulator: Device > Location > Custom Location (28.479581, -81.467916)'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error getting camera position: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location not available. Set custom location in Simulator: Device > Location > Custom Location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationTestingPanel() {
    final testLocations = [
      {'name': '🏰 Park Entrance', 'lat': 28.4744, 'lng': -81.4687, 'desc': 'Universal Orlando Center'},
      {'name': '🦕 Islands of Adventure', 'lat': 28.4722, 'lng': -81.4708, 'desc': 'IOA Main Area'},
      {'name': '🌍 Universal Studios', 'lat': 28.4766, 'lng': -81.4677, 'desc': 'USF Main Area'},
      {'name': '⚡ Near Hulk Coaster', 'lat': 28.471513, 'lng': -81.468761, 'desc': 'Marvel Super Hero Island'},
      {'name': '🪄 Near Harry Potter (IOA)', 'lat': 28.472621, 'lng': -81.472998, 'desc': 'Hogsmeade Village'},
      {'name': '🪄 Near Harry Potter (USF)', 'lat': 28.479903, 'lng': -81.470182, 'desc': 'Diagon Alley'},
      {'name': '👽 Near Men in Black', 'lat': 28.480728, 'lng': -81.467669, 'desc': 'World Expo Area'},
      {'name': '🦖 Near Jurassic Park', 'lat': 28.470427, 'lng': -81.474121, 'desc': 'Jurassic Park Area'},
      {'name': '🎢 Near VelociCoaster', 'lat': 28.471231, 'lng': -81.472616, 'desc': 'Jurassic World Area'},
      {'name': '🎭 Near Simpsons', 'lat': 28.4794389, 'lng': -81.4673639, 'desc': 'Springfield Area'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🧪 Location Testing Panel',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a starting location to test different chatbot scenarios:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: testLocations.length,
                itemBuilder: (context, index) {
                  final location = testLocations[index];
                  return Card(
                    child: ListTile(
                      leading: Text(
                        (location['name'] as String).split(' ')[0],
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        (location['name'] as String).substring(2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location['desc'] as String),
                          Text(
                            '${location['lat']}, ${location['lng']}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.location_on, color: Colors.blue),
                      onTap: () {
                        final locationService = Provider.of<LocationService>(context, listen: false);
                        locationService.setManualLocation(
                          location['lat'] as double,
                          location['lng'] as double,
                        );
                        
                        // Move camera to the new location
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(location['lat'] as double, location['lng'] as double),
                              zoom: 17.0,
                            ),
                          ),
                        );
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📍 Set location to: ${(location['name'] as String).substring(2)}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Testing Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('• Set location, then open chatbot to test recommendations'),
                  Text('• Try "What rides should I do?" from different locations'),
                  Text('• Test "Where am I?" to verify location detection'),
                  Text('• Ask for directions between rides'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatbot() {
    showDialog(
      context: context,
      builder: (context) => ChatbotDialog(
        onDirectionsRequested: _showDirections,
      ),
    );
  }

  void _showDirections(String fromRide, String toRide) async {
    // Show loading state
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Get coordinates from LocationService
      final rideCoordinates = LocationService.rideCoordinates;
      
      final fromCoords = rideCoordinates[fromRide];
      final toCoords = rideCoordinates[toRide];
      
      if (fromCoords == null || toCoords == null) {
        _showErrorSnackBar('Could not find coordinates for one of the rides');
        return;
      }
      
      // IMPORTANT: Mark the target ride as visited to prevent re-recommendation
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.addVisitedRide(toRide);
      locationService.markRideAsTarget(toRide);
      
      // Get walking directions using the new DirectionsService
      final directionsResult = await DirectionsService.getWalkingDirections(
        origin: fromCoords,
        destination: toCoords,
      );
      
      if (directionsResult != null) {
        setState(() {
          _currentDirectionFrom = fromRide;
          _currentDirectionTo = toRide;
          
          // Create polyline with proper walking route
          _polylines = {
            DirectionsService.createPolyline(
              polylineId: 'walking_route',
              points: directionsResult.polylinePoints,
              color: directionsResult.isFallback ? Colors.orange : const Color(0xFF1976D2),
              width: 5.0,
              isDashed: directionsResult.isFallback,
            ),
          };
        });
        
        // Fit camera to show the entire route
        _fitToDirections(directionsResult.polylinePoints.first, directionsResult.polylinePoints.last);
        
        // Show route information
        _showRouteInfoDialog(directionsResult, fromRide, toRide);
        
      } else {
        _showErrorSnackBar('Could not calculate walking route');
      }
      
    } catch (e) {
      print('Error showing directions: $e');
      _showErrorSnackBar('Error calculating directions: $e');
    } finally {
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRouteInfoDialog(DirectionsResult result, String fromRide, String toRide) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Walking Directions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text('From: $fromRide')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text('To: $toRide')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.straighten, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Distance: ${result.totalDistance}'),
                const SizedBox(width: 20),
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                Text('Time: ${result.totalDuration}'),
              ],
            ),
            if (result.isFallback) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing direct path - detailed walking route unavailable',
                        style: TextStyle(color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearDirections() {
    setState(() {
      _polylines.clear();
      _currentDirectionFrom = null;
      _currentDirectionTo = null;
    });
  }

  void _fitToDirections(LatLng from, LatLng to) {
    if (_mapController == null) return;
    
    // Calculate bounds that include both points
    double minLat = math.min(from.latitude, to.latitude);
    double maxLat = math.max(from.latitude, to.latitude);
    double minLng = math.min(from.longitude, to.longitude);
    double maxLng = math.max(from.longitude, to.longitude);
    
    // Add some padding
    double latPadding = (maxLat - minLat) * 0.3;
    double lngPadding = (maxLng - minLng) * 0.3;
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Widget _buildDirectionsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Get Walking Directions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showDirectionsPanel = false;
                      _selectedFromRide = null;
                      _selectedToRide = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRideDropdown(
                    'From',
                    _selectedFromRide,
                    (value) => setState(() => _selectedFromRide = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRideDropdown(
                    'To',
                    _selectedToRide,
                    (value) => setState(() => _selectedToRide = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedFromRide != null && _selectedToRide != null)
                    ? () {
                        _showDirections(_selectedFromRide!, _selectedToRide!);
                        setState(() {
                          _showDirectionsPanel = false; // Hide panel after getting directions
                        });
                      }
                    : null,
                icon: const Icon(Icons.directions_walk),
                label: const Text('Get Walking Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideDropdown(String label, String? value, Function(String?) onChanged) {
    final rideCoordinates = LocationService.rideCoordinates;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 9)),
        const SizedBox(height: 2),
        Container(
          constraints: const BoxConstraints(maxWidth: 120),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              isDense: true,
            ),
            hint: const Text('Select', style: TextStyle(fontSize: 7)),
            isExpanded: true,
            style: const TextStyle(fontSize: 7, color: Colors.black),
            items: rideCoordinates.keys.map((String rideName) {
              return DropdownMenuItem<String>(
                value: rideName,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    rideName,
                    style: const TextStyle(fontSize: 7),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Universal Orlando Map'),
            backgroundColor: const Color(0xFF1976D2),
            elevation: 0,
            actions: [
              if (locationService.currentPark != null)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    locationService.currentPark!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              // Debug info button
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  final userLoc = locationService.currentLocationLatLng;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Debug Info'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Map Ready: $_mapReady'),
                          Text('Location: ${userLoc?.latitude.toStringAsFixed(6) ?? 'null'}, ${userLoc?.longitude.toStringAsFixed(6) ?? 'null'}'),
                          Text('Current Park: ${locationService.currentPark ?? 'None'}'),
                          Text('Visited Rides: ${locationService.visitedRides.length}'),
                          Text('Last Visited: ${locationService.lastVisitedRide ?? 'None'}'),
                          const SizedBox(height: 10),
                          const Text('For Simulator:\n1. Device > Location > Custom Location\n2. Set: 28.4744, -81.4687', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 10),
                          const Text('VelociCoaster coords: 28.471231, -81.472616', style: TextStyle(fontSize: 11, color: Colors.blue)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            // Manual location refresh for testing
                            await locationService.refreshLocation();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Location refresh attempted')),
                            );
                          },
                          child: const Text('Refresh Location'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Set manual test location
                            locationService.setManualLocation(28.479581, -81.467916);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Set test location: Universal Orlando (28.479581, -81.467916)')),
                            );
                          },
                          child: const Text('Use Test Location'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Clear manual location and return to GPS
                            locationService.clearManualLocation();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cleared manual location - using GPS')),
                            );
                          },
                          child: const Text('Clear Manual Location'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLocationTestingPanel();
                          },
                          child: const Text('Location Testing'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Map Widget
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _initialPosition,
                markers: _markers,
                polylines: _polylines,
                mapType: MapType.normal,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // We'll use our custom button
                zoomControlsEnabled: false,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
                onTap: (LatLng position) {
                  // Show coordinates when tapping map (for debugging)
                  debugPrint('Tapped at: ${position.latitude}, ${position.longitude}');
                },
              ),
              
              // Map loading overlay
              if (!_mapReady)
                Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                        ),
                        SizedBox(height: 16),
                        Text('Loading Google Maps...'),
                      ],
                    ),
                  ),
                ),
              
              // Map error overlay
              if (_mapReady && _mapError != null)
                Container(
                  color: Colors.red[50],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[600],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _mapError!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _mapReady = false;
                              _mapError = null;
                            });
                            // Trigger a rebuild of the GoogleMap widget
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                setState(() {});
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Location loading indicator
              if (_isLocationLoading && _mapReady)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Finding location...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              // Directions info banner
              if (_currentDirectionFrom != null && _currentDirectionTo != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Walking Directions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'From: ${_currentDirectionFrom!}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'To: ${_currentDirectionTo!}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _clearDirections,
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Directions Panel - only show when requested
              if (_showDirectionsPanel && _currentDirectionFrom == null && _currentDirectionTo == null && _mapReady)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildDirectionsPanel(),
                ),
              // AQI indicator (like in the original image) - moved down when directions active
              if (_mapReady && _currentDirectionFrom == null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AQI 35',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.circle,
                          color: Colors.green,
                          size: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              // Custom location button
              if (_mapReady)
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _centerOnUserLocation,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1976D2),
                    mini: true,
                    heroTag: "location_button",
                    child: const Icon(Icons.my_location),
                  ),
                ),
              // Chatbot floating action button
              if (_mapReady)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: _showChatbot,
                    backgroundColor: const Color(0xFF1976D2),
                    heroTag: "chatbot_button",
                    child: const Icon(
                      Icons.chat,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Visited rides indicator
              if (locationService.visitedRides.isNotEmpty && _mapReady)
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${locationService.visitedRides.length} rides visited',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Custom zoom controls
              if (_mapReady)
                Positioned(
                  top: 80,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomIn,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomOut,
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.remove,
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
} 