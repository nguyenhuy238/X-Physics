import '../../../core/storage/local_storage_service.dart';

/// Signature matching the subset of `ApiClient` this service needs: POST a
/// JSON body to [path] and return the decoded response body. Kept as a
/// plain function type (instead of taking a `Dio`/`ApiClient` directly) so
/// this service can be unit-tested without mocking Dio — see
/// test/offline_sync_test.dart.
typedef SyncPost =
    Future<Map<String, dynamic>> Function(
      String path,
      Map<String, dynamic> data,
    );

/// Flushes locally-queued reading-progress updates (the `pending_progress`
/// Hive box, see [LocalStorageService]) to `POST /api/sync/progress` once
/// the device is back online. See docs/OFFLINE_FLOW.md for the full flow
/// and its known limitations (quiz submission is NOT queued here).
class ProgressSyncService {
  ProgressSyncService({
    required SyncPost post,
    LocalStorageService? localStorage,
    String path = '/api/sync/progress',
  }) : _post = post,
       _localStorage = localStorage ?? const LocalStorageService(),
       _path = path;

  final SyncPost _post;
  final LocalStorageService _localStorage;
  final String _path;

  /// Returns the number of items successfully synced (`0` if the queue was
  /// empty or the request failed — everything stays queued on failure so
  /// it is retried on the next reconnect).
  Future<int> syncPending() async {
    final items = _localStorage.pendingProgressItems();
    if (items.isEmpty) {
      return 0;
    }

    try {
      await _post(_path, {'items': items});
    } catch (_) {
      // Network/API failure: keep everything queued. The backend accepts
      // or rejects the whole batch (see
      // backend/src/modules/offline-sync/offline-sync.service.ts), so
      // there is no partial-success case to handle for MVP.
      return 0;
    }

    await _localStorage.pendingProgressBox().clear();
    return items.length;
  }
}
