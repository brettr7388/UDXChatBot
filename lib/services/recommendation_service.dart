import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recommendation.dart';

class RecommendationService extends ChangeNotifier {
  static const String _baseUrl = 'http://127.0.0.1:5000'; // Flask server URL
  
  bool _isLoading = false;
  String? _lastError;
  
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Convert distance in meters to walking time in minutes
  // Average walking speed: 1.4 m/s (5 km/h)
  int _metersToWalkingMinutes(double meters) {
    const double walkingSpeedMeterPerSecond = 1.4;
    final double seconds = meters / walkingSpeedMeterPerSecond;
    final int minutes = (seconds / 60).round();
    return minutes < 1 ? 1 : minutes; // Minimum 1 minute
  }

  Future<Recommendation?> getRecommendation({
    required String lastRide,
    required String park,
    String weather = 'sunny',
    int hour = 14,
    List<String>? excludeRides,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final Map<String, dynamic> requestBody = {
        'last_ride': lastRide,
        'park': park,
        'weather': weather,
        'hour': hour,
      };
      
      // Add excluded rides if provided
      if (excludeRides != null && excludeRides.isNotEmpty) {
        requestBody['exclude_rides'] = excludeRides;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/recommend'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          _lastError = data['error'];
          return null;
        }
        
        final double distanceMeters = (data['distance_meters'] ?? 0).toDouble();
        final int walkingMinutes = _metersToWalkingMinutes(distanceMeters);
        
        return Recommendation(
          rideName: data['recommendation'] ?? 'Unknown Ride',
          waitTime: data['wait_time'] ?? 0,
          distance: distanceMeters,
          walkingMinutes: walkingMinutes,
          park: park,
        );
      } else {
        _lastError = 'Failed to get recommendation: ${response.statusCode}';
        return null;
      }
    } catch (e) {
      _lastError = 'Network error: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getWaitTimes(String park) async {
    try {
      // This would call a hypothetical endpoint for wait times
      final response = await http.get(
        Uri.parse('$_baseUrl/wait-times?park=$park'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching wait times: $e');
    }
    return null;
  }

  Future<List<String>> getAvailableRides(String park) async {
    try {
      // This would call the Flask API to get available rides for a park
      final response = await http.get(
        Uri.parse('$_baseUrl/rides?park=$park'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['rides'] ?? []);
      }
    } catch (e) {
      debugPrint('Error fetching rides: $e');
    }
    
    // Fallback to hardcoded rides if API is not available
    return _getDefaultRides(park);
  }

  List<String> _getDefaultRides(String park) {
    switch (park) {
      case 'Islands of Adventure':
        return [
          'Harry Potter and the Forbidden Journey™',
          'Flight of the Hippogriff™',
          'Hagrid\'s Magical Creatures Motorbike Adventure™',
          'Jurassic World VelociCoaster',
          'The Incredible Hulk Coaster®',
          'The Amazing Adventures of Spider-Man®',
          'Skull Island: Reign of Kong™',
          'Jurassic Park River Adventure™',
        ];
      case 'Universal Studios':
        return [
          'Revenge of the Mummy™',
          'Hollywood Rip Ride Rockit™',
          'E.T. Adventure™',
          'Despicable Me Minion Mayhem™',
          'Harry Potter and the Escape from Gringotts™',
          'TRANSFORMERS™: The Ride-3D',
          'Fast & Furious - Supercharged™',
          'The Simpsons Ride™',
        ];
      case 'Epic Universe':
        return [
          'Stardust Racers',
          'Curse of the Werewolf',
          'Dragon Racer\'s Rally',
          'Mario Kart™: Bowser\'s Challenge',
          'Harry Potter and the Battle at the Ministry™',
        ];
      default:
        return [];
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
} 