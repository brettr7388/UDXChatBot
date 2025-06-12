# 🗺️ Google Maps Setup Guide for Universal Orlando Ride Recommender

## Overview
This guide will help you set up Google Maps integration for the Universal Orlando Ride Recommendation System, including **real walking directions** between rides.

## 🚀 New Features Added
- **✅ Real Walking Paths**: Shows actual walkable routes instead of straight lines
- **🚶‍♂️ Walking Time Display**: Shows walking time in minutes (not meters) - more practical for guests
- **🛣️ Avoids Obstacles**: Routes go around water, buildings, and restricted areas
- **📱 Enhanced Mobile Experience**: Better performance on mobile devices
- **🔄 Fallback System**: Falls back to straight lines if directions fail

---

## 📋 Step-by-Step Setup

### Step 1: Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Create Project" or select existing project
3. Name your project (e.g., "Universal Orlando Maps")
4. Note your Project ID

### Step 2: Enable Required APIs
You need to enable **TWO** APIs for full functionality:

#### 2.1 Maps JavaScript API
1. Go to "APIs & Services" → "Library"
2. Search for "**Maps JavaScript API**"
3. Click "Enable"

#### 2.2 Directions API (NEW - Required for Walking Paths)
1. In the same Library section
2. Search for "**Directions API**"
3. Click "Enable"
4. ⚠️ **Important**: This API has usage costs, but Google provides $200/month free credit

### Step 3: Create API Key
1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy your API key (starts with `AIzaSy...`)
4. **Important**: Restrict your API key (see Step 4)

### Step 4: Secure Your API Key
1. Click on your API key to edit it
2. Under "Application restrictions":
   - Choose "HTTP referrers (web sites)"
   - Add: `http://localhost:5000/*` and `http://127.0.0.1:5000/*`
3. Under "API restrictions":
   - Choose "Restrict key"
   - Select: "Maps JavaScript API" and "Directions API"
4. Save changes

### Step 5: Update Your HTML File
Replace `YOUR_API_KEY` in `templates/index.html`:
```html
<script async defer src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&callback=initMap"></script>
```

---

## 🔧 Technical Implementation

### What's New in the Code

#### 1. Directions Service Integration
```javascript
// New: Initialize Directions Service
directionsService = new google.maps.DirectionsService();
directionsRenderer = new google.maps.DirectionsRenderer({
    suppressMarkers: true, // Use custom markers
    polylineOptions: {
        strokeColor: '#667eea',
        strokeWeight: 4
    }
});
```

#### 2. Walking Route Calculation
```javascript
function calculateWalkingRoute(startCoords, endCoords, startName, endName, waitTime) {
    const request = {
        origin: start,
        destination: end,
        travelMode: google.maps.TravelMode.WALKING, // 🚶‍♂️ Walking mode
        unitSystem: google.maps.UnitSystem.METRIC,
        avoidHighways: true,
        avoidTolls: true
    };
    
    directionsService.route(request, (result, status) => {
        if (status === 'OK') {
            // Show real walking path
            directionsRenderer.setDirections(result);
            
            // Extract walking time and distance
            const walkingTime = result.routes[0].legs[0].duration.text;
            const walkingDistance = result.routes[0].legs[0].distance.text;
        }
    });
}
```

#### 3. Enhanced Markers with Walking Info
- **Red Marker**: Starting point (last ride)
- **Green Marker**: Destination (recommended ride)
- **Blue Path**: Actual walking route
- **Info Windows**: Include walking time and distance

#### 4. Fallback System
If the Directions API fails, the system:
- Falls back to a dashed red line (straight path)
- Still shows accurate ride locations
- Displays appropriate error handling

---

## 🧪 Testing Your Setup

### Run the Test Script
```bash
python3 test_google_maps.py
```

