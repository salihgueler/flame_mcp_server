#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:flame_mcp_server/src/flame_live_docs.dart';

void main() async {
  print('🔧 Generating Static MCP API...');

  final docs = FlameLiveDocs();

  // Create output directory
  final apiDir = Directory('api_output');
  if (await apiDir.exists()) {
    await apiDir.delete(recursive: true);
  }
  await apiDir.create(recursive: true);

  try {
    // Get all resources
    final resources = await docs.getResources();
    final metadata = await docs.getMetadata();

    print('📊 Found ${resources.length} documentation resources');

    // Generate MCP server info
    await _generateServerInfo(apiDir);

    // Generate resources list
    await _generateResourcesList(apiDir, resources, metadata);

    // Generate individual resource content
    await _generateResourceContent(apiDir, docs, resources);

    // Generate tools list
    await _generateToolsList(apiDir);

    // Generate search index
    await _generateSearchIndex(apiDir, docs, resources);

    // Generate index.html for GitHub Pages
    await _generateIndexPage(apiDir, resources.length);

    print('✅ Static API generated successfully!');
    print('📁 Output directory: api_output/');
    print(
        '🌐 Will be available at: https://yourusername.github.io/flame_mcp_server/');
  } catch (e) {
    print('❌ Error generating API: $e');
    exit(1);
  } finally {
    docs.dispose();
  }
}

Future<void> _generateServerInfo(Directory apiDir) async {
  final serverInfo = {
    'protocolVersion': '2024-11-05',
    'capabilities': {
      'resources': {'listChanged': false},
      'tools': {'listChanged': false},
    },
    'serverInfo': {
      'name': 'flame-mcp-static',
      'version': '1.0.0',
      'description':
          'Static Flame game engine MCP server with GitHub documentation'
    }
  };

  await File('${apiDir.path}/server-info.json')
      .writeAsString(jsonEncode(serverInfo));
}

Future<void> _generateResourcesList(Directory apiDir, List<String> resources,
    Map<String, dynamic>? metadata) async {
  final resourceList = resources.map((uri) {
    final name = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
    return {
      'uri': uri,
      'name': 'Flame: $name',
      'description': 'Live Flame engine documentation: $name',
      'mimeType': 'text/markdown'
    };
  }).toList();

  // Add metadata resource if available
  if (metadata != null) {
    resourceList.insert(0, {
      'uri': 'flame://metadata',
      'name': 'Documentation Metadata',
      'description': 'Information about documentation sync',
      'mimeType': 'application/json'
    });
  }

  await File('${apiDir.path}/resources.json')
      .writeAsString(jsonEncode({'resources': resourceList}));
}

Future<void> _generateResourceContent(
    Directory apiDir, FlameLiveDocs docs, List<String> resources) async {
  final resourcesDir = Directory('${apiDir.path}/resources');
  await resourcesDir.create();

  for (final uri in resources) {
    final content = await docs.getContent(uri);
    if (content != null) {
      final filename = uri
          .replaceFirst('flame://', '')
          .replaceAll('/', '_')
          .replaceAll(' ', '_');
      final resourceData = {
        'uri': uri,
        'mimeType': 'text/markdown',
        'text': content
      };

      await File('${resourcesDir.path}/$filename.json')
          .writeAsString(jsonEncode(resourceData));
    }
  }

  // Add metadata resource
  final metadata = await docs.getMetadata();
  if (metadata != null) {
    await File('${resourcesDir.path}/metadata.json').writeAsString(jsonEncode({
      'uri': 'flame://metadata',
      'mimeType': 'application/json',
      'text': jsonEncode(metadata)
    }));
  }
}

Future<void> _generateToolsList(Directory apiDir) async {
  final tools = [
    {
      'name': 'search_documentation',
      'description': 'Search through Flame documentation',
      'inputSchema': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string', 'description': 'Search query'}
        },
        'required': ['query']
      }
    }
  ];

  await File('${apiDir.path}/tools.json')
      .writeAsString(jsonEncode({'tools': tools}));
}

Future<void> _generateSearchIndex(
    Directory apiDir, FlameLiveDocs docs, List<String> resources) async {
  final searchIndex = <Map<String, dynamic>>[];

  for (final uri in resources) {
    final content = await docs.getContent(uri);
    if (content != null) {
      final title = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');

      // Create searchable entries
      final lines = content.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty && !line.startsWith('#')) {
          searchIndex.add({
            'uri': uri,
            'title': title,
            'content': line,
            'lineNumber': i + 1
          });
        }
      }
    }
  }

  await File('${apiDir.path}/search-index.json')
      .writeAsString(jsonEncode({'index': searchIndex}));
}

Future<void> _generateIndexPage(Directory apiDir, int resourceCount) async {
  final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flame MCP Server - Static API</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; margin-bottom: 40px; }
        .stats { background: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .config { background: #f0f8ff; padding: 20px; border-radius: 8px; margin: 20px 0; }
        pre { background: #f5f5f5; padding: 15px; border-radius: 4px; overflow-x: auto; }
        .endpoint { margin: 10px 0; }
        .endpoint code { background: #e8e8e8; padding: 2px 6px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎮 Flame MCP Server</h1>
        <p>Static API for Flame Game Engine Documentation</p>
    </div>
    
    <div class="stats">
        <h2>📊 Statistics</h2>
        <ul>
            <li><strong>Documentation Resources:</strong> $resourceCount</li>
            <li><strong>Last Updated:</strong> ${DateTime.now().toIso8601String()}</li>
            <li><strong>Source:</strong> flame-engine/flame GitHub repository</li>
        </ul>
    </div>
    
    <div class="config">
        <h2>🔧 MCP Configuration</h2>
        <p>Add this to your Claude Desktop config:</p>
        <pre>{
  "mcpServers": {
    "flame-docs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-fetch", "https://yourusername.github.io/flame_mcp_server/"]
    }
  }
}</pre>
    </div>
    
    <div>
        <h2>🔗 API Endpoints</h2>
        <div class="endpoint">
            <strong>Server Info:</strong> <code>GET /server-info.json</code>
        </div>
        <div class="endpoint">
            <strong>Resources List:</strong> <code>GET /resources.json</code>
        </div>
        <div class="endpoint">
            <strong>Tools List:</strong> <code>GET /tools.json</code>
        </div>
        <div class="endpoint">
            <strong>Search Index:</strong> <code>GET /search-index.json</code>
        </div>
        <div class="endpoint">
            <strong>Resource Content:</strong> <code>GET /resources/{resource-name}.json</code>
        </div>
    </div>
    
    <div>
        <h2>📚 Available Resources</h2>
        <p>This API provides access to $resourceCount Flame engine documentation resources, automatically synced from the official GitHub repository.</p>
    </div>
</body>
</html>
''';

  await File('${apiDir.path}/index.html').writeAsString(html);
}
