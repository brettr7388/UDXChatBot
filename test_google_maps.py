#!/usr/bin/env python3
"""
Test script to verify Google Maps integration is working
Run this after setting up your API key
"""

import requests
import webbrowser
import time
from urllib.parse import quote

def test_google_maps_api(api_key):
    """Test if the Google Maps API key is valid"""
    print("🔍 Testing Google Maps API key...")
    
    # Test the JavaScript API endpoint
    test_url = f"https://maps.googleapis.com/maps/api/js?key={api_key}"
    
    try:
        response = requests.get(test_url)
        if response.status_code == 200 and 'google.maps' in response.text:
            print("✅ Google Maps API key is valid!")
            return True
        else:
            print(f"❌ API key test failed. Status: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing API key: {e}")
        return False

def check_flask_app():
    """Check if the Flask app is running"""
    print("\n🔍 Checking if Flask app is running...")
    
    try:
        response = requests.get("http://127.0.0.1:5000", timeout=5)
        if response.status_code == 200:
            print("✅ Flask app is running!")
            return True
        else:
            print(f"❌ Flask app returned status: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Flask app is not running. Please start it with: python3 predictive_in_park.py")
        return False
    except Exception as e:
        print(f"❌ Error checking Flask app: {e}")
        return False

def test_recommendation_api():
    """Test the recommendation API endpoint"""
    print("\n🔍 Testing recommendation API...")
    
    test_data = {
        "last_ride": "Harry Potter and the Forbidden Journey™",
        "park": "Islands of Adventure",
        "weather": "sunny",
        "hour": 14
    }
    
    try:
        response = requests.post(
            "http://127.0.0.1:5000/recommend",
            json=test_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            if 'recommendation' in result:
                print("✅ Recommendation API is working!")
                print(f"   📍 Recommended: {result['recommendation']}")
                print(f"   ⏱️  Wait time: {result['wait_time']} minutes")
                print(f"   🚶 Distance: {result['distance_meters']}m")
                return True
            else:
                print(f"❌ API returned unexpected format: {result}")
                return False
        else:
            print(f"❌ API request failed with status: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error testing recommendation API: {e}")
        return False

def open_browser_test():
    """Open the web interface in browser"""
    print("\n🌐 Opening web interface for manual testing...")
    try:
        webbrowser.open("http://127.0.0.1:5000")
        print("✅ Browser opened! Check if the Google Maps loads correctly.")
        return True
    except Exception as e:
        print(f"❌ Error opening browser: {e}")
        return False

def main():
    print("🎢 Universal Orlando Ride Recommender - Google Maps Test")
    print("=" * 60)
    
    # Get API key from user
    print("\n📋 Before running this test:")
    print("1. Make sure you've set up your Google Maps API key")
    print("2. Updated the HTML file with your API key")
    print("3. Started your Flask app in another terminal")
    
    api_key = input("\n🔑 Enter your Google Maps API key (or press Enter to skip API test): ").strip()
    
    results = []
    
    # Test API key if provided
    if api_key:
        results.append(test_google_maps_api(api_key))
    else:
        results.append(True)  # Skip this test
    
    # Test Flask app
    results.append(check_flask_app())
    
    # Test recommendation API if Flask is running
    if results[-1]:  # If Flask is running
        results.append(test_recommendation_api())
    else:
        results.append(False)
    
    # Open browser for manual testing
    if results[1]:  # If Flask is running
        results.append(open_browser_test())
    else:
        results.append(False)
    
    # Summary
    print("\n" + "=" * 60)
    print("📊 TEST SUMMARY:")
    print(f"   Google Maps API: {'✅ PASS' if results[0] else '❓ SKIPPED' if not api_key else '❌ FAIL'}")
    print(f"   Flask App: {'✅ PASS' if results[1] else '❌ FAIL'}")
    print(f"   Recommendation API: {'✅ PASS' if results[2] else '❌ FAIL'}")
    print(f"   Browser Test: {'✅ OPENED' if results[3] else '❌ FAIL'}")
    
    if all(results[:3]):  # Ignore browser test result
        print("\n🎉 All tests passed! Your Google Maps integration should be working!")
        print("\n💡 Next steps:")
        print("   1. Check the browser window that opened")
        print("   2. Select a park and ride")
        print("   3. Verify the map loads with Google Maps (not OpenStreetMap)")
        print("   4. Test getting a recommendation and see the path drawn")
    else:
        print("\n⚠️  Some tests failed. Please check the issues above.")
        print("\n🔧 Common solutions:")
        print("   - Make sure your Google Maps API key is correct")
        print("   - Ensure Maps JavaScript API is enabled in Google Cloud Console")
        print("   - Check that your Flask app is running")
        print("   - Verify your API key restrictions allow localhost")

if __name__ == "__main__":
    main() 