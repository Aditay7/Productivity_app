#!/bin/bash

# Solo Level Up - Setup and Run Script
# This script helps you set up and run the Flutter app

echo "🎮 Solo Level Up - Setup Script"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "❌ Flutter is not found in PATH"
    echo ""
    echo "Please install Flutter or add it to your PATH:"
    echo "1. Download Flutter from: https://flutter.dev/docs/get-started/install"
    echo "2. Or add Flutter to PATH: export PATH=\"\$PATH:/path/to/flutter/bin\""
    echo ""
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

echo "📦 Installing dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully!"
    echo ""
    
    echo "🚀 Available devices:"
    flutter devices
    echo ""
    
    echo "To run the app, use one of these commands:"
    echo "  flutter run                    # Run on default device"
    echo "  flutter run -d chrome          # Run on Chrome"
    echo "  flutter run -d macos           # Run on macOS"
    echo "  flutter run -d <device-id>     # Run on specific device"
    echo ""
    
    read -p "Do you want to run the app now? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo "🚀 Starting app..."
        flutter run
    fi
else
    echo "❌ Failed to install dependencies"
    exit 1
fi
