import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

/// Simple offline sync service.
/// - monitors connectivity
/// - processes local pending records (IsSynced = 0)
/// - marks records synced when connectivity available
/// Note: remote sync hook is a placeholder to wire in an API later.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  Timer? _pollTimer;
  bool _running = false;

  void start({Duration interval = const Duration(seconds: 10)}) {
    if (_running) return;
    _running = true;
    _tick();
    _pollTimer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _running = false;
  }

  Future<void> _tick() async {
    final online = await _checkConnectivity();
    isOnline.value = online;
    await _updatePendingCount();
    if (online) await _processQueue();
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updatePendingCount() async {
    final pending = await DatabaseHelper.instance.getPendingSyncRecords();
    pendingCount.value = pending.length;
  }

  /// Process queued (pending) records.
  /// For now this simulates a successful remote sync and marks items as synced.
  Future<void> _processQueue() async {
    final pending = await DatabaseHelper.instance.getPendingSyncRecords();
    if (pending.isEmpty) return;

    // In a real app you would POST each pending record to your API here.
    for (final r in pending) {
      try {
        // TODO: implement remote sync - currently simulate success
        await Future.delayed(const Duration(milliseconds: 250));
        await DatabaseHelper.instance.markRecordSynced(r['RecordID'] as int);
      } catch (e) {
        // keep item pending; continue with next
        debugPrint('Sync failed for ${r['RecordID']}: $e');
      }
    }

    await _updatePendingCount();
  }
}
