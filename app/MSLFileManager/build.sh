#!/bin/bash
# Build script for MSLFileManager
# This script helps build the project using Swift Package Manager

set -e

echo "=== MSLFileManager Build Script ==="
echo ""

# Check if we're in the right directory
if [ ! -f "MSLFileManager/MSLFileManagerApp.swift" ]; then
    echo "Error: Please run this script from the app/MSLFileManager directory"
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "Error: Swift is not installed"
    exit 1
fi

echo "Building MSLFileManager..."
swift build

echo ""
echo "Build complete!"
echo ""
echo "To create an Xcode project:"
echo "1. Install xcodegen: brew install xcodegen"
echo "2. Run: xcodegen generate"
echo "3. Open MSLFileManager.xcodeproj"
