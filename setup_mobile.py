#!/usr/bin/env python3
"""
Mobile Setup Script for Universal Orlando ChatBot
This script helps configure the Flutter app to connect to the Flask API from mobile devices.
"""

import socket
import subprocess
import sys
from pathlib import Path

def get_local_ip():
    """Get the local IP address of this machine"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "127.0.0.1"

def update_flutter_config(local_ip):
    """Update the Flutter app configuration with the local IP"""
    service_file = Path("lib/services/recommendation_service.dart")
    
    if not service_file.exists():
        print("❌ Flutter service file not found!")
        return False
    
    # Read the current file
    with open(service_file, 'r') as f:
        content = f.read()
    
    # Replace the IP addresses in the fallback URLs
    updated_content = content.replace(
        'http://192.168.1.100:5001',
        f'http://{local_ip}:5001'
    ).replace(
        'http://10.0.0.100:5001',
        f'http://{local_ip}:5001'
    )
    
    # Write the updated content
    with open(service_file, 'w') as f:
        f.write(updated_content)
    
    return True

def install_dependencies():
    """Install required Python dependencies"""
    try:
        print("📦 Installing Python dependencies...")
        subprocess.run([sys.executable, "-m", "pip", "install", "-r", "requirements.txt"], check=True)
        return True
    except subprocess.CalledProcessError:
        print("❌ Failed to install Python dependencies")
        return False

def main():
    print("🎢 Universal Orlando Mobile Setup")
    print("=" * 50)
    
    # Get local IP
    local_ip = get_local_ip()
    print(f"🌐 Detected local IP: {local_ip}")
    
    # Install dependencies
    if not install_dependencies():
        return
    
    # Update Flutter configuration
    print("📱 Updating Flutter app configuration...")
    if update_flutter_config(local_ip):
        print("✅ Flutter app updated successfully!")
    else:
        print("❌ Failed to update Flutter app")
        return
    
    print("\n🚀 Setup Complete!")
    print("=" * 50)
    print("📋 Next Steps:")
    print("1. Start the API server:")
    print("   python3 predictive_in_park.py")
    print()
    print("2. Connect your phone to the same WiFi network")
    print()
    print("3. In your Flutter app, the API will try these URLs:")
    print(f"   • http://{local_ip}:5001 (your laptop)")
    print("   • http://127.0.0.1:5001 (localhost)")
    print()
    print("4. Run your Flutter app:")
    print("   flutter run")
    print()
    print("💡 Tip: Make sure your firewall allows connections on port 5001")

if __name__ == "__main__":
    main() 