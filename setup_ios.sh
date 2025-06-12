#!/bin/bash

echo "🎢 Universal Orlando iOS App Setup"
echo "=================================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null
then
    echo "❌ Xcode is not installed. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Flutter and Xcode detected"

# Flutter doctor check
echo "🔍 Running Flutter doctor..."
flutter doctor

# Install Flutter dependencies
echo "📦 Installing Flutter dependencies..."
flutter pub get

# Install iOS dependencies
echo "📱 Installing iOS CocoaPods..."
cd ios
pod install
cd ..

# Check for iOS simulators
echo "📱 Available iOS devices:"
flutter devices

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Get a Google Maps API key from: https://console.cloud.google.com/"
echo "2. Enable 'Maps SDK for iOS' in your Google Cloud project"
echo "3. Edit ios/Runner/Info.plist and replace YOUR_IOS_API_KEY_HERE with your actual key"
echo "4. Start the backend server: python3 predictive_in_park.py"
echo "5. Run the app: flutter run -d 'iPhone 15 Pro'"
echo ""
echo "🎢 Ready to build your Universal Orlando iOS app!" 