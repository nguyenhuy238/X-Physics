import '../../../core/storage/local_storage_service.dart';

/// Signature matching the subset of `ApiClient` this service needs: POST a
/// JSON body to [path] and return the decoded response body. Kept as a
/// plain function type (instead of taking a `Dio`/`ApiClient` directly) so
/// this service can be unit-tested without mocking Dio — see
/// test/offline_sync_test.dart.
typedef SyncPost =
    Future<Map<String, dynamic>> Function(
      String userId,
      String path,
      Map<String, dynamic> data,
    );
typedef IsUserActive = bool Function(String userId);

/// Flushes locally-queued reading-progress updates (the `pending_progress`
/// Hive box, see [LocalStorageService]) to `POST /api/sync/progress` once
/// the device is back online. See docs/OFFLINE_FLOW.md for the full flow
/// and its known limitations (quiz submission is NOT queued here).
class ProgressSyncService {
  ProgressSyncService({
    required SyncPost post,
    IsUserActive? isUserActive,
    LocalStorageService? localStorage,
    String path = '/api/sync/progress',
  }) : _post = post,
       _isUserActive = isUserActive ?? ((_) => true),
       _localStorage = localStorage ?? const LocalStorageService(),
       _path = path;

  final SyncPost _post;
  final IsUserActive _isUserActive;
  final LocalStorageService _localStorage;
  final String _path;
  final _runningSyncByUser = <String, Future<int>>{};

  /// Returns the number of items successfully synced (`0` if the queue was
  /// empty or the request failed — everything stays queued on failure so
  /// it is retried on the next reconnect).
  Future<int> syncPending(String? userId) {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return Future.value(0);
    }

    final current = _runningSyncByUser[normalizedUserId];
    if (current != null) {
      return current;
    }

    final future = _syncPendingOnce(normalizedUserId);
    _runningSyncByUser[normalizedUserId] = future;
    future.whenComplete(() {
      if (identical(_runningSyncByUser[normalizedUserId], future)) {
        _runningSyncByUser.remove(normalizedUserId);
      }
    });
    return future;
  }

  Future<int> _syncPendingOnce(String userId) async {
    final snapshot = _localStorage.pendingProgressSnapshot(userId);
    final items = snapshot.values.toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }

    Map<String, dynamic> response;
    try {
      if (!_isUserActive(userId)) {
        return 0;
      }
      final payloadItems = items.map(_syncPayloadItem).toList(growable: false);
      response = await _post(userId, _path, {'items': payloadItems});
    } catch (error) {
      await _localStorage.markPendingProgressSnapshotFailed(snapshot, error);
      return 0;
    }

    if (!_isUserActive(userId)) {
      return 0;
    }
    final acceptedSnapshot = _acceptedSnapshot(snapshot, response);
    if (acceptedSnapshot.isEmpty) {
      return 0;
    }
    await _localStorage.removePendingProgressSnapshot(acceptedSnapshot);
    return acceptedSnapshot.length;
  }

  Map<String, dynamic> _syncPayloadItem(Map<String, dynamic> item) => {
    'lessonId': item['lessonId'],
    'progressPercent': item['progressPercent'],
    'isCompleted': item['isCompleted'] == true,
    'clientUpdatedAt': item['clientUpdatedAt'],
    if (item['operationId'] is String) 'operationId': item['operationId'],
    if (item['quizAttempt'] is Map) 'quizAttempt': item['quizAttempt'],
  };

  Map<String, Map<String, dynamic>> _acceptedSnapshot(
    Map<String, Map<String, dynamic>> snapshot,
    Map<String, dynamic> response,
  ) {
    final data = response['data'] is Map
        ? Map<String, dynamic>.from(response['data'] as Map)
        : response;
    final accepted = data['accepted'];
    if (accepted is! List) {
      final syncedItems = data['syncedItems'];
      if (syncedItems is int && syncedItems == snapshot.length) {
        return snapshot;
      }
      return const {};
    }

    final acceptedOperationIds = <String>{};
    final acceptedLessonIds = <String>{};
    for (final item in accepted) {
      if (item is! Map) {
        continue;
      }
      final operationId = item['operationId'];
      if (operationId is String && operationId.isNotEmpty) {
        acceptedOperationIds.add(operationId);
      }
      final lessonId = item['lessonId'];
      if (lessonId is String && lessonId.isNotEmpty) {
        acceptedLessonIds.add(lessonId);
      }
    }

    return Map.fromEntries(
      snapshot.entries.where((entry) {
        final operationId = entry.value['operationId'];
        if (operationId is String &&
            operationId.isNotEmpty &&
            acceptedOperationIds.contains(operationId)) {
          return true;
        }
        final lessonId = entry.value['lessonId'];
        return lessonId is String && acceptedLessonIds.contains(lessonId);
      }),
    );
  }
}
