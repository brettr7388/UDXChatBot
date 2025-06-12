# Universal Orlando Predictive In-Park Recommendation System

GPS SITE:
https://www.gps-coordinates.net/

API USED FOR WAIT TIMES:
https://queue-times.com/en-US/pages/api

## Overview

This service provides intelligent ride recommendations for Universal Orlando Resort parks based on real-time wait times and user location. When a user exits a ride, the system calculates the optimal next ride recommendation using live data and distance calculations.

**🌟 NEW: Beautiful Web Interface with Google Maps!** - Now includes a user-friendly web form with interactive Google Maps showing your location and recommended ride path!

## ✨ Features

- **🗺️ Interactive Google Maps**: Professional mapping with satellite imagery
- **🏰 Smart Park Selection**: Choose your park and see it center on the map with smooth transitions
  - Islands of Adventure
  - Universal Studios Florida  
  - Epic Universe (correctly positioned south of main resort)
- **🎢 Dynamic Ride Dropdowns**: Ride options change based on selected park
- **🚶‍♂️ Real Walking Directions**: Shows actual walkable paths between rides with walking time in minutes
- **🎯 Smart Recommendations**: ML-powered suggestions based on location, wait times, and preferences
- **📱 Mobile Responsive**: Works perfectly on phones and tablets
- **⚡ Real-time Updates**: Live wait time integration and dynamic recommendations

## Features

- **🌐 Web Interface**: Beautiful, responsive homepage with form and popup recommendations
- **Real-time Wait Times**: Fetches live wait times from queue-times.com API
- **Distance Calculation**: Uses Haversine formula for accurate walking distances
- **Smart Scoring**: Combines walking distance and wait time for optimal recommendations
- **Multi-Park Support**: Supports Islands of Adventure, Universal Studios Florida, and Epic Universe
- **REST API**: Simple JSON endpoint for integration with other systems

## Supported Parks

- **Islands of Adventure** (Park ID: 64)
- **Universal Studios Florida** (Park ID: 65)
- **Epic Universe** (Park ID: 334)

## Quick Start

### 1. Google Maps Setup (Required)

Before running the application, you need to set up Google Maps:

1. **Get a Google Maps API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create/select a project and enable "Maps JavaScript API"
   - Create an API key under "APIs & Services" > "Credentials"

2. **Update the HTML file**:
   - Open `templates/index.html`
   - Replace `YOUR_API_KEY` with your actual API key:
   ```html
   <script async defer src="https://maps.googleapis.com/maps/api/js?key=YOUR_ACTUAL_API_KEY&callback=initMap"></script>
   ```

3. **Secure your API key** (recommended):
   - Restrict to your domain (e.g., `http://localhost:5000/*`)
   - Limit to Maps JavaScript API only

📖 **Detailed setup guide**: See `google_maps_setup.md` for complete instructions.

### 2. Running the Service

Start the Flask development server:
```bash
python3 predictive_in_park.py
```

The service will be available at `http://127.0.0.1:5000`

**Note**: Use `127.0.0.1` instead of `localhost` to avoid conflicts with Apple's AirTunes service on macOS.

### 3. Using the Web Interface

1. **Open your browser** to `http://127.0.0.1:5000`
2. **Select your park** (Islands of Adventure, Universal Studios, or Epic Universe)
3. **Choose the ride you just finished** from the dropdown
4. **Optionally select weather conditions**
5. **Click "Get My Recommendation!"**
6. **View your personalized recommendation** in the popup and see the path on the map!

### Features of the Web Interface

- 🗺️ **Interactive Google Maps**: Shows park layout with your location and recommended ride
- 🎨 **Beautiful Design**: Modern gradient background with smooth animations
- 🎢 **Smart Form**: Park selection automatically updates available rides
- ⚡ **Real-time Data**: Fetches live wait times when you submit
- 🎯 **Instant Results**: Popup shows recommendation with wait time and distance
- 🚶 **Visual Paths**: See the walking route from your current ride to the recommended one
- 📍 **Smart Markers**: Red marker for current location, green for recommended ride
- 🔄 **Loading States**: Spinner shows while fetching your recommendation
- 📱 **Mobile Responsive**: Works perfectly on phones and tablets
- 🚨 **Error Handling**: Friendly error messages if something goes wrong

## Installation

### Prerequisites

- Python 3.7 or higher
- pip package manager
- Google Maps API key

### Setup Steps

1. Clone or download this repository
2. Install dependencies:
   ```bash
   pip3 install -r requirements.txt
   ```
3. Set up Google Maps API key (see setup guide above)
4. Start the server:
   ```bash
   python3 predictive_in_park.py
   ```
5. Open your browser to `http://127.0.0.1:5000`

### Testing Your Setup

Run the test script to verify everything is working:
```bash
python3 test_google_maps.py
```

This will:
- Test your Google Maps API key
- Verify the Flask app is running
- Test the recommendation API
- Open the web interface for manual testing

## API Usage

### Endpoint: `/recommend`

**Method**: POST  
**Content-Type**: application/json

#### Request Payload

