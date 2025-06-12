import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math'; // For sqrt and pow

class LocationService extends ChangeNotifier {
  Location _location = Location();
  PermissionStatus? _permissionStatus;
  LocationData? _locationData;
  Stream<LocationData>? _locationStream;

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

  static const double RIDE_PROXIMITY_THRESHOLD_METERS = 30.0; // User must be within 30 meters

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
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          debugPrint("Location service not enabled");
          return;
        }
      }

      _permissionStatus = await _location.hasPermission();
      if (_permissionStatus == PermissionStatus.denied) {
        _permissionStatus = await _location.requestPermission();
        if (_permissionStatus != PermissionStatus.granted) {
          debugPrint("Location permission not granted: $_permissionStatus");
          return;
        }
      }

      debugPrint("Location permission granted, starting location stream");
      
      // Get current location immediately
      await refreshLocation();
      
      // Set up location stream
      _locationStream = _location.onLocationChanged;
      _locationStream?.listen((LocationData newLocationData) {
        debugPrint("Location update received: ${newLocationData.latitude}, ${newLocationData.longitude}");
        _updateLocation(newLocationData);
      }, onError: (error) {
        debugPrint("Location stream error: $error");
      });
    } catch (e) {
      debugPrint("Error initializing location stream: $e");
    }
  }

  Future<void> refreshLocation() async {
    try {
      debugPrint("Attempting to get current location...");
      LocationData newLocationData = await _location.getLocation();
      debugPrint("Got location: ${newLocationData.latitude}, ${newLocationData.longitude}");
      _updateLocation(newLocationData);
    } catch (e) {
      debugPrint("Error getting location: $e");
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
    final locationData = LocationData.fromMap({
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': 5.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch.toDouble(),
    });
    debugPrint("Setting manual location: $latitude, $longitude");
    _updateLocation(locationData);
  }

  void _detectVisitedRide(LatLng currentLatLng) {
    for (var entry in rideCoordinates.entries) {
      final String rideName = entry.key;
      final LatLng rideLatLng = entry.value;
      final double distance = calculateDistance(currentLatLng, rideLatLng);

      if (distance <= RIDE_PROXIMITY_THRESHOLD_METERS) {
        if (_lastVisitedRide != rideName) {
          _lastVisitedRide = rideName;
          if (!_visitedRides.contains(rideName)) {
            _visitedRides.add(rideName);
          }
          debugPrint("User is at or just visited: $rideName");
          notifyListeners(); 
        }
        return; // Found the closest ride, no need to check others if already within threshold
      }
    }
  }

  void addVisitedRide(String rideName) {
    if (!_visitedRides.contains(rideName)) {
      _visitedRides.add(rideName);
      _lastVisitedRide = rideName;
      notifyListeners();
    }
  }

  String? _detectPark(LatLng location) {
    // Islands of Adventure bounds (rough)
    if (location.latitude >= 28.468 && location.latitude <= 28.475 &&
        location.longitude >= -81.475 && location.longitude <= -81.467) {
      return 'Islands of Adventure';
    }
    
    // Universal Studios Florida bounds (rough)
    if (location.latitude >= 28.473 && location.latitude <= 28.480 &&
        location.longitude >= -81.471 && location.longitude <= -81.465) {
      return 'Universal Studios';
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
    notifyListeners();
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