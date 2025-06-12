# 🎢 Universal Studios Orlando iOS App with AI Chatbot

A modern Flutter iOS app that replicates the Universal Studios Orlando experience with an intelligent AI chatbot for personalized ride recommendations. Built for iOS using Xcode.

## ✨ Features

### 📱 **Complete iOS App Structure**
- **Home Screen**: Welcome page with feature highlights
- **Interactive Map**: Google Maps integration with Universal Orlando parks
- **Shop Screen**: Placeholder for merchandise (future implementation)
- **Profile Screen**: User account management (future implementation)

### 🤖 **Intelligent Chatbot**
- **Real-time Recommendations**: Connects to existing Python Flask API
- **Contextual Responses**: Understands ride, food, and shopping queries
- **Live Wait Times**: Integration with queue-times.com API
- **Location Awareness**: Tracks user movement through parks
- **Natural Conversation**: Emoji-rich responses with helpful suggestions

### 🗺️ **Smart Map Features**
- **Three Parks**: Islands of Adventure, Universal Studios, Epic Universe
- **Zoom to Explore**: Tap markers to zoom into specific parks
- **Location Tracking**: Real-time user position tracking
- **AQI Display**: Air quality indicator (like the real app)
- **Floating Chat Button**: Easy access to chatbot assistant

## 🏗️ **Technical Architecture**

### **Frontend (Flutter iOS)**
- **State Management**: Provider pattern for reactive UI
- **Google Maps**: Native iOS map integration with custom markers
- **HTTP Client**: RESTful API communication
- **Material Design**: Universal Studios blue color scheme
- **iOS-Optimized**: Native iOS location services and permissions

### **Backend Integration**
- **Flask API**: Connects to existing Python recommendation system
- **Real-time Data**: Live wait times from queue-times.com
- **Smart Algorithm**: Distance + wait time optimization
- **Location Services**: GPS tracking and park detection

## 🚀 **iOS Setup with Xcode**

### **Prerequisites**
```bash
# Ensure you have the required tools
flutter --version  # Flutter 3.2.3+ required
xcode-select --version  # Xcode Command Line Tools
python3 --version  # Python 3.x for backend
```

### **1. Xcode Setup**
```bash
# Open Xcode and install iOS Simulator
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
flutter doctor  # Verify iOS toolchain is ready
```

### **2. Google Maps API Setup**
1. **Get iOS API Key**: 
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing
   - Enable **Maps SDK for iOS**
   - Create credentials → iOS API Key

2. **Configure API Key**:
   ```bash
   # Edit ios/Runner/Info.plist and replace:
   <string>YOUR_IOS_API_KEY_HERE</string>
   # with your actual API key
   ```

### **3. Install Dependencies**
```bash
# Install Flutter dependencies
flutter pub get

# Install iOS CocoaPods
cd ios
pod install
cd ..
```

### **4. Start Backend Server**
```bash
# In a separate terminal, start the recommendation API
python3 predictive_in_park.py
# Server will run on http://127.0.0.1:5000
```

### **5. Run on iOS**
```bash
# List available iOS simulators
flutter devices

# Run on iOS Simulator
flutter run -d "iPhone 15 Pro"

# Or run on physical device (requires Apple Developer account)
flutter run -d "Your iPhone Name"
```

## 📱 **iOS-Specific Features**

### **Location Services**
- **Always/When-In-Use**: Smart location tracking while in Universal Parks
- **Background Updates**: Continues recommendations even when app is backgrounded
- **Privacy Compliant**: Clear permission requests with usage descriptions

### **iOS Permissions**
The app requests these iOS permissions:
- `NSLocationWhenInUseUsageDescription`: For park navigation
- `NSLocationAlwaysAndWhenInUseUsageDescription`: For continuous recommendations
- `NSCameraUsageDescription`: For QR code scanning (future feature)
- `NSPhotoLibraryUsageDescription`: For saving park memories

### **iOS Optimization**
- **Native iOS Maps**: Optimized for iPhone and iPad
- **iOS 12+**: Compatible with modern iOS devices
- **Memory Efficient**: Optimized for mobile performance

## 🎯 **How to Use on iOS**

