import 'dart:convert';
import 'dart:io';
import 'flame_live_docs.dart';

/// Local MCP server for Flame documentation
class FlameMcpLive {
  final FlameLiveDocs _docs = FlameLiveDocs();

  /// Start the MCP server
  Future<void> start() async {
    // MCP servers must not print to stdout - only JSON-RPC messages
    // Use stderr for logging instead
    stderr.writeln('🎮 Starting Flame MCP Server (Local Mode)');

    // Initialize documentation system
    await _docs.initialize();

    // Start MCP server
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleRequest);
  }

  void _handleRequest(String line) async {
    dynamic requestId;
    try {
      // First try to parse the JSON
      final request = jsonDecode(line);

      // Extract the ID for error handling
      requestId = request['id'];

      // Validate required fields
      if (request['jsonrpc'] != '2.0') {
        _sendError(requestId, -32600, 'Invalid JSON-RPC version');
        return;
      }

      if (request['method'] == null) {
        _sendError(requestId, -32600, 'Missing method field');
        return;
      }

      // Check if this is a notification (no id field)
      final isNotification = requestId == null;

      final response = await _processRequest(request);

      // Only send response for requests, not notifications
      if (!isNotification && response.isNotEmpty) {
        final jsonResponse = jsonEncode(response);
        stdout.writeln(jsonResponse);
      }
    } catch (e) {
      // Use the extracted ID if available, otherwise null
      _sendError(requestId, -32700, 'Parse error: $e');
    }
  }

  Future<Map<String, dynamic>> _processRequest(
      Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>?;

    // Check if this is a notification (no id field)
    final isNotification = id == null;

    // Validate that we have a method
    if (method == null || method.isEmpty) {
      if (isNotification) {
        // For notifications, we can't send an error response
        stderr.writeln('Warning: Received notification without method');
        return {};
      }
      return _createError(id, -32600, 'Missing or empty method field');
    }

    switch (method) {
      case 'initialize':
        if (isNotification) {
          stderr.writeln(
              'Warning: Initialize should be a request, not notification');
          return {};
        }
        return _handleInitialize(id);

      case 'notifications/initialized':
        // Handle initialized notification - no response needed
        stderr.writeln('Received initialized notification');
        return {};

      case 'resources/list':
        if (isNotification) {
          stderr.writeln(
              'Warning: resources/list should be a request, not notification');
          return {};
        }
        return await _handleResourcesList(id);

      case 'resources/read':
        if (isNotification) {
          stderr.writeln(
              'Warning: resources/read should be a request, not notification');
          return {};
        }
        return await _handleResourcesRead(id, params);

      case 'tools/list':
        if (isNotification) {
          stderr.writeln(
              'Warning: tools/list should be a request, not notification');
          return {};
        }
        return _handleToolsList(id);

      case 'tools/call':
        if (isNotification) {
          stderr.writeln(
              'Warning: tools/call should be a request, not notification');
          return {};
        }
        return await _handleToolsCall(id, params);

      case 'ping':
        if (isNotification) {
          stderr.writeln('Warning: ping should be a request, not notification');
          return {};
        }
        return _handlePing(id);

      default:
        if (isNotification) {
          stderr.writeln('Warning: Unknown notification method: $method');
          return {};
        }
        return _createError(id, -32601, 'Method not found: $method');
    }
  }

  Map<String, dynamic> _handleInitialize(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'protocolVersion': '2024-11-05',
        'capabilities': {
          'resources': {'listChanged': true},
          'tools': {'listChanged': true},
        },
        'serverInfo': {
          'name': 'flame-mcp-local',
          'version': '1.0.0',
          'description':
              'Local Flame game engine MCP server with on-demand GitHub documentation'
        }
      }
    };
  }

  Future<Map<String, dynamic>> _handleResourcesList(dynamic id) async {
    final resources = await _docs.getResources();

    final resourceList = resources.map((uri) {
      final name = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
      return {
        'uri': uri,
        'name': 'Flame: $name',
        'description': 'Flame engine documentation: $name',
        'mimeType': 'text/markdown'
      };
    }).toList();

    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'resources': resourceList}
    };
  }

  Future<Map<String, dynamic>> _handleResourcesRead(
      dynamic id, Map<String, dynamic>? params) async {
    final uri = params?['uri'] as String?;
    if (uri == null) {
      return _createError(id, -32602, 'Missing uri parameter');
    }

    final content = await _docs.getContent(uri);
    if (content == null) {
      return _createError(id, -32603, 'Resource not found: $uri');
    }

    // Additional content sanitization for JSON safety
    final safeContent = _safeJsonContent(content);

    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'contents': [
          {'uri': uri, 'mimeType': 'text/markdown', 'text': safeContent}
        ]
      }
    };
  }

  /// Safely encode content for JSON transmission
  String _safeJsonContent(String content) {
    // Additional safety for JSON encoding
    return content
        .replaceAll('\r\n', '\n') // Normalize line endings
        .replaceAll('\r', '\n') // Handle old Mac line endings
        .replaceAll('\t', '    ') // Replace tabs with spaces
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'),
            ''); // Remove control chars
  }

  Map<String, dynamic> _handleToolsList(dynamic id) {
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
      },
      {
        'name': 'tutorial',
        'description':
            'Get complete Flame tutorials with step-by-step instructions for building games (space shooter, platformer, klondike). Use this for learning how to build specific games.',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'topic': {
              'type': 'string',
              'description':
                  'Tutorial topic: "space shooter" for complete space shooter game tutorial, "platformer" for platformer game tutorial, "klondike" for card game tutorial, or "list" to see all available tutorials'
            }
          },
          'required': ['topic']
        }
      },
    ];

    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'tools': tools}
    };
  }

  Future<Map<String, dynamic>> _handleToolsCall(
      dynamic id, Map<String, dynamic>? params) async {
    final toolName = params?['name'] as String?;
    final arguments = params?['arguments'] as Map<String, dynamic>? ?? {};

    if (toolName == null) {
      return _createError(id, -32602, 'Missing tool name');
    }

    try {
      String result;

      switch (toolName) {
        case 'search_documentation':
          final query = arguments['query'] as String? ?? '';
          if (query.isEmpty) {
            result = '❌ Search query cannot be empty';
          } else {
            final results = await _docs.search(query);
            if (results.isEmpty) {
              result = 'No results found for "$query"';
            } else {
              final buffer = StringBuffer();
              buffer.writeln('Found ${results.length} results for "$query":\n');
              for (final result in results.take(5)) {
                buffer.writeln('📄 **${result['title']}** (${result['uri']})');
                buffer.writeln('   ${result['snippet']}\n');
              }
              result = buffer.toString();
            }
          }
          break;

        case 'tutorial':
          final topic = arguments['topic'] as String? ?? '';
          if (topic.isEmpty) {
            result = '❌ Tutorial topic cannot be empty';
          } else {
            result = await _handleTutorialRequest(topic);
          }
          break;

        default:
          result = 'Unknown tool: $toolName';
      }

      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': {
          'content': [
            {'type': 'text', 'text': result}
          ]
        }
      };
    } catch (e) {
      return _createError(id, -32603, 'Tool execution failed: $e');
    }
  }

  /// Handle tutorial requests
  Future<String> _handleTutorialRequest(String topic) async {
    final lowerTopic = topic.toLowerCase();

    // Handle "list" request to show all available tutorials
    if (lowerTopic == 'list') {
      return await _listAllTutorials();
    }

    // For specific tutorial requests, provide comprehensive step-by-step content
    if (lowerTopic.contains('space shooter') ||
        lowerTopic.contains('spaceshooter')) {
      return await _getCompleteTutorial('space_shooter');
    } else if (lowerTopic.contains('platformer')) {
      return await _getCompleteTutorial('platformer');
    } else if (lowerTopic.contains('klondike')) {
      return await _getCompleteTutorial('klondike');
    }

    // Fallback to search for tutorials matching the topic
    final tutorialResults = await _docs.searchTutorials(lowerTopic);

    if (tutorialResults.isEmpty) {
      return 'No tutorials found for "$topic". Try "list" to see all available tutorials.';
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '🎓 Found ${tutorialResults.length} tutorial(s) for "$topic":\n');

    for (final tutorial in tutorialResults) {
      buffer.writeln('📚 **${tutorial['title']}** (${tutorial['uri']})');
      buffer.writeln('   ${tutorial['snippet']}\n');
    }

    return buffer.toString();
  }

  /// Get complete tutorial with all steps
  Future<String> _getCompleteTutorial(String tutorialName) async {
    final resources = await _docs.getResources();
    final tutorialResources = resources
        .where((uri) => uri.contains('tutorials/$tutorialName/'))
        .toList();

    if (tutorialResources.isEmpty) {
      return 'No tutorial found for "$tutorialName".';
    }

    // Sort to get main tutorial first, then steps in order
    tutorialResources.sort((a, b) {
      final aName = a.split('/').last;
      final bName = b.split('/').last;

      // Main tutorial file comes first
      if (aName == tutorialName) return -1;
      if (bName == tutorialName) return 1;

      // Sort steps numerically
      final aStep = _extractStepNumber(aName);
      final bStep = _extractStepNumber(bName);
      return aStep.compareTo(bStep);
    });

    final buffer = StringBuffer();
    buffer.writeln(
        '🎮 ${_formatTopicName(tutorialName)} Tutorial - Complete Guide\n');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (int i = 0; i < tutorialResources.length; i++) {
      final uri = tutorialResources[i];
      final content = await _docs.getContent(uri);

      if (content != null) {
        final fileName = uri.split('/').last;
        final isMainTutorial = fileName == tutorialName;
        final stepNumber = isMainTutorial ? 0 : _extractStepNumber(fileName);

        if (isMainTutorial) {
          buffer.writeln('📖 **Overview**\n');
        } else {
          buffer.writeln('📝 **Step $stepNumber**\n');
        }

        // Get first few paragraphs of content
        final lines = content.split('\n');
        final contentLines = lines
            .where((line) =>
                line.trim().isNotEmpty &&
                !line.startsWith('```') &&
                !line.startsWith('![') &&
                !line.startsWith('{'))
            .take(10)
            .toList();

        for (final line in contentLines) {
          if (line.startsWith('#')) {
            buffer.writeln('**${line.replaceAll('#', '').trim()}**');
          } else {
            buffer.writeln(line);
          }
        }

        buffer.writeln('\n📄 Full content: $uri\n');
        buffer.writeln('-' * 30);
        buffer.writeln();
      }
    }

    buffer.writeln('💡 **Next Steps:**');
    buffer.writeln('• Use the URIs above to get full content for each step');
    buffer.writeln('• Follow the steps in order for best results');
    buffer.writeln('• Each step builds upon the previous one');

    return buffer.toString();
  }

  /// Extract step number from filename
  int _extractStepNumber(String filename) {
    final match = RegExp(r'step_?(\d+)').firstMatch(filename);
    return match != null ? int.parse(match.group(1)!) : 999;
  }

  /// List all available tutorials
  Future<String> _listAllTutorials() async {
    final resources = await _docs.getResources();
    final tutorials =
        resources.where((uri) => uri.contains('tutorials/')).toList();

    if (tutorials.isEmpty) {
      return 'No tutorials found in the documentation cache.';
    }

    final buffer = StringBuffer();
    buffer.writeln('🎓 Available Flame Tutorials:\n');

    // Group tutorials by main topic
    final tutorialGroups = <String, List<String>>{};

    for (final uri in tutorials) {
      // Parse URI like "flame://tutorials/space_shooter/step_1"
      final parts = uri.replaceFirst('flame://', '').split('/');
      if (parts.length >= 2 && parts[0] == 'tutorials') {
        final mainTopic = parts.length >= 3 ? parts[1] : 'general';
        tutorialGroups.putIfAbsent(mainTopic, () => []).add(uri);
      }
    }

    for (final entry in tutorialGroups.entries) {
      final topic = entry.key;
      final uris = entry.value;

      buffer.writeln('📖 **${_formatTopicName(topic)}**');

      // Sort URIs to show main tutorial first, then steps
      uris.sort((a, b) {
        final aName = a.split('/').last;
        final bName = b.split('/').last;

        // Main tutorial files (same name as directory) come first
        if (aName == topic) return -1;
        if (bName == topic) return 1;

        // Then sort steps numerically
        return aName.compareTo(bName);
      });

      for (final uri in uris) {
        final title = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
        buffer.writeln('   • $title');
      }
      buffer.writeln();
    }

    buffer
        .writeln('💡 Use `tutorial <topic>` to get specific tutorial content.');
    buffer.writeln(
        '   Example: `tutorial space shooter` or `tutorial platformer`');

    return buffer.toString();
  }

  /// Format topic name for display
  String _formatTopicName(String topic) {
    return topic
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Map<String, dynamic> _handlePing(dynamic id) {
    return {'jsonrpc': '2.0', 'id': id, 'result': {}};
  }

  Map<String, dynamic> _createError(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message}
    };
  }

  void _sendError(dynamic id, int code, String message) {
    try {
      stdout.writeln(jsonEncode(_createError(id, code, message)));
    } catch (e) {
      // Fallback for encoding errors
      stdout.writeln(
          '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"Internal JSON encoding error"}}');
    }
  }

  void dispose() {
    _docs.dispose();
  }
}
