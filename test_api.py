#!/usr/bin/env python3
"""
Test script for the Universal Orlando Predictive In-Park Recommendation System
"""

import requests
import json

BASE_URL = "http://127.0.0.1:5000"

def test_recommendation(last_ride, park, weather=None, hour=None):
    """Test the recommendation endpoint"""
    payload = {
        "last_ride": last_ride,
        "park": park
    }
    if weather:
        payload["weather"] = weather
    if hour:
        payload["hour"] = hour
    
    try:
        response = requests.post(f"{BASE_URL}/recommend", json=payload)
        result = response.json()
        
        print(f"\n📍 Last Ride: {last_ride}")
        print(f"🏰 Park: {park}")
        if weather:
            print(f"🌤️  Weather: {weather}")
        if hour:
            print(f"🕐 Hour: {hour}")
        print("─" * 50)
        
        if "error" in result:
            print(f"❌ Error: {result['error']}")
        else:
            print(f"🎯 Recommendation: {result['recommendation']}")
            print(f"⏱️  Wait Time: {result['wait_time']} minutes")
            print(f"🚶 Walking Distance: {result['distance_meters']} meters")
            print(f"📊 Total Score: {result['distance_meters'] + (result['wait_time'] * 10):.1f}")
        
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection Error: {e}")
        print("Make sure the Flask server is running: python3 predictive_in_park.py")

def test_debug():
    """Test the debug endpoint to see available data"""
    try:
        response = requests.get(f"{BASE_URL}/debug")
        result = response.json()
        
        print("\n🔍 DEBUG INFO")
        print("─" * 50)
        print(f"🏰 Park ID: {result['park_id']} (Islands of Adventure)")
        print(f"🎢 Available Rides: {len(result['wait_times'])}")
        print(f"📍 Rides with Coordinates: {len(result['ride_coords_available'])}")
        
        print("\n🎢 Current Wait Times:")
        for ride, wait_time in sorted(result['wait_times'].items()):
            emoji = "📍" if ride in result['ride_coords_available'] else "❓"
            print(f"  {emoji} {ride}: {wait_time} min")
        
        print(f"\n📍 Rides with Known Coordinates:")
        for ride in result['ride_coords_available']:
            print(f"  ✅ {ride}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Connection Error: {e}")

def main():
    print("🎢 Universal Orlando Predictive In-Park Recommendation System")
    print("═" * 70)
    
    # Test debug endpoint first
    test_debug()
    
    # Test various scenarios
    print("\n\n🧪 TESTING SCENARIOS")
    print("═" * 70)
    
    # Scenario 1: From Flight of the Hippogriff
    test_recommendation(
        last_ride="Flight of the Hippogriff™",
        park="Islands of Adventure",
        weather="sunny",
        hour=14
    )
    
    # Scenario 2: From Harry Potter ride
    test_recommendation(
        last_ride="Harry Potter and the Forbidden Journey™",
        park="Islands of Adventure",
        weather="cloudy",
        hour=11
    )
    
    # Scenario 3: Invalid ride name
    test_recommendation(
        last_ride="Non-existent Ride",
        park="Islands of Adventure"
    )
    
    # Scenario 4: Invalid park
    test_recommendation(
        last_ride="Flight of the Hippogriff™",
        park="Magic Kingdom"
    )
    
    print(f"\n🎯 Test completed! Server is running at {BASE_URL}")
    print("Ready for n8n integration! 🚀")

if __name__ == "__main__":
    main() 