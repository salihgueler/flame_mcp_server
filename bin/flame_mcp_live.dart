#!/usr/bin/env dart

import 'package:flame_mcp_server/src/flame_mcp_live.dart';

void main() async {
  final server = FlameMcpLive();
  await server.start();
}
