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

# Build static API generator
echo "   • Building static API generator..."
dart compile exe bin/generate_static_api.dart -o build/generate_static_api

# Build MCP fetch adapter (for local testing)
echo "   • Building MCP fetch adapter..."
dart compile exe bin/mcp_fetch_adapter.dart -o build/mcp_fetch_adapter

# Make executables executable
chmod +x build/*

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📋 Available executables:"
echo "   • build/flame_mcp_live       - Live documentation server"
echo "   • build/flame_sync           - Manual documentation sync"
echo "   • build/generate_static_api  - Static API generator"
echo "   • build/mcp_fetch_adapter    - HTTP adapter for testing"
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
echo "   # Generate static API"
echo "   ./build/generate_static_api"
echo ""
echo "   # Test HTTP adapter locally"
echo "   ./build/mcp_fetch_adapter"
echo ""
echo "🎯 For GitHub Pages deployment:"
echo "   • Push to main branch to trigger GitHub Actions"
echo "   • Actions will sync docs and deploy to GitHub Pages"
echo "   • Users can then use the hosted URL in their MCP config"
echo ""
