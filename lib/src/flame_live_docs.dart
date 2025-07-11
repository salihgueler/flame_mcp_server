import 'dart:io';
import 'package:path/path.dart' as path;

/// Simple, robust live documentation fetcher for Flame engine
class FlameLiveDocs {
  // Use absolute path for cache directory
  static String get cacheDir {
    // Get the directory where the executable is located
    final executablePath = Platform.resolvedExecutable;
    final executableDir = File(executablePath).parent.path;

    // The executable is in build/, so go up one level to project root
    final projectRoot = Directory(executableDir).parent.path;
    return path.join(projectRoot, 'flame_docs_cache');
  }

  /// Initialize the documentation system
  Future<void> initialize() async {
    // Check if cache exists and build index
    final dir = Directory(cacheDir);
    if (await dir.exists()) {
      await _buildIndex();
    }
  }

  // Cache for indexed resources
  List<String>? _cachedResources;

  /// Build index of all cached files
  Future<void> _buildIndex() async {
    final resources = <String>[];
    final dir = Directory(cacheDir);

    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.md')) {
          final relativePath = path.relative(entity.path, from: cacheDir);
          final uri =
              'flame://${relativePath.replaceAll(path.separator, '/').replaceAll('.md', '')}';
          resources.add(uri);
        }
      }
    }

    _cachedResources = resources;
  }

  /// Get all available documentation resources
  Future<List<String>> getResources() async {
    // Return cached resources if available
    if (_cachedResources != null) {
      return _cachedResources!;
    }

    // Build index if not cached
    await _buildIndex();
    return _cachedResources ?? [];
  }

  /// Get content for a specific resource
  Future<String?> getContent(String uri) async {
    final docPath = uri.replaceFirst('flame://', '');
    final filePath = path.join(cacheDir, '$docPath.md');
    final file = File(filePath);

    if (await file.exists()) {
      final content = await file.readAsString();
      return _sanitizeContent(content);
    }

    return null;
  }

  /// Sanitize content to avoid JSON encoding issues
  String _sanitizeContent(String content) {
    // Remove or replace characters that might cause JSON parsing issues
    return content
        // Replace text emoticons that might cause issues
        .replaceAll(':)', '🙂')
        .replaceAll(':(', '🙁')
        .replaceAll(':D', '😀')
        .replaceAll(';)', '😉')
        // Remove control characters except newlines and tabs
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        // Ensure content is valid UTF-8
        .replaceAll('\uFFFD', '?'); // Replace replacement character
  }

  /// Search through documentation
  Future<List<Map<String, dynamic>>> search(String query) async {
    final results = <Map<String, dynamic>>[];
    final resources = await getResources();

    for (final uri in resources) {
      try {
        final content = await getContent(uri);
        if (content != null &&
            content.toLowerCase().contains(query.toLowerCase())) {
          final title = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
          final snippet = _extractSnippet(content, query);

          results.add({
            'uri': uri,
            'title': title,
            'snippet': snippet,
          });
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }

    return results;
  }

  /// Search specifically through tutorial documentation
  Future<List<Map<String, dynamic>>> searchTutorials(String query) async {
    final results = <Map<String, dynamic>>[];
    final resources = await getResources();

    // Filter to only tutorial resources
    final tutorialResources =
        resources.where((uri) => uri.contains('tutorials/')).toList();

    for (final uri in tutorialResources) {
      try {
        final content = await getContent(uri);
        if (content != null &&
            content.toLowerCase().contains(query.toLowerCase())) {
          final title = uri.replaceFirst('flame://', '').replaceAll('/', ' > ');
          final snippet = _extractSnippet(content, query);

          results.add({
            'uri': uri,
            'title': title,
            'snippet': snippet,
          });
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }

    return results;
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
}
