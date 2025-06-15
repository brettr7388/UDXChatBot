# ────────────────────────────────────────────────────────────────────────────────
# Cursor Agent Mode Script: Predictive In-Park Recommendation API
#
# STORY:
# You want a service that, whenever a user exits a ride at one of Universal Orlando's parks
# (Islands of Adventure, Universal Studios Florida, or Epic Universe), fetches live wait times,
# calculates which nearby ride has the shortest combined "distance + wait" score, and returns
# a "next ride" recommendation.
#
# This Python file does the following:
#  1. Knows each park's Queue-Times ID for live wait data.
#  2. Holds sample latitude/longitude for a few rides in each park.
#  3. Defines a helper (Haversine) to compute real‐world distances.
#  4. Fetches live wait times from queue‐times.com for the specified park.
#  5. Uses a simple "distance + wait * 10" heuristic to pick the best next ride.
#  6. Exposes a Flask API endpoint (/recommend) that accepts JSON and returns the recommendation.
#
# STEPS FOR CURSOR AGENT:
# 1. Ensure Python 3.x is installed.
# 2. Install dependencies:
#       pip install requests flask python-dotenv
# 3. Save this file as `predictive_in_park.py`.
# 4. Run it locally:
#       python predictive_in_park.py
# 5. Verify the service is running on http://localhost:5000.
# 6. Test with a POST request (for example using curl or Postman):
#       POST http://localhost:5000/recommend
#       Payload:
#         {
#           "last_ride": "Flight of the Hippogriff",
#           "park": "Islands of Adventure",
#           "weather": "sunny",
#           "hour": 14
#         }
#    You should get back a JSON recommending the next ride.
# 7. Once verified, integrate this endpoint into your Flutter mobile app.
# 8. To expand later, collect historical ride‐sequence + wait‐time data, train a decision‐tree/XGBoost,
#    and replace the simple heuristic in `recommend_next_ride` with a model inference call.
# ────────────────────────────────────────────────────────────────────────────────

import os
import requests
from flask import Flask, request, jsonify
from math import radians, cos, sin, sqrt, atan2
import random
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)

# Configuration from environment variables
FLASK_HOST = os.getenv('FLASK_HOST', '127.0.0.1')
FLASK_PORT = int(os.getenv('FLASK_PORT', 5000))
FLASK_DEBUG = os.getenv('FLASK_DEBUG', 'false').lower() == 'true'

# ────────────────────────────────────────────────────────────────────────────────
# 1) PARK IDs FOR UNIVERSAL ORLANDO (Queue-Times API)
#    – Islands of Adventure:     ID = 64
#    – Universal Studios Florida: ID = 65
#    – Epic Universe:            ID = 334
#    Base URL format: https://queue-times.com/parks/{PARK_ID}/queue_times.json
# ────────────────────────────────────────────────────────────────────────────────

PARK_IDS = {
    "Islands of Adventure": 64,
    "Universal Studios": 65,
    "Epic Universe": 334
}

QUEUE_TIMES_BASE = "https://queue-times.com/parks/{}/queue_times.json"

# ────────────────────────────────────────────────────────────────────────────────
# 2) SAMPLE RIDE COORDINATES (latitude, longitude in decimal degrees)
#    Add more rides here as needed for each park.
# ────────────────────────────────────────────────────────────────────────────────

