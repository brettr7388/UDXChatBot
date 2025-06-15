# Universal Orlando Flutter Mobile App

A Flutter mobile application for Universal Orlando Resort that provides intelligent ride recommendations, real-time wait times, interactive maps, and an AI chatbot assistant.

## 🚀 Features

### 📱 Mobile App
- **4-Tab Navigation**: Home, Map, Shop, Profile
- **Google Maps Integration**: Interactive maps with custom markers and directions
- **Real-time Location Services**: GPS tracking and location-based features
- **AI Chatbot**: Intelligent assistant for park recommendations and information
- **Ride Tracking**: Session memory of visited rides
- **Custom UI**: Beautiful Universal Orlando themed interface

### 🤖 AI Chatbot
- **Smart Recommendations**: ML-powered ride suggestions based on location and wait times
- **Session Memory**: Tracks conversation history and visited rides
- **Context Awareness**: Understands user preferences and park context
- **Real-time Data**: Integrates live wait times from queue-times.com API

### 🗺️ Maps & Navigation
- **Interactive Google Maps**: Satellite imagery with smooth navigation
- **Custom Markers**: Emoji-based markers for different ride types
- **Walking Directions**: Real-time directions between rides
- **Zoom Controls**: Custom zoom in/out buttons
- **Location Detection**: Automatic ride detection when near attractions

### 🎢 Ride Recommendations
- **Smart Algorithm**: Combines walking distance and wait times
- **Multi-Park Support**: Islands of Adventure, Universal Studios Florida, Epic Universe
- **Real-time Wait Times**: Live data from queue-times.com API
- **Exclusion Logic**: Avoids recently visited rides

## 🏗️ Architecture

### Flutter Frontend
- **Dart/Flutter**: Cross-platform mobile development
- **Google Maps Flutter Plugin**: Native map integration
- **Location Services**: GPS and geofencing capabilities
- **HTTP Client**: API communication with Flask backend

### Python Flask Backend
- **REST API**: JSON endpoints for recommendations
- **Real-time Data**: Queue-times.com API integration
- **Haversine Distance**: Accurate walking distance calculations
- **Environment Variables**: Secure API key management

## 📋 Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Python 3.7+
- iOS Simulator or Android Emulator
- Google Maps API Key

## 🛠️ Installation

### 1. Clone Repository
```bash
git clone https://github.com/brettr7388/UDXChatBot.git
cd UDXChatBot
```

### 2. Environment Setup
```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your API keys
# GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 3. Flutter Setup
```bash
# Install Flutter dependencies
flutter pub get

# Run iOS configuration (macOS only)
./setup_ios.sh

# For Android, ensure Google Maps API key is configured
```

### 4. Python Backend Setup
```bash
# Install Python dependencies
pip3 install -r requirements.txt

# Run environment setup
python3 setup_env.py
```

## 🚀 Running the Application

### 1. Start Flask Backend
```bash
python3 predictive_in_park.py
```
The API will be available at `http://127.0.0.1:5000`

### 2. Launch Flutter App
```bash
# For iOS Simulator
flutter run

# For Android Emulator
flutter run

# For specific device
flutter devices
flutter run -d <device_id>
```

## 🔧 Configuration

### Google Maps API Key Setup

1. **Get API Key**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Enable "Maps SDK for iOS" and "Maps SDK for Android"
   - Create API key under "Credentials"

2. **Configure iOS**:
   - API key is automatically configured via environment variables
   - Ensure `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` include Config.xcconfig

3. **Configure Android**:
   - API key is automatically configured via environment variables
   - Ensure `android/app/src/main/AndroidManifest.xml` references the environment variable

### Environment Variables

The app uses the following environment variables (configured in `.env`):

```bash
# Required
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Optional (with defaults)
FLASK_HOST=127.0.0.1
FLASK_PORT=5000
FLASK_DEBUG=false
```

## 📡 API Endpoints

### POST `/recommend`

Get intelligent ride recommendations based on current location and preferences.

**Request:**
```json
{
  "last_ride": "Flight of the Hippogriff™",
  "park": "Islands of Adventure",
  "weather": "sunny",
  "hour": 14,
  "exclude_rides": ["The Simpsons Ride™"]
}
```

**Response:**
```json
{
  "recommendation": "Harry Potter and the Forbidden Journey™",
  "wait_time": 25,
  "distance_meters": 150.4,
  "excluded_count": 1,
  "last_ride": "Flight of the Hippogriff™"
}
```

### GET `/debug`

Debug endpoint for testing API connectivity and data availability.

## 🎯 Supported Parks

- **Islands of Adventure** (Park ID: 64)
- **Universal Studios Florida** (Park ID: 65)  
- **Epic Universe** (Park ID: 334)

## 🧪 Testing

### API Testing
```bash
# Test recommendation endpoint
python3 test_api.py

# Manual curl test
curl -X POST http://127.0.0.1:5000/recommend \
     -H "Content-Type: application/json" \
     -d '{
       "last_ride": "Flight of the Hippogriff™",
       "park": "Islands of Adventure",
       "weather": "sunny",
       "hour": 14
     }'
```

### Flutter Testing
```bash
# Run Flutter tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🔒 Security

- **Environment Variables**: API keys stored in `.env` file (not committed to git)
- **API Key Restrictions**: Recommend restricting Google Maps API key to your app bundle
- **HTTPS**: Use HTTPS in production deployments
- **Input Validation**: All API inputs are validated and sanitized

## 🚀 Deployment

### Production Backend
```bash
# Use production WSGI server
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 predictive_in_park:app
```

### Mobile App Release
```bash
# Build for iOS
flutter build ios --release

# Build for Android
flutter build apk --release
flutter build appbundle --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Queue-Times.com**: Real-time wait time data
- **Google Maps**: Mapping and navigation services
- **Universal Orlando Resort**: Park data and inspiration
- **Flutter Community**: Excellent documentation and plugins

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check existing documentation
- Review Flutter and Python setup guides

---

**Note**: This is a personal project and is not affiliated with Universal Orlando Resort. 