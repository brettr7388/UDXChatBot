import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  // STEP 1: Get your Google Maps API key from https://console.cloud.google.com/
  // STEP 2: Enable these APIs:
  // - Maps SDK for Android
  // - Maps SDK for iOS  
  // - Directions API
  // STEP 3: Add your API key to .env file as: GOOGLE_MAPS_API_KEY=your_actual_key
  
  static String get googleMapsApiKey {
    // Load from environment variable, fallback to demo mode if not found
    return dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'DEMO_MODE';
  }
  
  // DEMO MODE BEHAVIOR:
  // - Shows orange dashed lines (fallback routes)
  // - Displays "detailed walking path unavailable" message
  // - Uses straight-line distance calculations
  
  // WITH REAL API KEY:
  // - Shows blue solid lines (proper walking paths)
  // - Follows actual sidewalks and avoids obstacles
  // - Provides accurate distance and time estimates
  
  // SECURITY NOTE:
  // - API key is now loaded from .env file
  // - .env file should be in .gitignore to prevent committing secrets
  // - Never commit real API keys to version control!
} 