RIDE_COORDS = {
    # Islands of Adventure (with exact names from API)
    "Harry Potter and the Forbidden Journey™": (28.472621, -81.472998),  # pre‐supplied
    "Flight of the Hippogriff™": (28.472233, -81.472426),  # pre‐supplied
    "Hagrid's Magical Creatures Motorbike Adventure™": (28.472800, -81.473200),  # pre‐supplied
    "Jurassic World VelociCoaster": (28.471231, -81.472616),  # :contentReference[oaicite:0]{index=0}
    "The Incredible Hulk Coaster®": (28.471513, -81.468761),  # :contentReference[oaicite:1]{index=1}
    "The Amazing Adventures of Spider-Man®": (28.470403, -81.469899),  # :contentReference[oaicite:2]{index=2}
    "Skull Island: Reign of Kong™": (28.473000, -81.473400),  # pre‐supplied
    "Jurassic Park River Adventure™": (28.470427, -81.474121),  # :contentReference[oaicite:5]{index=5}
    "Pteranodon Flyers™": (28.470361, -81.472599),  # :contentReference[oaicite:7]{index=7}
    "Doctor Doom's Fearfall®": (28.470539, -81.469285),  # :contentReference[oaicite:9]{index=9}
    "Storm Force Accelatron®": (28.470539, -81.469285),  # same coords as Doctor Doom's (adjacent) :contentReference[oaicite:10]{index=10}
    "Caro-Seuss-el™": (28.472880, -81.469567),  # :contentReference[oaicite:11]{index=11}
    "One Fish, Two Fish, Red Fish, Blue Fish™": (28.472949, -81.469099),  # :contentReference[oaicite:12]{index=12}
    "The Cat In The Hat™": (28.472949, -81.469099),  # :contentReference[oaicite:13]{index=13}
    "The High in the Sky Seuss Trolley Train Ride!™": (28.472800, -81.468900),  # approx. above Seuss Landing (no direct source)
    "Dudley Do-Right's Ripsaw Falls®": (28.469184, -81.471634),  # :contentReference[oaicite:14]{index=14}
    "Popeye & Bluto's Bilge-Rat Barges®": (28.470470, -81.471738),  # :contentReference[oaicite:15]{index=15}

    # Universal Studios Florida
    "Revenge of the Mummy™": (28.476781, -81.469866),  # pre‐supplied
    "Hollywood Rip Ride Rockit™": (28.474962, -81.468417),  # :contentReference[oaicite:16]{index=16}
    "E.T. Adventure™": (28.477729, -81.466626),  # approximate based on park map (no direct source)
    "Despicable Me Minion Mayhem™": (28.475272, -81.468103),  # approximate in Minion Land (no direct source)
    "Illumination's Villain-Con Minion Blast": (28.475636, -81.467976),  # same Land as Minion Mayhem (no direct source)
    "Race Through New York Starring Jimmy Fallon™": (28.4756833, -81.46945),  # :contentReference[oaicite:17]{index=17}
    "TRANSFORMERS™: The Ride-3D": (28.47638, -81.468506),  # approximate in Production Central (no direct source)
    "Fast & Furious - Supercharged™": (28.478105, -81.469609),  # approximate in San Francisco land (no direct source)
    "Harry Potter and the Escape from Gringotts™": (28.479903, -81.470182),  # same as King's Cross area (no direct source)
    "Kang & Kodos' Twirl 'n' Hurl": (28.479345, -81.467864),  # approximate in World Expo (no direct source)
    "MEN IN BLACK™ Alien Attack!™": (28.480728, -81.467669),  # same land (no direct source)
    "The Simpsons Ride™": (28.4794389, -81.4673639),  # same World Expo coordinates (no direct source)

    # Epic Universe (with exact names from API)
    "Constellation Carousel": (28.473200, -81.472900),  # approximate in Celestial Park (no direct source)
    "Stardust Racers": (28.473500, -81.472750),  # pre‐supplied
    "Curse of the Werewolf": (28.473800, -81.473100),  # approximate in Dark Universe (no direct source)
    "Monsters Unchained: The Frankenstein Experiment": (28.474000, -81.473300),  # approximate (no direct source)
    "Dragon Racer's Rally": (28.473900, -81.472800),  # approximate in Isle of Berk (no direct source)
    "Fyre Drill": (28.473700, -81.472900),  # approximate (no direct source)
    "Hiccup Wing Glider": (28.473800, -81.472850),  # approximate (no direct source)
    "Mario Kart™: Bowser's Challenge": (28.474100, -81.472650),  # approximate (no direct source)
    "Mine-Cart Madness™": (28.474200, -81.472550),  # approximate (no direct source)
    "Yoshi's Adventure™": (28.474300, -81.472500),  # approximate (no direct source)
    "Harry Potter and the Battle at the Ministry™": (28.473246, -81.472388),  # :contentReference[oaicite:19]{index=19}
}


# ────────────────────────────────────────────────────────────────────────────────
# 3) HELPER FUNCTION: HAVERSINE DISTANCE
#    Computes the distance (in meters) between two (lat, lon) coordinates.
# ────────────────────────────────────────────────────────────────────────────────

