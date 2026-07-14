import 'package:hive/hive.dart';

class LocalStorageService {
  const LocalStorageService();

  Box<Map> offlineLessonsBox() => Hive.box<Map>('offline_lessons');

  Box<Map> pendingProgressBox() => Hive.box<Map>('pending_progress');

  /// Queues (or overwrites) a pending progress update for `item['lessonId']`
  /// so it can be sent to `POST /api/sync/progress` once the app is back
  /// online. Only the latest update per lesson is kept — an older queued
  /// update for the same lesson is superseded rather than duplicated.
  /// See docs/OFFLINE_FLOW.md.
  Future<void> queuePendingProgress(Map<String, dynamic> item) async {
    final lessonId = item['lessonId'];
    if (lessonId is! String || lessonId.trim().isEmpty) {
      throw ArgumentError.value(
        lessonId,
        'lessonId',
        'Must be a non-empty string',
      );
    }
    await pendingProgressBox().put(lessonId, item);
  }

  /// Snapshot of everything currently queued, decoded to plain
  /// `Map<String, dynamic>` so callers don't need to know about Hive types.
  List<Map<String, dynamic>> pendingProgressItems() =>
      pendingProgressSnapshot().values.toList(growable: false);

  Map<String, Map<String, dynamic>> pendingProgressSnapshot() {
    final box = pendingProgressBox();
    final snapshot = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final value = box.get(key);
      if (value == null) {
        continue;
      }
      final normalized = _normalizeMap(value);
      final lessonId = normalized['lessonId'];
      if (lessonId is String && lessonId.isNotEmpty) {
        snapshot[lessonId] = normalized;
      }
    }
    return snapshot;
  }

  Future<void> removePendingProgressSnapshot(
    Map<String, Map<String, dynamic>> snapshot,
  ) async {
    final box = pendingProgressBox();
    for (final entry in snapshot.entries) {
      final current = box.get(entry.key);
      if (current == null) {
        continue;
      }
      if (_mapsEqual(_normalizeMap(current), entry.value)) {
        await box.delete(entry.key);
      }
    }
  }

  bool get hasPendingProgress => pendingProgressBox().isNotEmpty;

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> source) {
    final normalized = <String, dynamic>{};
    source.forEach((key, value) {
      normalized[key.toString()] = value;
    });
    return normalized;
  }

  bool _mapsEqual(Map<String, dynamic> left, Map<String, dynamic> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
