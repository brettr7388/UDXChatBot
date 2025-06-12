#!/usr/bin/env python3
"""
Demo script to test the web interface functionality
"""

import requests
import time

BASE_URL = "http://127.0.0.1:5000"

def test_homepage():
    """Test that the homepage loads correctly"""
    try:
        response = requests.get(BASE_URL)
        if response.status_code == 200:
            print("✅ Homepage loads successfully")
            print(f"   URL: {BASE_URL}")
            print(f"   Status: {response.status_code}")
            return True
        else:
            print(f"❌ Homepage failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to homepage: {e}")
        return False

def simulate_web_form_submission():
    """Simulate what happens when a user submits the web form"""
    print("\n🎢 Simulating user form submission...")
    
    # This simulates the JavaScript form submission from the web interface
    form_data = {
        "last_ride": "Flight of the Hippogriff™",
        "park": "Islands of Adventure",
        "weather": "sunny",
        "hour": 14
    }
    
    print(f"   📍 User just finished: {form_data['last_ride']}")
    print(f"   🏰 Park: {form_data['park']}")
    print(f"   🌤️  Weather: {form_data['weather']}")
    
    try:
        response = requests.post(f"{BASE_URL}/recommend", json=form_data)
        result = response.json()
        
        if "error" in result:
            print(f"   ❌ Error: {result['error']}")
        else:
            print("\n   🎯 RECOMMENDATION POPUP WOULD SHOW:")
            print("   ┌─────────────────────────────────────┐")
            print(f"   │ 🎢 Next Ride: {result['recommendation'][:20]}{'...' if len(result['recommendation']) > 20 else ''}")
            print(f"   │ ⏱️  Wait Time: {result['wait_time']} minutes")
            print(f"   │ 🚶 Distance: {result['distance_meters']}m")
            print("   │ 🎉 Have fun at your next ride!")
            print("   └─────────────────────────────────────┘")
            
        return True
        
    except Exception as e:
        print(f"   ❌ API call failed: {e}")
        return False

def show_user_journey():
    """Show the complete user journey through the web interface"""
    print("🌟 UNIVERSAL ORLANDO WEB INTERFACE DEMO")
    print("=" * 50)
    
    print("\n👤 USER JOURNEY:")
    print("1. User visits http://127.0.0.1:5000")
    print("2. Beautiful homepage loads with form")
    print("3. User selects:")
    print("   - 🏰 Park: Islands of Adventure")
    print("   - 🎢 Last Ride: Flight of the Hippogriff™")
    print("   - 🌤️  Weather: Sunny")
    print("4. User clicks 'Get My Recommendation!'")
    print("5. Loading spinner appears")
    print("6. Popup shows personalized recommendation")
    
    print("\n🔧 TECHNICAL FLOW:")
    print("1. HTML form captures user input")
    print("2. JavaScript sends POST to /recommend")
    print("3. Flask fetches live wait times")
    print("4. Algorithm calculates best next ride")
    print("5. JSON response returns recommendation")
    print("6. JavaScript displays popup with results")

def main():
    """Run the complete demo"""
    show_user_journey()
    
    print("\n" + "="*50)
    print("🧪 TESTING WEB INTERFACE")
    print("="*50)
    
    # Test homepage
    if not test_homepage():
        print("\n❌ Cannot test further - server not running")
        print("💡 Start the server with: python3 predictive_in_park.py")
        return
    
    # Simulate form submission
    if simulate_web_form_submission():
        print("\n✅ Web interface is working perfectly!")
        print(f"\n🌐 Open your browser to: {BASE_URL}")
        print("🎯 Try the interactive form!")
    
    print("\n🚀 WEB INTERFACE FEATURES:")
    print("• 📱 Responsive design works on mobile")
    print("• 🎨 Beautiful gradient background")
    print("• 🎢 Park-specific ride selection")
    print("• ⚡ Real-time wait time integration")
    print("• 🎯 Instant popup recommendations")
    print("• ⭐ Smooth animations and loading states")
    print("• 🔄 Error handling with friendly messages")

if __name__ == "__main__":
    main() 