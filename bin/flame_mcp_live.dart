#!/usr/bin/env dart

import 'package:flame_mcp_server/src/flame_mcp_live.dart';

void main(List<String> args) async {
  final server = FlameMcpLive();

  // Check for scheduler flag
  final enableScheduler = args.contains('--scheduler') || args.contains('-s');

  if (enableScheduler) {
    print('📅 Scheduler enabled - will sync nightly at 2 AM');
  } else {
    print('💡 Use --scheduler or -s to enable nightly sync');
  }

  await server.start(enableScheduler: enableScheduler);
}