def haversine(coord1, coord2):
    lat1, lon1 = coord1
    lat2, lon2 = coord2
    # convert decimal degrees to radians
    rlat1, rlon1, rlat2, rlon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = rlat2 - rlat1
    dlon = rlon2 - rlon1

    a = sin(dlat / 2)**2 + cos(rlat1) * cos(rlat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    R = 6371000  # Earth radius in meters
    return R * c

# ────────────────────────────────────────────────────────────────────────────────
# 4) FETCH REAL-TIME WAIT TIMES FOR A GIVEN PARK
#    Returns a dict: { ride_name: wait_time_in_minutes, ... }
# ────────────────────────────────────────────────────────────────────────────────

def fetch_wait_times(park_id):
    """
    Fetch the live wait times JSON from Queue-Times.
    Returns a dict mapping ride names to their current wait times.
    """
    url = QUEUE_TIMES_BASE.format(park_id)
    try:
        resp = requests.get(url, timeout=5)
        resp.raise_for_status()
        data = resp.json()
        rides_section = data.get("lands", [])  # each "land" has a list of rides
        wait_times = {}
        for land in rides_section:
            for ride in land.get("rides", []):
                name = ride.get("name")
                wt = ride.get("wait_time", 0)
                is_open = ride.get("is_open", False)
                # Only include open rides with positive wait times
                if name and is_open:
                    wait_times[name] = wt
        return wait_times
    except Exception as e:
        print(f"Error fetching wait times for park {park_id}: {e}")
        return {}

# ────────────────────────────────────────────────────────────────────────────────
# 5) RECOMMENDATION ALGORITHM (SIMPLE HEURISTIC)
#    Steps:
#      1. Take the user's last ride (string) and look up its coords.
#      2. Fetch current wait times for the given park.
#      3. For every other open ride with known coords, compute:
#            distance (meters) + (wait_time * 10).
#      4. Choose the ride with the lowest combined score.
# ────────────────────────────────────────────────────────────────────────────────

def recommend_next_ride(last_ride, current_park_name, weather=None, hour=None, exclude_rides=None):
    """
    last_ride: e.g., "Harry Potter and the Forbidden Journey"
    current_park_name: one of the keys in PARK_IDS ("Islands of Adventure", etc.)
    weather: optional string ("sunny", "rainy", etc.)
    hour: optional int (0-23)
    exclude_rides: optional list of ride names to exclude from recommendations
    """
    park_id = PARK_IDS.get(current_park_name)
    if not park_id:
        return {"error": f"Unknown park '{current_park_name}'"}

    # 1) Fetch live wait times
    wait_times = fetch_wait_times(park_id)

    # 2) Check that we have coordinates for the last ride
    if last_ride not in RIDE_COORDS:
        return {"error": f"Coordinates for '{last_ride}' not found"}

    last_coord = RIDE_COORDS[last_ride]
    best_score = float("inf")
    best_ride = None
    best_ride_wait = None
    best_distance = None

    # Convert exclude_rides to set for faster lookup
    excluded = set(exclude_rides or [])

    # 3) Find the best ride considering exclusions
    for ride_name, wait_time in wait_times.items():
        # Skip the last ride and any excluded rides
        if ride_name == last_ride or ride_name in excluded:
            continue
            
        if ride_name not in RIDE_COORDS:
            continue  # Skip rides we don't have coordinates for

        ride_coord = RIDE_COORDS[ride_name]
        distance_m = haversine(last_coord, ride_coord)

        # Simple heuristic: distance + (wait_time * 10)
        # You can tune these weights or add weather/hour modifiers
        score = distance_m + (wait_time * 10)

        if score < best_score:
            best_score = score
            best_ride = ride_name
            best_ride_wait = wait_time
            best_distance = distance_m

    # 4) If no suitable ride found, try to find any available ride not in exclusions
    if best_ride is None:
        available_rides = [r for r in wait_times.keys() if r not in excluded and r != last_ride and r in RIDE_COORDS]
        if available_rides:
            # Pick a random available ride
            best_ride = random.choice(available_rides)
            best_ride_wait = wait_times[best_ride]
            best_distance = haversine(last_coord, RIDE_COORDS[best_ride])
        else:
            return {"error": "No suitable rides available (all may be excluded or closed)"}

    return {
        "recommendation": best_ride,
        "wait_time": best_ride_wait,
        "distance_meters": best_distance,
        "excluded_count": len(excluded),
        "last_ride": last_ride
    }

# ────────────────────────────────────────────────────────────────────────────────
# 6) FLASK ENDPOINT: /recommend
#    Expects JSON payload:
#      {
#        "last_ride": "Harry Potter and the Forbidden Journey",
#        "park": "Islands of Adventure",
#        "weather": "sunny",
#        "hour": 14,
#        "exclude_rides": ["The Simpsons Ride™", "MEN IN BLACK™ Alien Attack!™"]
#      }
#    Returns JSON with the recommendation.
# ────────────────────────────────────────────────────────────────────────────────

@app.route('/recommend', methods=['POST'])
def recommend_endpoint():
    """
    Expected JSON:
    {
      "last_ride": "Harry Potter and the Forbidden Journey",
      "park": "Islands of Adventure",
      "weather": "sunny",
      "hour": 14,
      "exclude_rides": ["The Simpsons Ride™", "MEN IN BLACK™ Alien Attack!™"]
    }
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "No JSON provided"}), 400

    last_ride = data.get("last_ride")
    park = data.get("park")
    weather = data.get("weather", "sunny")
    hour = data.get("hour", 14)
    exclude_rides = data.get("exclude_rides", [])

    if not last_ride or not park:
        return jsonify({"error": "Missing 'last_ride' or 'park' in request"}), 400

    result = recommend_next_ride(last_ride, park, weather, hour, exclude_rides)
    return jsonify(result)

@app.route('/debug', methods=['GET'])
def debug_endpoint():
    """Debug endpoint to see what wait times are being fetched"""
    park_id = 64  # Islands of Adventure
    wait_times = fetch_wait_times(park_id)
    return jsonify({
        "park_id": park_id,
        "wait_times": wait_times,
        "ride_coords_available": list(RIDE_COORDS.keys())
    })

# ────────────────────────────────────────────────────────────────────────────────
# 7) MAIN GUARD: RUN FLASK APP
#
#    In development, run: python predictive_in_park.py
#    Then POST to http://localhost:5000/recommend
#
#    Example curl test:
#      curl -X POST http://localhost:5000/recommend \
#           -H "Content-Type: application/json" \
#           -d '{"last_ride":"Flight of the Hippogriff","park":"Islands of Adventure","weather":"sunny","hour":14}'
# ────────────────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    app.run(debug=FLASK_DEBUG, port=FLASK_PORT, host=FLASK_HOST) 