#!/bin/bash

# Homebrew Tap Setup for Singalong
# This script sets up the local Homebrew tap for development

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Singalong Homebrew Tap Setup"
echo "================================"
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✓ Homebrew found: $(brew --version)"
echo ""

# Add local tap (for development)
echo "📝 Setting up local tap..."
if brew tap-new patterueldev/singalong 2>/dev/null || true; then
    echo "✓ Tap created (or already exists)"
else
    echo "✓ Tap already exists"
fi

echo ""
echo "📦 Installing singalong-mdns-bridge..."
if brew install patterueldev/singalong/singalong-mdns-bridge; then
    echo "✓ Installation successful"
else
    echo "⚠ Installation failed or already installed"
fi

echo ""
echo "🚀 Starting service..."
if brew services start singalong-mdns-bridge; then
    echo "✓ Service started"
else
    echo "⚠ Service start failed - check 'brew services list'"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Useful commands:"
echo "  brew services list                              # Check service status"
echo "  brew services restart singalong-mdns-bridge    # Restart service"
echo "  tail -f /usr/local/var/log/singalong-mdns-bridge.log  # View logs"
echo ""