### Manual Testing Steps
1. **Open the app**: Visit `http://127.0.0.1:5000`
2. **Select a park**: Choose "Islands of Adventure" or "Universal Studios"
3. **Pick a ride**: Select any ride from the dropdown
4. **Check the map**: Should show Google Maps (not OpenStreetMap)
5. **Get recommendation**: Click "Get My Recommendation!"
6. **Verify walking path**: Look for:
   - Red marker (start)
   - Green marker (destination)
   - Blue walking path between them
   - Walking time (in minutes) in popup

### Expected Results
- ✅ Map loads with Google Maps styling
- ✅ Real walking paths (not straight lines)
- ✅ Paths avoid water and buildings
- ✅ Walking time in minutes displayed (not meters)
- ✅ Smooth animations and transitions

---

## 🛠️ Troubleshooting

### Issue: Map Not Loading
**Solution**: Check browser console for errors
- Verify API key is correct
- Ensure Maps JavaScript API is enabled
- Check API key restrictions

### Issue: No Walking Directions
**Symptoms**: Only straight lines appear
**Solution**: 
- Enable Directions API in Google Cloud Console
- Check API key includes Directions API permissions
- Verify internet connection

### Issue: "OVER_QUERY_LIMIT" Error
**Cause**: Too many API requests
**Solution**: 
- Google provides $200/month free credit
- For production, consider caching directions
- Implement request rate limiting

### Issue: Walking Path Goes Through Buildings
**Cause**: Limited walking data in theme parks
**Solution**: 
- Google Maps may not have detailed Universal Orlando walking paths
- The system tries to use available pedestrian routes
- Consider using `avoidHighways: true` in request

---

## 💰 Cost Considerations

### Google Maps Pricing (2024)
- **Maps JavaScript API**: $7 per 1,000 loads
- **Directions API**: $5 per 1,000 requests
- **Free Tier**: $200/month credit covers ~28K map loads or 40K directions

### Cost Optimization Tips
1. **Cache Results**: Store frequently requested routes
2. **Batch Requests**: Combine multiple route requests
3. **Smart Loading**: Only load directions when needed
4. **Rate Limiting**: Prevent excessive API calls

---

## 🎯 Benefits of Real Walking Paths

### Before (Straight Lines)
- ❌ Paths went over water and buildings
- ❌ Inaccurate distance calculations in meters
- ❌ No walking time estimates
- ❌ Poor user experience

### After (Real Walking Directions)
- ✅ Follows actual walkable paths
- ✅ Shows walking time in minutes (more practical than meters)
- ✅ Avoids obstacles and restricted areas
- ✅ Professional mapping experience
- ✅ Better trip planning for guests

---

## 🔮 Future Enhancements

### Potential Additions
1. **Multiple Routes**: Show fastest vs. scenic routes
2. **Real-time Updates**: Account for construction/closures
3. **Accessibility Routes**: Wheelchair-accessible paths
4. **Indoor Navigation**: Connect to Universal's indoor maps
5. **Turn-by-Turn**: Detailed navigation instructions

### Advanced Features
```javascript
// Example: Add intermediate waypoints
const request = {
    origin: start,
    destination: end,
    waypoints: [
        { location: bathroomStop, stopover: true },
        { location: foodStand, stopover: true }
    ],
    travelMode: google.maps.TravelMode.WALKING
};
```

---

## 📞 Support

### If You Need Help
1. **Check the browser console** for error messages
2. **Verify API setup** in Google Cloud Console
3. **Test with simpler requests** first
4. **Review Google Maps documentation**: [developers.google.com/maps](https://developers.google.com/maps)

### Common Error Messages
- `"InvalidKeyMapError"`: Check API key
- `"RefererNotAllowedMapError"`: Update referrer restrictions
- `"OVER_QUERY_LIMIT"`: Enable billing or reduce requests
- `"ZERO_RESULTS"`: No walking path found (rare)

---

## 🎉 Success!

Once everything is working, you'll have:
- **Interactive Google Maps** with satellite imagery
- **Real walking directions** between Universal Orlando rides
- **Accurate time and distance** calculations
- **Professional user experience** for theme park navigation
- **Fallback systems** for reliability

Your Universal Orlando Ride Recommender now provides **real walking paths** instead of straight lines over water! 🎢🗺️ 