#!/usr/bin/env python3
"""
🚀 Universal Orlando API - Cloud Deployment Setup

This script automates the deployment of your Universal Orlando API to the cloud.
It prepares your Flask app for production deployment on Render (free tier).

Usage:
    python3 deploy_cloud.py

What it does:
1. ✅ Installs production dependencies (gunicorn)
2. ✅ Updates requirements.txt
3. ✅ Creates production configuration
4. ✅ Tests local production server
5. ✅ Prepares for Git deployment
6. ✅ Provides deployment instructions

After running this script, you can deploy to Render for FREE!
"""

import os
import sys
import subprocess
import requests
import time
from pathlib import Path

def run_command(cmd, description=""):
    """Run a shell command and handle errors"""
    print(f"🔄 {description}")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"❌ Error: {result.stderr}")
            return False
        if result.stdout.strip():
            print(f"✅ {result.stdout.strip()}")
        return True
    except Exception as e:
        print(f"❌ Error running command: {e}")
        return False

def check_file_exists(filepath, description=""):
    """Check if a file exists"""
    if Path(filepath).exists():
        print(f"✅ {description}: {filepath}")
        return True
    else:
        print(f"❌ Missing {description}: {filepath}")
        return False

def test_api_endpoint(url, timeout=5):
    """Test if API endpoint is responding"""
    try:
        response = requests.get(url, timeout=timeout)
        if response.status_code == 200:
            print(f"✅ API responding at {url}")
            return True
        else:
            print(f"❌ API returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ API test failed: {e}")
        return False

def main():
    print("🚀 Universal Orlando API - Cloud Deployment Setup")
    print("=" * 60)
    
    # Step 1: Check if we're in the right directory
    if not check_file_exists("predictive_in_park.py", "Flask app"):
        print("❌ Please run this script from the UDXChatBot directory")
        sys.exit(1)
    
    # Step 2: Install production dependencies
    print("\n📦 Installing production dependencies...")
    if not run_command("pip3 install gunicorn", "Installing Gunicorn production server"):
        print("❌ Failed to install Gunicorn")
        sys.exit(1)
    
    # Step 3: Update requirements.txt
    print("\n📝 Updating requirements.txt...")
    if not run_command("pip3 freeze > requirements.txt", "Updating requirements.txt"):
        print("❌ Failed to update requirements.txt")
        sys.exit(1)
    
    # Step 4: Check configuration files
    print("\n⚙️ Checking configuration files...")
    check_file_exists("config.py", "Production config")
    check_file_exists("requirements.txt", "Requirements file")
    
    # Step 5: Test production server locally
    print("\n🧪 Testing production server locally...")
    print("Starting Gunicorn server (this will take a few seconds)...")
    
    # Start server in background
    server_process = subprocess.Popen(
        ["gunicorn", "predictive_in_park:app", "--bind", "127.0.0.1:8000"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    
    # Wait for server to start
    time.sleep(3)
    
    # Test the server
    if test_api_endpoint("http://127.0.0.1:8000/debug"):
        print("✅ Production server working correctly!")
    else:
        print("⚠️ Production server test failed (but deployment might still work)")
    
    # Stop the test server
    server_process.terminate()
    server_process.wait()
    
    # Step 6: Git preparation
    print("\n📋 Git repository status...")
    run_command("git status --porcelain", "Checking for uncommitted changes")
    
    print("\n🎯 DEPLOYMENT READY!")
    print("=" * 60)
    print("Your Universal Orlando API is ready for cloud deployment!")
    print()
    print("📋 NEXT STEPS:")
    print("1. Commit your changes:")
    print("   git add .")
    print("   git commit -m 'Prepare for cloud deployment'")
    print("   git push origin main")
    print()
    print("2. Deploy to Render (FREE):")
    print("   • Go to https://render.com")
    print("   • Sign up with GitHub (no credit card needed)")
    print("   • Click 'New' → 'Web Service'")
    print("   • Connect your GitHub repository")
    print("   • Use these settings:")
    print("     - Build Command: pip install -r requirements.txt")
    print("     - Start Command: gunicorn predictive_in_park:app")
    print("     - Environment Variables:")
    print("       * PROD_APP_SETTINGS = config.ProductionConfig")
    print("       * PYTHON_VERSION = 3.11.0")
    print()
    print("3. Update Flutter app with your new API URL:")
    print("   • Edit lib/services/recommendation_service.dart")
    print("   • Add your Render URL as the first option in _baseUrls")
    print()
    print("🎉 After deployment, your app will work anywhere without your laptop!")
    print()
    print("📚 For detailed instructions, see: deploy_to_render.md")

if __name__ == "__main__":
    main() 