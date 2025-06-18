#!/bin/bash

echo "🔨 Building Flame MCP Server"
echo "============================"

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Create build directory
mkdir -p build

echo "🏗️  Building executables..."

# Build live MCP server
echo "   • Building live MCP server..."
dart compile exe bin/flame_mcp_live.dart -o build/flame_mcp_live

# Build sync utility
echo "   • Building sync utility..."
dart compile exe bin/flame_sync.dart -o build/flame_sync

# Make executables executable
chmod +x build/*

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📋 Available executables:"
echo "   • build/flame_mcp_live    - Live documentation server"
echo "   • build/flame_sync        - Manual documentation sync"
echo ""
echo "🚀 Usage examples:"
echo "   # Start live server (manual sync only)"
echo "   ./build/flame_mcp_live"
echo ""
echo "   # Start live server with nightly scheduler"
echo "   ./build/flame_mcp_live --scheduler"
echo ""
echo "   # Manual sync"
echo "   ./build/flame_sync"
echo ""
echo "🎯 The live server will:"
echo "   • Automatically sync docs if cache is older than 24 hours"
echo "   • Provide live GitHub documentation via MCP"
echo "   • Optionally run nightly sync at 2 AM (with --scheduler)"
echo "   • Include search and manual sync tools"
echo ""
