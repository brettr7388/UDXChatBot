class ApiKeys {
  // STEP 1: Get your Google Maps API key from https://console.cloud.google.com/
  // STEP 2: Enable these APIs:
  // - Maps SDK for Android
  // - Maps SDK for iOS  
  // - Directions API
  // STEP 3: Replace 'DEMO_MODE' below with your actual API key
  
  static const String googleMapsApiKey = 'AIzaSyDPNIJm5pJfbtvCv6Uc7ESZaiNYo8dZj0s'; // Replace with: 'AIzaSyC...your-actual-key'
  
  // DEMO MODE BEHAVIOR:
  // - Shows orange dashed lines (fallback routes)
  // - Displays "detailed walking path unavailable" message
  // - Uses straight-line distance calculations
  
  // WITH REAL API KEY:
  // - Shows blue solid lines (proper walking paths)
  // - Follows actual sidewalks and avoids obstacles
  // - Provides accurate distance and time estimates
  
  // Note: In production, store API keys securely using:
  // - Environment variables: --dart-define=GOOGLE_MAPS_API_KEY=your_key
  // - Flutter's secure storage
  // - Never commit real API keys to version control!
} 