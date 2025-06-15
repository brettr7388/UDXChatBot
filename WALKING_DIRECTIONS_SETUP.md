# Walking Directions Setup Guide

## Overview
The app now uses Google's Directions API to provide proper walking paths between rides instead of straight lines. This ensures users get realistic walking routes that follow actual walkways and avoid obstacles like water bodies.

## Setup Instructions

### 1. Get Google Maps API Key
1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS**
   - **Directions API**
4. Create an API key in "APIs & Services" > "Credentials"

### 2. Configure API Key
1. Open `lib/constants/api_keys.dart`
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key:
   ```dart
   static const String googleMapsApiKey = 'AIzaSyC...your-actual-key-here';
   ```

### 3. Security Best Practices
- **Never commit real API keys to version control**
- Consider using environment variables or Flutter's `--dart-define` flag
- Restrict your API key to specific platforms and APIs in Google Cloud Console

## Features

### ✅ What's Fixed
- **Proper Walking Paths**: Uses Google Directions API to calculate realistic walking routes
- **Avoids Obstacles**: Routes follow actual walkways and avoid water, buildings, etc.
- **Accurate Distance & Time**: Provides real walking distance and estimated time
- **Fallback Support**: Shows straight line if API fails, with clear indication
- **Visual Feedback**: Different colors for API routes (blue) vs fallback routes (orange, dashed)

### 🎯 How It Works
1. **Route Calculation**: Uses `flutter_polyline_points` package with Google Directions API
2. **Walking Mode**: Specifically requests walking directions (not driving)
3. **Polyline Display**: Shows the route as a smooth line on the map
4. **Smart Markers**: Places start (red) and destination (green) markers
5. **Camera Adjustment**: Automatically fits the camera to show the entire route

### 🔧 Usage
1. Open the map screen
2. Select "From" and "To" rides from the dropdowns
3. Tap "Get Walking Directions"
4. View the walking route with distance and time information
5. The destination ride is automatically marked as "visited" to prevent re-recommendation

## Technical Details

### New Files Added
- `lib/services/directions_service.dart` - Handles Google Directions API calls
- `lib/constants/api_keys.dart` - Stores API configuration
- `WALKING_DIRECTIONS_SETUP.md` - This setup guide

### Dependencies Added
- `flutter_polyline_points: ^2.1.0` - For Google Directions API integration

### Key Classes
- `DirectionsService` - Main service for calculating walking routes
- `DirectionsResult` - Contains route data (points, distance, time, instructions)
- `RouteInfo` - Additional route information from Directions API

## Troubleshooting

### Common Issues
1. **"Could not calculate walking route"**
   - Check if your API key is valid
   - Ensure Directions API is enabled in Google Cloud Console
   - Verify you have billing enabled (required for Directions API)

2. **Straight orange dashed line instead of proper route**
   - This is the fallback mode when API fails
   - Check your internet connection
   - Verify API key permissions

3. **App crashes on directions**
   - Make sure you've run `flutter pub get` after adding dependencies
   - Check that API key is properly set in `api_keys.dart`

### Testing
- Test with different ride combinations
- Try with and without internet connection to see fallback behavior
- Verify that destination rides are marked as visited after getting directions

## Cost Considerations
- Google Directions API has usage limits and costs
- Free tier includes some requests per month
- Monitor usage in Google Cloud Console
- Consider implementing request caching for frequently used routes 