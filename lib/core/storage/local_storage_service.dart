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
    final lessonId = item['lessonId'] as String;
    await pendingProgressBox().put(lessonId, item);
  }

  /// Snapshot of everything currently queued, decoded to plain
  /// `Map<String, dynamic>` so callers don't need to know about Hive types.
  List<Map<String, dynamic>> pendingProgressItems() => pendingProgressBox()
      .values
      .map((value) => Map<String, dynamic>.from(value))
      .toList(growable: false);

  bool get hasPendingProgress => pendingProgressBox().isNotEmpty;
}
