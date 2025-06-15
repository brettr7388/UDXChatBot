import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';

class DirectionsService {
  static final PolylinePoints _polylinePoints = PolylinePoints();

  /// Calculate walking route between two points using Google Directions API
  static Future<DirectionsResult?> getWalkingDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final String apiKey = ApiKeys.googleMapsApiKey; // Get API key dynamically
      
      // Use flutter_polyline_points to get the route
      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey,
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.walking,
        ),
      );

      if (result.points.isNotEmpty) {
        // Convert points to LatLng
        List<LatLng> polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        // Get additional route information using Directions API
        final routeInfo = await _getRouteInfo(origin, destination);

        return DirectionsResult(
          polylinePoints: polylineCoordinates,
          totalDistance: routeInfo?.totalDistance ?? '${_calculateStraightLineDistance(origin, destination).toStringAsFixed(1)} km',
          totalDuration: routeInfo?.totalDuration ?? 'Unknown',
          instructions: routeInfo?.instructions ?? [],
        );
      } else {
        print('Directions API Error: ${result.errorMessage}');
        // Fallback to straight line if API fails
        return _createFallbackRoute(origin, destination);
      }
    } catch (e) {
      print('Error getting walking directions: $e');
      // Fallback to straight line if there's an error
      return _createFallbackRoute(origin, destination);
    }
  }

  /// Get detailed route information from Google Directions API
  static Future<RouteInfo?> _getRouteInfo(LatLng origin, LatLng destination) async {
    try {
      final String apiKey = ApiKeys.googleMapsApiKey; // Get API key dynamically
      
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}&'
          'destination=${destination.latitude},${destination.longitude}&'
          'mode=walking&'
          'avoid=highways|tolls|ferries&'
          'key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Extract instructions
          List<String> instructions = [];
          if (leg['steps'] != null) {
            for (var step in leg['steps']) {
              if (step['html_instructions'] != null) {
                // Remove HTML tags from instructions
                String instruction = step['html_instructions']
                    .replaceAll(RegExp(r'<[^>]*>'), '')
                    .replaceAll('&nbsp;', ' ')
                    .trim();
                if (instruction.isNotEmpty) {
                  instructions.add(instruction);
                }
              }
            }
          }

          return RouteInfo(
            totalDistance: leg['distance']['text'] ?? 'Unknown',
            totalDuration: leg['duration']['text'] ?? 'Unknown',
            instructions: instructions,
          );
        }
      }
    } catch (e) {
      print('Error getting route info: $e');
    }
    return null;
  }

  /// Create a fallback route with straight line if API fails
  static DirectionsResult _createFallbackRoute(LatLng origin, LatLng destination) {
    return DirectionsResult(
      polylinePoints: [origin, destination],
      totalDistance: '${_calculateStraightLineDistance(origin, destination).toStringAsFixed(1)} km',
      totalDuration: 'Unknown',
      instructions: ['Walk directly to destination'],
      isFallback: true,
    );
  }

  /// Calculate straight-line distance between two points (Haversine formula)
  static double _calculateStraightLineDistance(LatLng origin, LatLng destination) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = origin.latitude * (pi / 180);
    double lat2Rad = destination.latitude * (pi / 180);
    double deltaLatRad = (destination.latitude - origin.latitude) * (pi / 180);
    double deltaLngRad = (destination.longitude - origin.longitude) * (pi / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  /// Create a polyline for the map
  static Polyline createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color color = Colors.blue,
    double width = 4.0,
    bool isDashed = false,
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width.round(),
      patterns: isDashed ? [PatternItem.dash(20), PatternItem.gap(10)] : [],
      geodesic: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }
}

/// Result class for directions
class DirectionsResult {
  final List<LatLng> polylinePoints;
  final String totalDistance;
  final String totalDuration;
  final List<String> instructions;
  final bool isFallback;

  DirectionsResult({
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.instructions,
    this.isFallback = false,
  });
}

/// Route information class
class RouteInfo {
  final String totalDistance;
  final String totalDuration;
  final List<String> instructions;

  RouteInfo({
    required this.totalDistance,
    required this.totalDuration,
    required this.instructions,
  });
} 