import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math'; // For sqrt and pow

class LocationService extends ChangeNotifier {
  Location _location = Location();
  PermissionStatus? _permissionStatus;
  LocationData? _locationData;
  Stream<LocationData>? _locationStream;
  bool _isManualLocationSet = false; // Track if manual location is active

  String? _currentPark;
  final List<String> _visitedRides = [];
  String? _lastVisitedRide;
  final List<LatLng> _locationHistory = [];

  // Ride coordinates provided by the user
  static const Map<String, LatLng> rideCoordinates = {
    // Islands of Adventure
    "Harry Potter and the Forbidden Journey™": LatLng(28.472621, -81.472998),
    "Flight of the Hippogriff™": LatLng(28.472233, -81.472426),
    "Hagrid's Magical Creatures Motorbike Adventure™": LatLng(28.472800, -81.473200),
    "Jurassic World VelociCoaster": LatLng(28.471231, -81.472616),
    "The Incredible Hulk Coaster®": LatLng(28.471513, -81.468761),
    "The Amazing Adventures of Spider-Man®": LatLng(28.470403, -81.469899),
    "Skull Island: Reign of Kong™": LatLng(28.473000, -81.473400),
    "Jurassic Park River Adventure™": LatLng(28.470427, -81.474121),
    "Pteranodon Flyers™": LatLng(28.470361, -81.472599),
    "Doctor Doom's Fearfall®": LatLng(28.470539, -81.469285),
    "Storm Force Accelatron®": LatLng(28.470539, -81.469285),
    "Caro-Seuss-el™": LatLng(28.472880, -81.469567),
    "One Fish, Two Fish, Red Fish, Blue Fish™": LatLng(28.472949, -81.469099),
    "The Cat In The Hat™": LatLng(28.472949, -81.469099),
    "The High in the Sky Seuss Trolley Train Ride!™": LatLng(28.472800, -81.468900),
    "Dudley Do-Right's Ripsaw Falls®": LatLng(28.469184, -81.471634),
    "Popeye & Bluto's Bilge-Rat Barges®": LatLng(28.470470, -81.471738),

    // Universal Studios Florida
    "Revenge of the Mummy™": LatLng(28.476781, -81.469866),
    "Hollywood Rip Ride Rockit™": LatLng(28.474962, -81.468417),
    "E.T. Adventure™": LatLng(28.477729, -81.466626),
    "Despicable Me Minion Mayhem™": LatLng(28.475272, -81.468103),
    "Illumination's Villain-Con Minion Blast": LatLng(28.475636, -81.467976),
    "Race Through New York Starring Jimmy Fallon™": LatLng(28.4756833, -81.46945),
    "TRANSFORMERS™: The Ride-3D": LatLng(28.47638, -81.468506),
    "Fast & Furious - Supercharged™": LatLng(28.478105, -81.469609),
    "Harry Potter and the Escape from Gringotts™": LatLng(28.479903, -81.470182),
    "Kang & Kodos' Twirl 'n' Hurl": LatLng(28.479345, -81.467864),
    "MEN IN BLACK™ Alien Attack!™": LatLng(28.480728, -81.467669),
    "The Simpsons Ride™": LatLng(28.4794389, -81.4673639),

    // # Epic Universe (with exact names from API)
    // "Constellation Carousel": LatLng(28.473200, -81.472900),
    // "Stardust Racers": LatLng(28.473500, -81.472750),
    // "Curse of the Werewolf": LatLng(28.473800, -81.473100),
    // "Monsters Unchained: The Frankenstein Experiment": LatLng(28.474000, -81.473300),
    // "Dragon Racer's Rally": LatLng(28.473900, -81.472800),
    // "Fyre Drill": LatLng(28.473700, -81.472900),
    // "Hiccup Wing Glider": LatLng(28.473800, -81.472850),
    // "Mario Kart™: Bowser's Challenge": LatLng(28.474100, -81.472650),
    // "Mine-Cart Madness™": LatLng(28.474200, -81.472550),
    // "Yoshi's Adventure™": LatLng(28.474300, -81.472500),
    // "Harry Potter and the Battle at the Ministry™": LatLng(28.473246, -81.472388),
  };

  static const double RIDE_PROXIMITY_THRESHOLD_METERS = 100.0; // Increased from 30m to 100m for better detection

