# Flame MCP Server

A clean, robust Model Context Protocol (MCP) server providing live documentation for the Flame game engine in Flutter/Dart.

## ✨ Features

- **Live Documentation**: Fetches latest docs directly from GitHub
- **Smart Caching**: Only syncs if cache is older than 24 hours  
- **Nightly Scheduler**: Optional automatic sync at 2 AM
- **Search**: Search through all documentation
- **Manual Sync**: Force sync when needed
- **Fallback**: Graceful handling of network issues

## 🚀 Quick Start

### 1. Build
```bash
./build_clean.sh
```

### 2. Start Live Server
```bash
# Basic live server (auto-sync if cache is old)
./build/flame_mcp_live

# With nightly scheduler at 2 AM
./build/flame_mcp_live --scheduler
```

### 3. Manual Sync
```bash
./build/flame_sync
```

## 📋 Available Tools

When using the live server, you get these MCP tools:

- **search_documentation**: Search through all Flame docs
- **sync_documentation**: Manually trigger a sync
- **scheduler_status**: Check scheduler status (if enabled)

## 🔧 How It Works

### Smart Caching
- Checks if cached docs are less than 24 hours old
- If cache is stale or missing, syncs automatically
- Stores 80+ documentation files locally

### Nightly Scheduler  
- Runs at 2 AM daily (when enabled with `--scheduler`)
- Handles failures gracefully
- Provides status via MCP tools

### GitHub Integration
- Fetches from `flame-engine/flame` repository
- Downloads all `.md` files from `/doc` directory
- Preserves directory structure
- Creates metadata with sync timestamps

## 📁 File Structure

```
flame_docs_cache/           # Cached documentation
├── metadata.json          # Sync information
├── getting_started.md     # Core docs
├── components/            # Component docs
├── rendering/             # Rendering docs
└── ...                    # All other docs
```

## 🛠️ Configuration

### Environment Variables
- `GITHUB_TOKEN`: Optional, for higher API rate limits

### Cache Location
- Default: `./flame_docs_cache`
- Automatically created and managed

## 📊 MCP Resources

The server provides these resources:

- `flame://getting_started` - Getting started guide
- `flame://components/component_system` - Component system docs
- `flame://rendering/rendering` - Rendering documentation
- `flame://metadata` - Sync metadata (JSON)
- `flame://scheduler/status` - Scheduler status (if enabled)

## 🔍 Example Usage

### With Claude Desktop
Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "flame-live": {
      "command": "/path/to/build/flame_mcp_live",
      "args": ["--scheduler"]
    }
  }
}
```

### Manual Testing
```bash
# Sync documentation
./build/flame_sync

# Start server with scheduler
./build/flame_mcp_live --scheduler

# Check what was synced
find flame_docs_cache -name "*.md" | wc -l
```

## 🎯 Benefits

1. **Simple**: Just 3 core files, easy to understand
2. **Robust**: Handles failures gracefully
3. **Efficient**: Smart caching, only syncs when needed
4. **Flexible**: Works with or without scheduler
5. **Clean**: No complex dependencies or configurations

## 🔄 Sync Process

1. **Check Cache**: Is it less than 24 hours old?
2. **Fetch Structure**: Get directory tree from GitHub API
3. **Download Files**: Fetch all `.md` files
4. **Create Metadata**: Store sync timestamp and info
5. **Serve Content**: Provide via MCP protocol

## 📈 Statistics

- **84 documentation files** synced from GitHub
- **Sub-second startup** with valid cache
- **2 AM daily sync** (optional)
- **3 MCP tools** for interaction
- **Zero configuration** required

## 📂 Project Structure

```
flame_mcp_server/
├── bin/
│   ├── flame_mcp_live.dart       # Live MCP server
│   └── flame_sync.dart           # Manual sync utility
├── lib/src/
│   ├── flame_live_docs.dart      # GitHub doc fetcher
│   ├── simple_scheduler.dart     # Nightly scheduler
│   └── flame_mcp_live.dart       # Live MCP server implementation
├── build_clean.sh                # Build script
└── README.md                     # This file
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add your improvements
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Flame Engine Documentation](https://docs.flame-engine.org/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language](https://dart.dev/)
