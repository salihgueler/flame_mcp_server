import 'dart:async';
import 'flame_live_docs.dart';

/// Simple scheduler for nightly documentation sync
class SimpleScheduler {
  final FlameLiveDocs _docs = FlameLiveDocs();
  Timer? _timer;
  bool _isRunning = false;

  /// Start the scheduler (syncs at 2 AM daily)
  void start() {
    print('📅 Starting documentation scheduler...');
    _scheduleNext();
  }

  /// Manually trigger a sync
  Future<bool> syncNow() async {
    if (_isRunning) {
      print('⚠️  Sync already in progress');
      return false;
    }

    _isRunning = true;
    try {
      await _docs.syncDocs();
      print('✅ Manual sync completed');
      return true;
    } catch (e) {
      print('❌ Manual sync failed: $e');
      return false;
    } finally {
      _isRunning = false;
    }
  }

  /// Get scheduler status
  Map<String, dynamic> getStatus() {
    final nextSync = _getNextSyncTime();
    return {
      'isRunning': _isRunning,
      'nextSync': nextSync.toIso8601String(),
      'hoursUntilNext': nextSync.difference(DateTime.now()).inHours,
    };
  }

  void _scheduleNext() {
    _timer?.cancel();

    final nextSync = _getNextSyncTime();
    final delay = nextSync.difference(DateTime.now());

    print('⏰ Next sync scheduled for: $nextSync');

    _timer = Timer(delay, () async {
      await _performSync();
      _scheduleNext(); // Schedule the next one
    });
  }

  DateTime _getNextSyncTime() {
    final now = DateTime.now();
    var nextSync = DateTime(now.year, now.month, now.day, 2, 0); // 2 AM

    // If it's already past 2 AM today, schedule for tomorrow
    if (nextSync.isBefore(now)) {
      nextSync = nextSync.add(const Duration(days: 1));
    }

    return nextSync;
  }

  Future<void> _performSync() async {
    if (_isRunning) return;

    _isRunning = true;
    print('🌙 Starting scheduled documentation sync...');

    try {
      await _docs.syncDocs();
      print('✅ Scheduled sync completed successfully');
    } catch (e) {
      print('❌ Scheduled sync failed: $e');
      // Could add retry logic here if needed
    } finally {
      _isRunning = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _docs.dispose();
    print('⏹️  Scheduler stopped');
  }
}
