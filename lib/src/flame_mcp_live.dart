import 'dart:convert';
import 'dart:io';
import 'flame_live_docs.dart';
import 'simple_scheduler.dart';

/// Clean, simple MCP server with live documentation support
class FlameMcpLive {
  final FlameLiveDocs _docs = FlameLiveDocs();
  final SimpleScheduler _scheduler = SimpleScheduler();
  bool _useScheduler = false;

  /// Start the MCP server
  Future<void> start({bool enableScheduler = false}) async {
    _useScheduler = enableScheduler;

    print('🎮 Starting Flame MCP Server with Live Documentation');
    print('📚 Scheduler: ${_useScheduler ? 'Enabled' : 'Disabled'}');

    // Check if we have recent docs, if not sync immediately
    if (!await _docs.isCacheValid()) {
      print('📥 No recent documentation found, syncing now...');
      try {
        await _docs.syncDocs();
      } catch (e) {
        print('⚠️  Initial sync failed: $e');
      }
    }

    // Start scheduler if enabled
    if (_useScheduler) {
      _scheduler.start();
    }

    // Start MCP server
    stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleRequest);
  }

  void _handleRequest(String line) async {
    try {
      final request = jsonDecode(line);
      final response = await _processRequest(request);
      stdout.writeln(jsonEncode(response));
    } catch (e) {
      _sendError(null, -32700, 'Parse error: $e');
    }
  }

  Future<Map<String, dynamic>> _processRequest(
      Map<String, dynamic> request) async {
    final method = request['method'] as String?;
    final id = request['id'];
    final params = request['params'] as Map<String, dynamic>?;

    switch (method) {
      case 'initialize':
        return _handleInitialize(id);

      case 'resources/list':
        return await _handleResourcesList(id);

      case 'resources/read':
        return await _handleResourcesRead(id, params);

      case 'tools/list':
        return _handleToolsList(id);

      case 'tools/call':
        return await _handleToolsCall(id, params);

      default:
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
          'name': 'flame-mcp-live',
          'version': '1.0.0',
          'description':
              'Flame game engine MCP server with live GitHub documentation'
        }
      }
    };
  }

  Future<Map<String, dynamic>> _handleResourcesList(dynamic id) async {
    final resources = await _docs.getResources();
    final metadata = await _docs.getMetadata();

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

    // Add scheduler status if enabled
    if (_useScheduler) {
      resourceList.insert(0, {
        'uri': 'flame://scheduler/status',
        'name': 'Scheduler Status',
        'description': 'Current scheduler status and next sync time',
        'mimeType': 'application/json'
      });
    }

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

    String? content;
    String mimeType = 'text/markdown';

    if (uri == 'flame://metadata') {
      final metadata = await _docs.getMetadata();
      content = jsonEncode(metadata ?? {'error': 'No metadata available'});
      mimeType = 'application/json';
    } else if (uri == 'flame://scheduler/status' && _useScheduler) {
      content = jsonEncode(_scheduler.getStatus());
      mimeType = 'application/json';
    } else {
      content = await _docs.getContent(uri);
    }

    if (content == null) {
      return _createError(id, -32603, 'Resource not found: $uri');
    }

    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'contents': [
          {'uri': uri, 'mimeType': mimeType, 'text': content}
        ]
      }
    };
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
        'name': 'sync_documentation',
        'description': 'Manually sync documentation from GitHub',
        'inputSchema': {'type': 'object', 'properties': {}, 'required': []}
      },
    ];

    if (_useScheduler) {
      tools.add({
        'name': 'scheduler_status',
        'description': 'Get scheduler status and next sync time',
        'inputSchema': {'type': 'object', 'properties': {}, 'required': []}
      });
    }

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

        case 'sync_documentation':
          final success = await _scheduler.syncNow();
          result = success
              ? '✅ Documentation sync completed successfully!'
              : '❌ Documentation sync failed';
          break;

        case 'scheduler_status':
          if (_useScheduler) {
            final status = _scheduler.getStatus();
            result = '📅 Scheduler Status:\n'
                '• Running: ${status['isRunning']}\n'
                '• Next sync: ${status['nextSync']}\n'
                '• Hours until next: ${status['hoursUntilNext']}';
          } else {
            result = '⏸️  Scheduler is disabled';
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

  Map<String, dynamic> _createError(dynamic id, int code, String message) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message}
    };
  }

  void _sendError(dynamic id, int code, String message) {
    stdout.writeln(jsonEncode(_createError(id, code, message)));
  }

  void dispose() {
    _scheduler.stop();
    _docs.dispose();
  }
}
