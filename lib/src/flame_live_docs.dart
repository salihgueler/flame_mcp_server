import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Simple, robust live documentation fetcher for Flame engine
class FlameLiveDocs {
  static const String repoApiUrl = 'https://api.github.com/repos/flame-engine/flame/contents/doc';
  static const String rawBaseUrl = 'https://raw.githubusercontent.com/flame-engine/flame/main/doc';
  static const String cacheDir = './flame_docs_cache';
  
  final http.Client _client = http.Client();
  
  /// Sync documentation from GitHub
  Future<void> syncDocs() async {
    print('🔄 Syncing Flame documentation from GitHub...');
    
    try {
      // Create cache directory
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      await dir.create(recursive: true);
      
      // Fetch all markdown files
      await _fetchDirectory('');
      
      // Create metadata
      await _createMetadata();
      
      print('✅ Documentation sync completed!');
    } catch (e) {
      print('❌ Sync failed: $e');
      rethrow;
    }
  }
  
  /// Get all available documentation resources
  Future<List<String>> getResources() async {
    final resources = <String>[];
    final dir = Directory(cacheDir);
    
    if (!await dir.exists()) {
      return resources;
    }
    
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        final relativePath = path.relative(entity.path, from: cacheDir);
        final uri = 'flame://${relativePath.replaceAll(path.separator, '/').replaceAll('.md', '')}';
        resources.add(uri);
      }
    }
    
    return resources;
  }
  
  /// Get content for a specific resource
  Future<String?> getContent(String uri) async {
    final docPath = uri.replaceFirst('flame://', '');
    final filePath = path.join(cacheDir, '$docPath.md');
    final file = File(filePath);
    
    if (await file.exists()) {
      return await file.readAsString();
    }
    
    return null;
  }
  
  /// Get sync metadata
  Future<Map<String, dynamic>?> getMetadata() async {
    final file = File(path.join(cacheDir, 'metadata.json'));
    if (await file.exists()) {
      final content = await file.readAsString();
      return jsonDecode(content);
    }
    return null;
  }
  
  /// Check if docs are cached and recent (less than 24 hours old)
  Future<bool> isCacheValid() async {
    final metadata = await getMetadata();
    if (metadata == null) return false;
    
    final lastSync = DateTime.tryParse(metadata['lastSync'] ?? '');
    if (lastSync == null) return false;
    
    final age = DateTime.now().difference(lastSync);
    return age.inHours < 24;
  }
  
  /// Search through documentation
  Future<List<Map<String, dynamic>>> search(String query) async {
    final results = <Map<String, dynamic>>[];
    final resources = await getResources();
    
    for (final uri in resources) {
      final content = await getContent(uri);
      if (content != null && content.toLowerCase().contains(query.toLowerCase())) {
        final title = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
        final snippet = _extractSnippet(content, query);
        
        results.add({
          'uri': uri,
          'title': title,
          'snippet': snippet,
        });
      }
    }
    
    return results;
  }
  
  Future<void> _fetchDirectory(String relativePath) async {
    final apiUrl = relativePath.isEmpty ? repoApiUrl : '$repoApiUrl/$relativePath';
    
    try {
      final response = await _client.get(Uri.parse(apiUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch directory: ${response.statusCode}');
      }
      
      final List<dynamic> items = jsonDecode(response.body);
      
      for (final item in items) {
        final name = item['name'] as String;
        final type = item['type'] as String;
        final itemPath = relativePath.isEmpty ? name : '$relativePath/$name';
        
        if (type == 'dir') {
          // Create local directory and recurse
          final localDir = Directory(path.join(cacheDir, itemPath));
          await localDir.create(recursive: true);
          await _fetchDirectory(itemPath);
        } else if (type == 'file' && name.endsWith('.md')) {
          // Download markdown file
          await _downloadFile(itemPath);
        }
      }
    } catch (e) {
      print('⚠️  Error fetching directory $relativePath: $e');
    }
  }
  
  Future<void> _downloadFile(String remotePath) async {
    final rawUrl = '$rawBaseUrl/$remotePath';
    final localPath = path.join(cacheDir, remotePath);
    
    try {
      final response = await _client.get(Uri.parse(rawUrl));
      if (response.statusCode == 200) {
        await File(localPath).writeAsString(response.body);
        print('📄 Downloaded: $remotePath');
      } else {
        print('⚠️  Failed to download $remotePath: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️  Error downloading $remotePath: $e');
    }
  }
  
  Future<void> _createMetadata() async {
    final metadata = {
      'lastSync': DateTime.now().toIso8601String(),
      'source': 'https://github.com/flame-engine/flame',
      'version': 'main',
    };
    
    final file = File(path.join(cacheDir, 'metadata.json'));
    await file.writeAsString(jsonEncode(metadata));
  }
  
  String _extractSnippet(String content, String query) {
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        final start = (i - 1).clamp(0, lines.length - 1);
        final end = (i + 2).clamp(0, lines.length);
        return lines.sublist(start, end).join('\n').trim();
      }
    }
    return lines.take(3).join('\n').trim();
  }
  
  void dispose() {
    _client.close();
  }
}
