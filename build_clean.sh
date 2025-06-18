#!/bin/bash

echo "🔨 Building Flame MCP Server (Local)"
echo "===================================="

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Create build directory
mkdir -p build

echo "🏗️  Building MCP server..."
dart compile exe bin/flame_mcp_live.dart -o build/flame_mcp_live

if [ $? -ne 0 ]; then
    echo "❌ Failed to build MCP server"
    exit 1
fi

# Make executable
chmod +x build/flame_mcp_live

echo ""
echo "📚 Fetching Flame documentation..."
echo "   • This may take 30-60 seconds depending on network speed"

# Use the standalone sync script to fetch documentation
dart run bin/flame_sync_standalone.dart

if [ $? -ne 0 ]; then
    echo "⚠️  Documentation sync failed, but build completed"
    echo "   You can manually sync later with: dart run bin/flame_sync_standalone.dart"
else
    echo "✅ Documentation cached successfully!"
fi

echo ""
echo "✅ Build completed successfully!"
echo ""
echo "📋 Available:"
echo "   • build/flame_mcp_live           - MCP server (search only)"
echo "   • bin/flame_sync_standalone.dart - Manual documentation sync"
echo ""
echo "📁 Documentation cache:"
echo "   • flame_docs_cache/              - Local Flame documentation"
echo ""
echo "🚀 Usage:"
echo "   # Start MCP server"
echo "   ./build/flame_mcp_live"
echo ""
echo "   # Manual sync (refresh docs)"
echo "   dart run bin/flame_sync_standalone.dart"
echo ""