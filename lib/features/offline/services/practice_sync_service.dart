import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/local_storage_service.dart';
import 'progress_sync_service.dart';

class PracticeSyncService {
  PracticeSyncService({
    required SyncPost post,
    IsUserActive? isUserActive,
    LocalStorageService? localStorage,
  }) : _post = post,
       _isUserActive = isUserActive ?? ((_) => true),
       _localStorage = localStorage ?? const LocalStorageService();

  final SyncPost _post;
  final IsUserActive _isUserActive;
  final LocalStorageService _localStorage;
  final _runningSyncByUser = <String, Future<int>>{};

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
    final snapshot = _localStorage.pendingPracticeSnapshot(userId);
    if (snapshot.isEmpty) {
      return 0;
    }

    final byLesson = <String, Map<String, Map<String, dynamic>>>{};
    for (final entry in snapshot.entries) {
      final lessonId = entry.value['lessonId'];
      if (lessonId is! String || lessonId.isEmpty) {
        continue;
      }
      byLesson.putIfAbsent(lessonId, () => {})[entry.key] = entry.value;
    }

    var synced = 0;
    for (final entry in byLesson.entries) {
      if (!_isUserActive(userId)) {
        return synced;
      }
      final lessonSnapshot = entry.value;
      try {
        final response = await _post(
          userId,
          ApiEndpoints.lessonPracticeSync(entry.key),
          {
            'items': lessonSnapshot.values
                .map(_syncPayloadItem)
                .toList(growable: false),
          },
        );
        if (!_isUserActive(userId)) {
          return synced;
        }
        final accepted = _acceptedSnapshot(lessonSnapshot, response);
        if (accepted.isNotEmpty) {
          await _localStorage.removePendingPracticeSnapshot(accepted);
          synced += accepted.length;
        }
      } catch (error) {
        await _localStorage.markPendingPracticeSnapshotFailed(
          lessonSnapshot,
          error,
        );
      }
    }
    return synced;
  }

  Map<String, dynamic> _syncPayloadItem(Map<String, dynamic> item) => {
    'id': item['id'],
    'startedAt': item['startedAt'],
    'completedAt': item['completedAt'],
    if (item['answers'] is List) 'answers': item['answers'],
    if (item['questionsAttempted'] is int)
      'questionsAttempted': item['questionsAttempted'],
    if (item['correctCount'] is int) 'correctCount': item['correctCount'],
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
      if (data['success'] == true) {
        return snapshot;
      }
      return const {};
    }

    final ids = <String>{};
    for (final item in accepted) {
      if (item is Map && item['id'] is String) {
        ids.add(item['id'] as String);
      }
    }
    return Map.fromEntries(
      snapshot.entries.where((entry) => ids.contains(entry.value['id'])),
    );
  }
}
