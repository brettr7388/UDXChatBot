class Recommendation {
  final String rideName;
  final int waitTime;
  final double distance;
  final int walkingMinutes;
  final String park;

  Recommendation({
    required this.rideName,
    required this.waitTime,
    required this.distance,
    required this.walkingMinutes,
    required this.park,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final double distanceMeters = (json['distance_meters'] ?? 0).toDouble();
    final int walkingMinutes = _metersToWalkingMinutes(distanceMeters);
    
    return Recommendation(
      rideName: json['recommendation'] ?? 'Unknown Ride',
      waitTime: json['wait_time'] ?? 0,
      distance: distanceMeters,
      walkingMinutes: walkingMinutes,
      park: json['park'] ?? 'Unknown Park',
    );
  }

  // Convert distance in meters to walking time in minutes
  // Average walking speed: 1.4 m/s (5 km/h)
  static int _metersToWalkingMinutes(double meters) {
    const double walkingSpeedMeterPerSecond = 1.4;
    final double seconds = meters / walkingSpeedMeterPerSecond;
    final int minutes = (seconds / 60).round();
    return minutes < 1 ? 1 : minutes; // Minimum 1 minute
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendation': rideName,
      'wait_time': waitTime,
      'distance_meters': distance,
      'walking_minutes': walkingMinutes,
      'park': park,
    };
  }
} 