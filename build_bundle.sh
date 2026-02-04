#!/bin/bash

# Script to build optimized App Bundle for Play Store upload
# This automatically handles the ABI splits conflict

echo "🚀 Building optimized App Bundle for Play Store..."
echo ""

# Clean build artifacts
echo "📦 Cleaning build artifacts..."
flutter clean

# Build the app bundle
echo "🔨 Building release bundle..."
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📍 App Bundle location:"
    echo "   build/app/outputs/bundle/release/app-release.aab"
    echo ""
    
    # Get file size
    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
        SIZE=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
        echo "📊 Bundle size: $SIZE"
        echo ""
        echo "🎯 Ready for Play Store upload!"
        echo ""
        echo "Next steps:"
        echo "  1. Go to Google Play Console"
        echo "  2. Upload build/app/outputs/bundle/release/app-release.aab"
        echo "  3. Google Play will generate optimized APKs automatically"
    fi
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
