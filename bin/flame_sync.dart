#!/usr/bin/env dart

import 'dart:io';
import 'package:flame_mcp_server/src/flame_live_docs.dart';

void main() async {
  print('🎮 Flame Documentation Sync');
  print('===========================');

  final docs = FlameLiveDocs();

  try {
    await docs.syncDocs();

    // Show summary
    final resources = await docs.getResources();
    final metadata = await docs.getMetadata();

    print('\n📊 Sync Summary:');
    print('   • Total resources: ${resources.length}');
    print('   • Last sync: ${metadata?['lastSync'] ?? 'Unknown'}');
    print('   • Source: ${metadata?['source'] ?? 'Unknown'}');

    if (resources.isNotEmpty) {
      print('\n🔗 Sample resources:');
      for (final resource in resources.take(5)) {
        print('   • $resource');
      }
      if (resources.length > 5) {
        print('   • ... and ${resources.length - 5} more');
      }
    }
  } catch (e) {
    print('❌ Sync failed: $e');
    exit(1);
  } finally {
    docs.dispose();
  }
}
