# 🔧 Universal Orlando App Troubleshooting Guide

This guide addresses the common issues experienced when using the app in Universal Orlando parks.

## 🚨 Common Issues & Solutions

### 1. **API Not Giving Correct Wait Times**

**Problem:** The app shows incorrect or no wait times for rides.

**Root Causes:**
- App can't connect to Flask server when phone is not connected to laptop
- API server not running
- Network connectivity issues

**Solutions:**

#### Option A: Mobile Setup (Recommended for park use)
```bash
# Run this before going to the parks
python3 setup_mobile.py
```

This will:
- Configure your app to use your laptop's IP address
- Install required dependencies
- Set up proper network configuration

#### Option B: Manual Configuration
1. Find your laptop's IP address:
   ```bash
   # On Mac/Linux
   ifconfig | grep "inet " | grep -v 127.0.0.1
   
   # On Windows
   ipconfig | findstr "IPv4"
   ```

2. Update `lib/services/recommendation_service.dart`:
   ```dart
   static const List<String> _fallbackUrls = [
     'http://YOUR_LAPTOP_IP:5001',  // Replace with your IP - Note: port 5001
     'http://127.0.0.1:5001',
   ];
   ```

3. Start the server with network access:
   ```bash
   python3 predictive_in_park.py
   ```

#### Option C: Offline Mode Enhancement
The app now includes better fallback recommendations when the API is unavailable.

---

### 2. **Location Not Working in Parks**

**Problem:** App can't detect your location or nearby rides.

**Root Causes:**
- GPS signal blocked by buildings/crowds
- Location permissions not granted
- Proximity threshold too strict (was 30m, now 100m)
- iOS location accuracy issues

**Solutions:**

#### Immediate Fixes:
1. **Check Permissions:**
   - iOS: Settings > Privacy & Security > Location Services > Your App > "While Using App"
   - Enable "Precise Location"

2. **Improve GPS Signal:**
   - Move to open areas when possible
   - Wait 30-60 seconds for GPS to lock
   - Restart the app if location is stuck

3. **Use Manual Location (Testing):**
   - Tap the location testing button in the map
   - Select your current area manually
   - This helps test the chatbot without GPS

#### Technical Improvements Made:
- Increased proximity threshold from 30m to 100m
- Added location accuracy filtering (ignores readings >100m accuracy)
- Better error handling and retry logic
- Improved location settings for iOS

---

### 3. **Chatbot Giving Poor Recommendations**

**Problem:** Chatbot suggests rides that are far away or not relevant.

**Root Causes:**
- Can't connect to recommendation API (same as issue #1)
- Falls back to random recommendations
- Not using actual user location
- Doesn't consider current wait times

**Solutions:**

#### API Connection (Primary Fix):
Follow the solutions from Issue #1 above to restore API connectivity.

#### Improved Fallback System:
The chatbot now has better fallback behavior:
- Uses park-specific ride lists
- Prioritizes popular rides
- Considers previously visited rides
- Provides reasonable default wait times

#### Better Location Integration:
- App now tracks visited rides more reliably
- Chatbot uses actual location data when available
- Manual location setting for testing

---

## 📱 Pre-Park Setup Checklist

Run this setup before visiting the parks:

```bash
# 1. Run mobile setup
python3 setup_mobile.py

# 2. Test the API
python3 test_api.py

# 3. Start the server
python3 predictive_in_park.py
```

**What you should see:**
```
🎢 Universal Orlando Recommendation API Starting...
============================================================
📱 For mobile devices, use: http://192.168.1.XXX:5001
💻 For local testing, use: http://127.0.0.1:5001
============================================================
```

## 🌐 Network Setup for Parks

### WiFi Requirements:
- **Both devices** (laptop + phone) on same WiFi network
- Universal Orlando Guest WiFi works
- Hotel WiFi works
- Personal hotspot works

### Firewall Settings:
```bash
# Mac: Allow Python through firewall
# Windows: Allow Python app through Windows Defender

# Test connectivity from phone browser:
http://YOUR_LAPTOP_IP:5001/debug
```

💡 Tip: Make sure your firewall allows connections on port 5001

## 🧪 Testing in Parks

### Location Testing:
1. Open the map screen
2. Tap the testing panel button
3. Set your location manually
4. Test chatbot recommendations

### API Testing:
1. Open chatbot
2. Ask "debug" or "status"
3. Check if location and API are working
4. Look for error messages

### Manual Ride Tracking:
If GPS isn't working:
1. Tell chatbot which ride you just went on
2. Ask for recommendations based on that
3. Use the directions feature

## 🔍 Advanced Debugging

### Check Logs:
```bash
# In Xcode (iOS):
# View > Debug Area > Console
# Look for location and API error messages

# In Android Studio:
# View > Tool Windows > Logcat
# Filter by your app package name
```

### Network Debugging:
```bash
# Test API from command line:
curl -X GET http://YOUR_LAPTOP_IP:5001/debug

# Test recommendation:
curl -X POST http://YOUR_LAPTOP_IP:5001/recommend \
  -H "Content-Type: application/json" \
  -d '{"last_ride": "Flight of the Hippogriff™", "park": "Islands of Adventure"}'
```

## 📞 Still Having Issues?

### Common Error Messages:

**"Could not connect to recommendation service"**
- Solution: Follow API connection fixes above

**"Location accuracy too poor"**
- Solution: Move to open area, wait for better GPS signal

**"No suitable rides available"**
- Solution: Clear visited rides or try different park

### Quick Fixes:
1. Restart the Flask server
2. Restart the Flutter app
3. Check WiFi connection on both devices
4. Try manual location setting

### Emergency Fallback:
If nothing works, the app will still function with:
- Manual location setting
- Offline ride recommendations
- Basic park information

The core functionality remains available even without perfect API/GPS connectivity.

---

## 🎯 Success Indicators

When everything is working correctly:
- ✅ Location updates show in debug logs
- ✅ API debug endpoint returns wait times
- ✅ Chatbot gives relevant, nearby recommendations
- ✅ Recommendations consider actual wait times
- ✅ Visited rides are tracked automatically

Your Universal Orlando experience should now be significantly improved! 🎢 