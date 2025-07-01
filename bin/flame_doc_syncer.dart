#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

/// Standalone script to sync Flame documentation
/// This script is separate from the MCP server and only handles cache management
void main() async {
  print('🔄 Syncing Flame Documentation');
  print('==============================');

  final syncer = FlameDocSyncer();

  try {
    await syncer.syncDocs();
    print('✅ Documentation sync completed successfully!');
  } catch (e) {
    print('❌ Sync failed: $e');
    exit(1);
  } finally {
    syncer.dispose();
  }
}

class FlameDocSyncer {
  FlameDocSyncer({String? githubToken})
      : _githubToken = githubToken ?? Platform.environment['GITHUB_TOKEN'];

  static const String repoApiUrl =
      'https://api.github.com/repos/flame-engine/flame/contents/doc';
  static const String rawBaseUrl =
      'https://raw.githubusercontent.com/flame-engine/flame/main/doc';

  // Use absolute path for cache directory
  static String get cacheDir {
    // Get the directory where the script is located
    final scriptPath = Platform.script.toFilePath();
    final scriptDir =
        File(scriptPath).parent.parent.path; // Go up from bin/ to project root
    return path.join(scriptDir, 'flame_docs_cache');
  }

  final http.Client _client = http.Client();
  final String? _githubToken;

  /// Get HTTP headers for GitHub API requests
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'Flame-MCP-Server/1.0',
    };

    if (_githubToken != null && _githubToken.isNotEmpty) {
      headers['Authorization'] = 'token $_githubToken';
    }

    return headers;
  }

  /// Sync documentation from GitHub
  Future<void> syncDocs() async {
    // Show authentication status
    if (_githubToken != null && _githubToken.isNotEmpty) {
      print('🔑 Using GitHub personal access token (higher rate limits)');

      // Check rate limit
      final rateLimitInfo = await getRateLimitStatus();
      if (rateLimitInfo.containsKey('rate')) {
        final rate = rateLimitInfo['rate'];
        print(
            '📊 API Rate Limit: ${rate['remaining']}/${rate['limit']} requests remaining');
        if (rate['remaining'] < 10) {
          print('⚠️  Warning: Low API rate limit remaining!');
        }
      }
    } else {
      print(
          '⚠️  No GitHub token found - using unauthenticated requests (60/hour limit)');
      print(
          '💡 Set GITHUB_TOKEN environment variable for higher limits (5000/hour)');
    }

    // Create cache directory
    final dir = Directory(cacheDir);
    if (await dir.exists()) {
      print('🗑️  Clearing existing cache...');
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    print('📁 Cache directory: $cacheDir');

    // Fetch all markdown files
    await _fetchDirectory('');

    // Count cached files
    int fileCount = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        fileCount++;
      }
    }

    print('📚 Cached $fileCount documentation files');
  }

  /// Check GitHub API rate limit status
  Future<Map<String, dynamic>> getRateLimitStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('https://api.github.com/rate_limit'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get rate limit: ${response.statusCode}');
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> _fetchDirectory(String relativePath) async {
    final apiUrl =
        relativePath.isEmpty ? repoApiUrl : '$repoApiUrl/$relativePath';

    try {
      final response = await _client.get(
        Uri.parse(apiUrl),
        headers: _getHeaders(),
      );

      if (response.statusCode == 403) {
        // Check if it's a rate limit issue
        final rateLimitRemaining = response.headers['x-ratelimit-remaining'];
        if (rateLimitRemaining == '0') {
          throw Exception(
              'GitHub API rate limit exceeded. Please wait or use a personal access token.');
        }
        throw Exception(
            'Access forbidden: ${response.statusCode}. Check your GitHub token permissions.');
      } else if (response.statusCode != 200) {
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
      rethrow;
    }
  }

  Future<void> _downloadFile(String remotePath) async {
    final rawUrl = '$rawBaseUrl/$remotePath';
    final localPath = path.join(cacheDir, remotePath);

    try {
      final response = await _client.get(
        Uri.parse(rawUrl),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        await File(localPath).writeAsString(response.body);
        print('📄 Downloaded: $remotePath');
      } else if (response.statusCode == 403) {
        print('⚠️  Access forbidden for $remotePath: ${response.statusCode}');
      } else {
        print('⚠️  Failed to download $remotePath: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️  Error downloading $remotePath: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
