#!/bin/bash

# Setup script for Singalong Player Apple project
# This script prepares the Xcode project structure

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="SingalongPlayer"
BUNDLE_ID="com.nicenature.singalong-player"
DEPLOYMENT_TARGET="16.0"

echo "📱 Setting up $PROJECT_NAME Xcode project..."

# Step 1: Ensure directory structure
echo "✓ Creating directory structure..."
mkdir -p "$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
mkdir -p "$PROJECT_DIR/$PROJECT_NAME.xcworkspace"
mkdir -p "$PROJECT_DIR/$PROJECT_NAME"/{App,Models,Services,Views,Assets.xcassets}

# Step 2: Copy sources if they exist in Sources/ folder
if [ -d "$PROJECT_DIR/Sources" ]; then
    echo "✓ Copying source files..."
    cp -r "$PROJECT_DIR/Sources"/* "$PROJECT_DIR/$PROJECT_NAME/" 2>/dev/null || true
fi

# Step 3: Ensure Info.plist exists
if [ ! -f "$PROJECT_DIR/$PROJECT_NAME/Info.plist" ]; then
    echo "✓ Creating Info.plist..."
    cat > "$PROJECT_DIR/$PROJECT_NAME/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<true/>
	</dict>
	<key>NSBonjourServices</key>
	<array>
		<string>_singalong-node._tcp</string>
	</array>
	<key>NSLocalNetworkUsageDescription</key>
	<string>Singalong Player needs to discover karaoke nodes on your local network</string>
	<key>NSBonjourUsageDescription</key>
	<string>Singalong Player discovers karaoke nodes using Bonjour (mDNS)</string>
</dict>
</plist>
EOF
fi

# Step 4: Create empty Assets.xcassets structure
if [ ! -f "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/Contents.json" ]; then
    echo "✓ Creating Assets.xcassets..."
    cat > "$PROJECT_DIR/$PROJECT_NAME/Assets.xcassets/Contents.json" << 'EOF'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
fi

# Step 5: Verify project structure
echo ""
echo "✅ Project structure ready!"
echo ""
echo "📂 Directory structure:"
tree -L 3 -I 'Preview Assets|.DS_Store' "$PROJECT_DIR" || find "$PROJECT_DIR" -maxdepth 3 -type f -name "*.swift" -o -name "*.plist" -o -name "*.xcconfig"

echo ""
echo "📖 Next steps:"
echo "1. Open in Xcode:"
echo "   open \"$PROJECT_DIR/$PROJECT_NAME.xcworkspace\""
echo ""
echo "2. Or open the project directly:"
echo "   open \"$PROJECT_DIR/$PROJECT_NAME.xcodeproj\""
echo ""
echo "3. Configure in Xcode:"
echo "   - Set Team ID (Signing & Capabilities)"
echo "   - Select deployment target (iOS, macOS, tvOS)"
echo "   - Configure Bundle Identifier: $BUNDLE_ID"
echo "   - Enable capabilities: Local Network, Bonjour"
echo ""
echo "4. Build & Run:"
echo "   Cmd+B to build, Cmd+R to run on simulator/device"
