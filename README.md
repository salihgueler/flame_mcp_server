# Flame MCP Server

A Model Context Protocol (MCP) server that provides on-demand documentation for the Flame game engine. This server fetches documentation from the official Flame GitHub repository and makes it available to AI assistants like Claude Desktop and Amazon Q Developer through the MCP protocol.

## 🎯 What This Does

- **On-Demand Documentation**: Fetches Flame engine documentation from GitHub when requested
- **Local Caching**: Stores documentation locally in `flame_docs_cache/` to avoid repeated API calls
- **MCP Integration**: Provides documentation as MCP resources and search tools
- **Search Capability**: Search through all cached Flame documentation
- **Manual Sync**: Refresh documentation cache when needed

## 📋 Prerequisites

- **Dart SDK**: Version 3.2.0 or higher
- **Internet Connection**: Required for fetching documentation from GitHub
- **MCP Client**: Amazon Q Developer, Claude Desktop, or another MCP-compatible client

## 🚀 Quick Start

### 1. Clone and Build

```bash
# Clone this repository
git clone <repository-url>
cd flame_mcp_server

# Build executables and sync documentation
./build_clean.sh
```

This creates two executables in the `build/` directory:
- `flame_mcp_live` - The MCP server
- `flame_sync` - Manual documentation sync utility

### 2. Test the Installation

```bash
# Verify documentation was downloaded
ls flame_docs_cache/
# Should show: bridge_packages/ flame/ tutorials/ development/ etc.

# Test the MCP server (press Ctrl+C to stop)
./build/flame_mcp_live
```

## 🔧 MCP Client Configuration

### Amazon Q Developer

Add to your MCP configuration:

```json
{
  "mcpServers": {
    "flame-docs": {
      "command": "/absolute/path/to/flame_mcp_server/build/flame_mcp_live"
    }
  }
}
```

### Claude Desktop

1. **Locate your config file:**
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%\\Claude\\claude_desktop_config.json`
   - **Linux**: `~/.config/Claude/claude_desktop_config.json`

2. **Add the server:**

```json
{
  "mcpServers": {
    "flame-docs": {
      "command": "/absolute/path/to/flame_mcp_server/build/flame_mcp_live"
    }
  }
}
```

3. **Restart your MCP client** to load the Flame documentation.

**Important**: Use the absolute path to your `flame_mcp_live` executable.

## ⚙️ Configuration

### GitHub Token (Recommended)

Without a GitHub token, you're limited to 60 API requests per hour. With a token, you get 5,000 requests per hour.

1. **Create a GitHub Personal Access Token:**
   - Go to [GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)](https://github.com/settings/tokens)
   - Click "Generate new token (classic)"
   - Name: "Flame MCP Server"
   - Scopes: Select **`public_repo`** (for accessing public repositories)
   - Generate and copy the token

2. **Set the environment variable:**

   **macOS/Linux:**
   ```bash
   export GITHUB_TOKEN=your_token_here
   # Add to ~/.bashrc or ~/.zshrc for persistence
   ```

   **Windows:**
   ```cmd
   setx GITHUB_TOKEN "your_token_here"
   ```

3. **Verify it's working:**
   ```bash
   ./build/flame_sync
   # Should show: "🔑 Using GitHub personal access token"
   ```

## 🛠️ Available MCP Tools

Once connected to your MCP client, you'll have access to:

### 1. `search_documentation`
Search through all Flame documentation.

**Example usage:**
> "Search the Flame documentation for collision detection examples"

### 2. `sync_documentation`
Manually refresh the documentation cache from GitHub.

**Example usage:**
> "Sync the Flame documentation to get the latest updates"

## 📊 MCP Resources

The server provides 80+ documentation resources accessible via MCP, including:

- `flame://index` - Main documentation index
- `flame://flame/components/component_system` - Component system
- `flame://flame/rendering/rendering` - Rendering and graphics
- `flame://flame/inputs/inputs` - Input handling
- `flame://flame/collision_detection/collision_detection` - Collision systems
- `flame://flame/effects/effects` - Effects and animations
- `flame://tutorials/platformer/platformer` - Platformer tutorial
- `flame://bridge_packages/flame_audio/audio` - Audio integration
- And many more...

## 🔍 How It Works

### Documentation Sync Process

1. **GitHub API**: Fetches directory structure from `flame-engine/flame/doc`
2. **Download**: Downloads all `.md` files preserving directory structure
3. **Cache**: Stores files locally in `flame_docs_cache/`
4. **Serve**: Makes documentation available via MCP protocol

### MCP Integration

- **Resources**: Each documentation file becomes an MCP resource with URI `flame://path/to/file`
- **Tools**: Provides search and sync capabilities
- **Protocol**: Communicates via JSON-RPC over stdin/stdout

## 📁 Project Structure

```
flame_mcp_server/
├── bin/
│   ├── flame_mcp_live.dart    # Main MCP server executable
│   └── flame_sync.dart        # Manual sync utility
├── lib/src/
│   ├── flame_live_docs.dart   # GitHub documentation fetcher
│   └── flame_mcp_live.dart    # MCP server implementation
├── build_clean.sh             # Build and setup script
├── pubspec.yaml               # Dart dependencies
├── .gitignore                 # Git ignore rules
└── README.md                  # This file

# Generated at runtime:
├── flame_docs_cache/          # Downloaded documentation
├── build/                     # Compiled executables
│   ├── flame_mcp_live         # MCP server binary
│   └── flame_sync             # Sync utility binary
└── .dart_tool/               # Dart build artifacts
```

## 🐛 Troubleshooting

### Build Issues

**Problem**: `dart pub get` fails  
**Solution**: Ensure Dart SDK 3.2.0+ is installed

**Problem**: Permission denied on executables  
**Solution**: 
```bash
chmod +x build/flame_mcp_live build/flame_sync
```

### Sync Issues

**Problem**: GitHub rate limit exceeded  
**Solution**: Set up a `GITHUB_TOKEN` environment variable

**Problem**: Network timeout during sync  
**Solution**: Run `./build/flame_sync` to retry manually

### MCP Integration Issues

**Problem**: MCP client doesn't see the server  
**Solution**: 
1. Use absolute path in configuration
2. Restart MCP client after config changes
3. Verify executable exists and runs

**Problem**: Server starts but no documentation appears  
**Solution**: 
1. Run `./build/flame_sync` to sync documentation
2. Check that `flame_docs_cache/` contains `.md` files

## 📈 Performance Stats

- **Documentation Files**: ~80 Markdown files
- **Sync Time**: 30-60 seconds (network dependent)
- **Cache Size**: ~2-3 MB
- **Memory Usage**: <50 MB when running
- **Startup Time**: <1 second

## 🔒 Security Notes

- Never commit GitHub tokens to version control
- Use environment variables for sensitive configuration
- The server only reads public documentation from GitHub
- No data is sent to external services except GitHub API

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test with `./build_clean.sh`
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Links

- [Flame Engine Documentation](https://docs.flame-engine.org/)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Claude Desktop](https://claude.ai/desktop)
- [Amazon Q Developer](https://aws.amazon.com/q/developer/)
- [Dart Language](https://dart.dev/)

## 💡 Usage Tips

1. **Set GitHub Token**: Avoid rate limiting with a personal access token
2. **Regular Syncing**: Run `./build/flame_sync` after major Flame releases
3. **Effective Searching**: Use specific terms when searching documentation
4. **Resource URIs**: Access specific docs directly via `flame://path/to/file` URIs

---

**Ready to get started?** Run `./build_clean.sh` and add the server to your MCP client!
