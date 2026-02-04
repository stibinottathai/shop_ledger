#!/bin/bash

# Build optimized APK with size reduction flags
echo "Building optimized APK..."
echo "This will create separate APKs for different architectures"
echo ""

flutter build apk \
  --release \
  --split-per-abi \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

echo ""
echo "Build complete!"
echo ""
echo "APKs generated:"
ls -lh build/app/outputs/flutter-apk/*.apk

echo ""
echo "Upload these APKs to Play Store:"
echo "- app-armeabi-v7a-release.apk (for 32-bit ARM devices)"
echo "- app-arm64-v8a-release.apk (for 64-bit ARM devices - most modern phones)"
echo "- app-x86_64-release.apk (for x86 devices - emulators/tablets)"
echo ""
echo "Or use app-release.apk (universal) for direct distribution"