### **iPhone Navigation**
1. Launch **Universal Orlando** from your home screen
2. Tap the **Map** tab to see all parks
3. Use pinch gestures to zoom in/out
4. Tap park markers to zoom into specific areas
5. Tap the blue **chat button** (bottom right) for AI assistant

### **iPad Experience**
- **Larger Map View**: Enhanced park exploration
- **Split Screen**: Use alongside other apps
- **Better Typing**: Improved chatbot interaction

### **Chatbot on iOS**
The AI assistant responds to natural language:

```
🎢 "What's the best ride right now?"
🍕 "I'm hungry, where should I eat?"
🛍️ "Where can I buy Harry Potter souvenirs?"
⏰ "Which rides have the shortest wait?"
🗺️ "How do I get to Hagrid's ride?"
```

## 🔧 **iOS Configuration**

### **Xcode Project Setup**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your development team
3. Configure bundle identifier
4. Add your iOS API key to Info.plist

### **Device Testing**
```bash
# Install on connected iPhone/iPad
flutter install

# View logs while testing
flutter logs
```

### **App Store Preparation**
```bash
# Build for release
flutter build ios --release

# Archive in Xcode for App Store submission
```

## 📁 **iOS Project Structure**

```
ios/
├── Runner/
│   ├── Info.plist              # iOS permissions & API keys
│   ├── AppDelegate.swift       # Google Maps initialization
│   └── Runner.entitlements     # iOS capabilities
├── Runner.xcworkspace          # Open this in Xcode
├── Podfile                     # iOS dependencies
└── RunnerTests/                # iOS unit tests
```

## 🛠️ **Development Workflow**

### **iOS Simulator Testing**
```bash
# Launch specific simulator
flutter run -d "iPhone 15 Pro Max"
flutter run -d "iPad Air (5th generation)"

# Hot reload during development
# Press 'r' in terminal to reload
# Press 'R' for hot restart
```

### **Physical Device Testing**
1. Connect iPhone/iPad via USB
2. Trust computer on device
3. Run: `flutter run`
4. App installs and launches automatically

## 🔍 **Debugging on iOS**

### **Common Issues & Solutions**

**Google Maps Not Loading:**
```bash
# Verify API key is correct in Info.plist
# Check Google Cloud Console that iOS API is enabled
# Ensure bundle ID matches Google Console configuration
```

**Location Not Working:**
```bash
# Check iOS Simulator → Features → Location
# Verify permission strings in Info.plist
# Test on physical device for accurate GPS
```

**Build Errors:**
```bash
# Clean and rebuild
flutter clean
cd ios && pod install && cd ..
flutter run
```

## 🎨 **iOS UI/UX Design**

### **iOS Design System**
- **Universal Blue**: `#1976D2` primary color
- **iOS Native**: Uses Cupertino design elements
- **Dynamic Type**: Supports iOS accessibility features
- **Dark Mode**: Automatic system appearance support

### **iOS-Specific Features**
- **Haptic Feedback**: Touch responses for interactions
- **Safe Areas**: Proper iPhone notch handling
- **Swipe Gestures**: iOS-native navigation patterns

## 🚀 **Deployment**

### **TestFlight Distribution**
```bash
# Build for TestFlight
flutter build ios --release
# Archive in Xcode and upload to App Store Connect
```

### **App Store Submission**
1. Update version in `pubspec.yaml`
2. Build release version
3. Archive in Xcode
4. Submit to App Store Connect
5. Configure app metadata
6. Submit for review

## 🎯 **RFP Compliance**

This iOS app fulfills the **"Experiential In-Park Itinerary"** use case:

✅ **Native iOS Experience** with optimal performance  
✅ **Real-time recommendations** based on purchased products and engagement  
✅ **Location-aware suggestions** using iOS Core Location  
✅ **Inventory availability** through live wait time integration  
✅ **Personalized experience** via chat-based interaction  
✅ **iOS-optimized UI** following Apple Human Interface Guidelines  

## 🤝 **iOS Development**

### **Requirements**
- **macOS**: Required for iOS development
- **Xcode 15+**: Latest version recommended
- **Apple Developer Account**: For device testing and App Store

### **Getting Started**
1. Clone repository
2. Run `flutter pub get`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Configure signing & capabilities
5. Run on simulator or device

---

**🎢 Ready for your Universal Orlando iOS adventure!** 🎉 Built with ❤️ for iPhone and iPad. 