```json
{
  "last_ride": "Flight of the Hippogriff",
  "park": "Islands of Adventure",
  "weather": "sunny",
  "hour": 14
}
```

#### Required Fields
- `last_ride`: Name of the ride the user just exited
- `park`: Park name ("Islands of Adventure", "Universal Studios", or "Epic Universe")

#### Optional Fields
- `weather`: Current weather conditions (for future ML enhancements)
- `hour`: Current hour (0-23) (for future ML enhancements)

#### Response

**Success Response:**
```json
{
  "recommendation": "Harry Potter and the Forbidden Journey",
  "wait_time": 25,
  "distance_meters": 150.4,
  "last_ride_coords": [28.4720, -81.4700],
  "recommendation_coords": [28.4725, -81.4705]
}
```

**Error Response:**
```json
{
  "error": "Coordinates for 'Unknown Ride' not found"
}
```

## Testing

Test the API with curl:

```bash
curl -X POST http://127.0.0.1:5000/recommend \
     -H "Content-Type: application/json" \
     -d '{
       "last_ride": "Flight of the Hippogriff™",
       "park": "Islands of Adventure",
       "weather": "sunny",
       "hour": 14
     }'
```

**Important**: Use exact ride names including trademark symbols (™, ®) as returned by the queue-times API.

## Integration with n8n

To integrate with n8n workflows:

1. **HTTP Webhook Trigger**: Set up to receive user park events
2. **HTTP Request Node**: Call `http://127.0.0.1:5000/recommend` with user data
3. **Response Handling**: Extract recommendation data and send via Slack/Email

Example n8n HTTP Request Node configuration:
- **URL**: `http://127.0.0.1:5000/recommend`
- **Method**: POST
- **Body**: JSON with user's last ride and park information

## Algorithm

The recommendation system uses a simple but effective heuristic:

```
Score = Walking Distance (meters) + (Wait Time × 10)
```

The system:
1. Fetches live wait times for the specified park
2. Calculates walking distance from current location to all available rides
3. Applies the scoring formula to rank options
4. Returns the ride with the lowest score

## Google Maps Features

The application uses Google Maps JavaScript API for:

- **Interactive Map**: Smooth panning, zooming, and modern styling
- **Colored Markers**: Red for current location, green for recommended ride
- **Info Windows**: Click markers to see ride information
- **Path Drawing**: Blue line showing walking route between rides
- **Auto-fitting**: Map automatically centers and zooms to show both locations

### Why Google Maps?

Switched from OpenStreetMap/Leaflet to Google Maps for:
- Better satellite and hybrid view options
- More accurate business/POI data for Universal Orlando
- Better performance and mobile experience
- Potential for Street View integration
- Better indoor mapping capabilities

## Future Enhancements

### Immediate Additions

- **Street View Integration**: Show ground-level views of ride entrances
- **Real-time Location**: Use device GPS for automatic "current location"
- **Route Optimization**: Multi-ride path planning
- **Refresh Button**: Update wait times every 5 minutes

### Machine Learning Integration

1. **Data Collection**: Gather historical ride sequences and wait times
2. **Feature Engineering**: Include weather, time of day, crowd levels
3. **Model Training**: Use decision trees or XGBoost for predictions
4. **A/B Testing**: Compare ML recommendations vs. heuristic approach

### Additional Features

- Real-time crowd density data
- User preference learning
- Restaurant and show recommendations
- Integration with Universal Orlando mobile app

## Configuration

### Adding New Rides

Update the `RIDE_COORDS` dictionary in `predictive_in_park.py`:

```python
RIDE_COORDS = {
    "New Ride Name": (latitude, longitude),
    # ... existing rides
}
```

### Adjusting the Scoring Algorithm

Modify the scoring formula in the `recommend_next_ride` function:

```python
score = dist + (wt * weight_factor)  # Adjust weight_factor as needed
```

## Troubleshooting

### Common Issues

1. **Map doesn't load**: 
   - Check your Google Maps API key in the HTML file
   - Ensure Maps JavaScript API is enabled in Google Cloud Console

2. **"This page can't load Google Maps correctly"**:
   - Verify your API key is valid
   - Check API key restrictions aren't too strict

3. **Flask app on wrong port**:
   - Use `127.0.0.1:5000` instead of `localhost:5000`
   - Check for port conflicts with other services

4. **Ride names don't match**:
   - Use exact names including trademark symbols (™, ®)
   - Check queue-times API for current ride names

### Getting Help

- Run `python3 test_google_maps.py` for automated diagnostics
- Check browser developer tools console for JavaScript errors
- See `google_maps_setup.md` for detailed Google Maps setup

## Files in This Project

- `predictive_in_park.py`: Main Flask application with API
- `templates/index.html`: Web interface with Google Maps integration
- `requirements.txt`: Python dependencies
- `test_api.py`: API testing suite
- `test_google_maps.py`: Google Maps integration test
- `demo_web_interface.py`: Web interface demonstration
- `google_maps_setup.md`: Detailed Google Maps setup guide
- `PROJECT_SUMMARY.md`: Complete project overview
- `README.md`: This file 