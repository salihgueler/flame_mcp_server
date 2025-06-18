#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

/// Simple HTTP server that adapts static JSON files to MCP protocol
/// This works with @modelcontextprotocol/server-fetch
void main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await HttpServer.bind('0.0.0.0', port);
  
  print('🚀 MCP Fetch Adapter running on port $port');
  
  await for (final request in server) {
    await handleRequest(request);
  }
}

Future<void> handleRequest(HttpRequest request) async {
  // Enable CORS
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  
  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }
  
  try {
    if (request.method == 'POST' && request.uri.path == '/') {
      await handleMcpRequest(request);
    } else if (request.method == 'GET') {
      await handleStaticFile(request);
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  } catch (e) {
    print('Error handling request: $e');
    request.response.statusCode = 500;
    request.response.write(jsonEncode({'error': 'Internal server error'}));
    await request.response.close();
  }
}

Future<void> handleMcpRequest(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  final mcpRequest = jsonDecode(body);
  
  final method = mcpRequest['method'] as String?;
  final id = mcpRequest['id'];
  
  Map<String, dynamic> response;
  
  switch (method) {
    case 'initialize':
      response = await handleInitialize(id);
      break;
    case 'resources/list':
      response = await handleResourcesList(id);
      break;
    case 'resources/read':
      response = await handleResourcesRead(id, mcpRequest['params']);
      break;
    case 'tools/list':
      response = await handleToolsList(id);
      break;
    case 'tools/call':
      response = await handleToolsCall(id, mcpRequest['params']);
      break;
    default:
      response = {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': -32601, 'message': 'Method not found: $method'}
      };
  }
  
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(response));
  await request.response.close();
}

Future<void> handleStaticFile(HttpRequest request) async {
  final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
  final file = File('api_output$path');
  
  if (await file.exists()) {
    final content = await file.readAsString();
    
    if (path.endsWith('.json')) {
      request.response.headers.contentType = ContentType.json;
    } else if (path.endsWith('.html')) {
      request.response.headers.contentType = ContentType.html;
    }
    
    request.response.write(content);
  } else {
    request.response.statusCode = 404;
    request.response.write('File not found');
  }
  
  await request.response.close();
}

Future<Map<String, dynamic>> handleInitialize(dynamic id) async {
  final serverInfo = await loadJsonFile('api_output/server-info.json');
  return {
    'jsonrpc': '2.0',
    'id': id,
    'result': serverInfo
  };
}

Future<Map<String, dynamic>> handleResourcesList(dynamic id) async {
  final resources = await loadJsonFile('api_output/resources.json');
  return {
    'jsonrpc': '2.0',
    'id': id,
    'result': resources
  };
}

Future<Map<String, dynamic>> handleResourcesRead(dynamic id, Map<String, dynamic>? params) async {
  final uri = params?['uri'] as String?;
  if (uri == null) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': -32602, 'message': 'Missing uri parameter'}
    };
  }
  
  try {
    final filename = uri.replaceFirst('flame://', '').replaceAll('/', '_').replaceAll(' ', '_');
    final resourceData = await loadJsonFile('api_output/resources/$filename.json');
    
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'contents': [resourceData]
      }
    };
  } catch (e) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': -32603, 'message': 'Resource not found: $uri'}
    };
  }
}

Future<Map<String, dynamic>> handleToolsList(dynamic id) async {
  final tools = await loadJsonFile('api_output/tools.json');
  return {
    'jsonrpc': '2.0',
    'id': id,
    'result': tools
  };
}

Future<Map<String, dynamic>> handleToolsCall(dynamic id, Map<String, dynamic>? params) async {
  final toolName = params?['name'] as String?;
  final arguments = params?['arguments'] as Map<String, dynamic>? ?? {};
  
  if (toolName == 'search_documentation') {
    final query = arguments['query'] as String? ?? '';
    final searchResults = await performSearch(query);
    
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'content': [
          {
            'type': 'text',
            'text': searchResults
          }
        ]
      }
    };
  }
  
  return {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': -32601, 'message': 'Unknown tool: $toolName'}
  };
}

Future<Map<String, dynamic>> loadJsonFile(String path) async {
  final file = File(path);
  final content = await file.readAsString();
  return jsonDecode(content);
}

Future<String> performSearch(String query) async {
  try {
    final searchIndex = await loadJsonFile('api_output/search-index.json');
    final index = searchIndex['index'] as List<dynamic>;
    
    final results = index.where((item) {
      final content = item['content'] as String;
      return content.toLowerCase().contains(query.toLowerCase());
    }).take(5).toList();
    
    if (results.isEmpty) {
      return 'No results found for "$query"';
    }
    
    final buffer = StringBuffer();
    buffer.writeln('Found ${results.length} results for "$query":\n');
    
    for (final result in results) {
      buffer.writeln('📄 **${result['title']}** (${result['uri']})');
      buffer.writeln('   ${result['content']}\n');
    }
    
    return buffer.toString();
  } catch (e) {
    return 'Search failed: $e';
  }
}