  LocationData? get currentLocationData => _locationData;
  LatLng? get currentLocationLatLng => _locationData != null ? LatLng(_locationData!.latitude!, _locationData!.longitude!) : null;
  String? get currentPark => _currentPark;
  List<String> get visitedRides => List.unmodifiable(_visitedRides);
  String? get lastVisitedRide => _lastVisitedRide;
  List<LatLng> get locationHistory => List.unmodifiable(_locationHistory);

  LocationService() {
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location service not enabled, requesting...");
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          debugPrint("❌ Location service not enabled by user");
          return;
        }
      }

      // Check and request permissions
      _permissionStatus = await _location.hasPermission();
      debugPrint("Current permission status: $_permissionStatus");
      
      if (_permissionStatus == PermissionStatus.denied) {
        debugPrint("Location permission denied, requesting...");
        _permissionStatus = await _location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          debugPrint("❌ Location permission not granted: $_permissionStatus");
          return;
        }
      }

      debugPrint("✅ Location permission granted, configuring location settings");
      
      // Configure location settings for better accuracy
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 5000, // Update every 5 seconds
        distanceFilter: 10, // Only update if moved 10 meters
      );
      
      // Get current location immediately
      await refreshLocation();
      
      // Set up location stream with error handling
      _locationStream = _location.onLocationChanged;
      _locationStream?.listen(
        (LocationData newLocationData) {
          // Don't override manual location with GPS updates
          if (!_isManualLocationSet) {
            debugPrint("📍 Location update: ${newLocationData.latitude}, ${newLocationData.longitude} (accuracy: ${newLocationData.accuracy}m)");
            _updateLocation(newLocationData);
          } else {
            debugPrint("🔧 Ignoring GPS update - manual location is active");
          }
        }, 
        onError: (error) {
          debugPrint("❌ Location stream error: $error");
          // Try to restart location services after error
          Future.delayed(const Duration(seconds: 10), () {
            debugPrint("🔄 Attempting to restart location services...");
            refreshLocation();
          });
        },
        cancelOnError: false, // Don't cancel the stream on error
      );
    } catch (e) {
      debugPrint("❌ Error initializing location stream: $e");
    }
  }

  Future<void> refreshLocation() async {
    try {
      debugPrint("🔄 Attempting to get current location...");
      
      // Set a timeout for location requests
      LocationData newLocationData = await _location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint("⏰ Location request timed out");
          throw Exception("Location request timed out");
        },
      );
      
      debugPrint("✅ Got location: ${newLocationData.latitude}, ${newLocationData.longitude} (accuracy: ${newLocationData.accuracy}m)");
      
      // Only use location if accuracy is reasonable (less than 100 meters)
      if (newLocationData.accuracy != null && newLocationData.accuracy! < 100) {
        _updateLocation(newLocationData);
      } else {
        debugPrint("⚠️ Location accuracy too poor (${newLocationData.accuracy}m), ignoring update");
      }
    } catch (e) {
      debugPrint("❌ Error getting location: $e");
      // Don't throw the error, just log it so the app continues working
    }
  }

  void _updateLocation(LocationData newLocationData) {
    _locationData = newLocationData;
    if (newLocationData.latitude != null && newLocationData.longitude != null) {
      final LatLng currentLatLng = LatLng(newLocationData.latitude!, newLocationData.longitude!);
      _locationHistory.add(currentLatLng);
      _currentPark = _detectPark(currentLatLng);
      _detectVisitedRide(currentLatLng);
      debugPrint("Location updated: $currentLatLng, Park: $_currentPark");
      notifyListeners();
    }
  }

  // Manual location setter for testing/simulator
  void setManualLocation(double latitude, double longitude) {
    _isManualLocationSet = true; // Flag that we're using manual location
    final locationData = LocationData.fromMap({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': 5.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
    });
    debugPrint("🔧 Setting manual location: $latitude, $longitude");
    _updateLocation(locationData);
  }

  // Method to reset to GPS location
  void resetToGPSLocation() {
    _isManualLocationSet = false;
    debugPrint("🔧 Resetting to GPS location");
    refreshLocation();
  }

  void _detectVisitedRide(LatLng currentLatLng) {
    String? nearestRide;
    double nearestDistance = double.infinity;
    
    debugPrint("🔍 Checking rides near location: ${currentLatLng.latitude}, ${currentLatLng.longitude}");
    
    // Find the nearest ride first and log distances to nearby rides
    List<MapEntry<String, double>> nearbyRides = [];
    for (var entry in rideCoordinates.entries) {
      final String rideName = entry.key;
      final LatLng rideLatLng = entry.value;
      final double distance = calculateDistance(currentLatLng, rideLatLng);
      
      // Log rides within 100 meters for debugging
      if (distance <= 100.0) {
        nearbyRides.add(MapEntry(rideName, distance));
      }

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestRide = rideName;
      }
    }
    
    // Sort and log nearby rides
    nearbyRides.sort((a, b) => a.value.compareTo(b.value));
    debugPrint("🎢 Nearby rides (within 100m):");
    for (var ride in nearbyRides.take(5)) {
      debugPrint("   ${ride.key}: ${ride.value.toStringAsFixed(1)}m");
    }
    
    debugPrint("🎯 Nearest ride: $nearestRide (${nearestDistance.toStringAsFixed(1)}m away)");

    // If we found a nearest ride and it's within threshold, mark as visited
    if (nearestRide != null && nearestDistance <= RIDE_PROXIMITY_THRESHOLD_METERS) {
      if (_lastVisitedRide != nearestRide) {
        _lastVisitedRide = nearestRide;
        if (!_visitedRides.contains(nearestRide)) {
          _visitedRides.add(nearestRide);
          debugPrint("🎢 NEW RIDE VISITED: $nearestRide (${nearestDistance.toStringAsFixed(1)}m away)");
        } else {
          debugPrint("🎢 RETURNED TO: $nearestRide (${nearestDistance.toStringAsFixed(1)}m away)");
        }
        notifyListeners(); 
      }
    } else {
      debugPrint("🚫 No rides within ${RIDE_PROXIMITY_THRESHOLD_METERS}m threshold");
    }
  }

  void addVisitedRide(String rideName) {
    if (!_visitedRides.contains(rideName)) {
      _visitedRides.add(rideName);
      debugPrint("🎢 MANUALLY ADDED VISITED RIDE: $rideName");
    }
    _lastVisitedRide = rideName;
    notifyListeners();
  }

  // Method to mark a ride as visited when user gets directions to it
  void markRideAsTarget(String rideName) {
    debugPrint("�� TARGET RIDE SET: $rideName (will be marked as visited when reached)");
    // This can be used to set up tracking for a specific ride
    // The actual visit will be detected by GPS proximity
  }

  // Method to check if user has been to a ride today
  bool hasVisitedRide(String rideName) {
    return _visitedRides.contains(rideName);
  }

  // Get rides visited today
  List<String> get todaysVisitedRides => List.unmodifiable(_visitedRides);

  String? _detectPark(LatLng location) {
    // Universal Studios Florida bounds (expanded to include all rides)
    if (location.latitude >= 28.473 && location.latitude <= 28.481 &&
        location.longitude >= -81.472 && location.longitude <= -81.465) {
      return 'Universal Studios';
    }
    
    // Islands of Adventure bounds (expanded and adjusted to avoid overlap)
    if (location.latitude >= 28.468 && location.latitude <= 28.473 &&
        location.longitude >= -81.475 && location.longitude <= -81.467) {
      return 'Islands of Adventure';
    }
    
    // Epic Universe bounds (very approximate)
    //  if (location.latitude >= 28.471 && location.latitude <= 28.476 &&
    //     location.longitude >= -81.475 && location.longitude <= -81.470) {
    //   return 'Epic Universe';
    // }
    
    return null; // Or "Universal Orlando Resort" as a general area
  }

  void clearHistory() {
    _visitedRides.clear();
    _locationHistory.clear();
    _lastVisitedRide = null;
    debugPrint("🧹 Cleared location history and visited rides");
    notifyListeners();
  }

  // Clear manual location and return to GPS
  void clearManualLocation() {
    _isManualLocationSet = false;
    debugPrint("🔧 Cleared manual location - returning to GPS");
    refreshLocation();
  }

  double calculateDistance(LatLng from, LatLng to) {
    const double earthRadius = 6371000; // Earth radius in meters
    
    double lat1Rad = from.latitude * (pi / 180);
    double lon1Rad = from.longitude * (pi / 180);
    double lat2Rad = to.latitude * (pi / 180);
    double lon2Rad = to.longitude * (pi / 180);

    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    double a = sin(dLat / 2) * sin(dLat / 2) +
               cos(lat1Rad) * cos(lat2Rad) *
               sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
} 