import 'package:hive/hive.dart';

import '../../shared/models/x_models.dart';

String buildUserLessonKey(String userId, String lessonId) {
  final normalizedUserId = userId.trim();
  final normalizedLessonId = lessonId.trim();
  if (normalizedUserId.isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'Must be a non-empty string');
  }
  if (normalizedLessonId.isEmpty) {
    throw ArgumentError.value(
      lessonId,
      'lessonId',
      'Must be a non-empty string',
    );
  }
  return '$normalizedUserId::$normalizedLessonId';
}

class LocalStorageService {
  const LocalStorageService();

  Box<Map> offlineLessonsBox() => Hive.box<Map>('offline_lessons');

  Box<Map> pendingProgressBox() => Hive.box<Map>('pending_progress');

  Future<void> saveOfflineLesson({
    required String userId,
    required Lesson lesson,
  }) async {
    final key = buildUserLessonKey(userId, lesson.id);
    await offlineLessonsBox().put(key, {
      'userId': userId.trim(),
      'lessonId': lesson.id.trim(),
      'lesson': lesson.toJson(),
    });
  }

  Lesson? getOfflineLesson({required String userId, required String lessonId}) {
    final key = buildUserLessonKey(userId, lessonId);
    final value = offlineLessonsBox().get(key);
    if (value == null) {
      return null;
    }
    final normalized = _normalizeMap(value);
    if (normalized['userId'] != userId.trim()) {
      return null;
    }
    final lessonJson = normalized['lesson'];
    if (lessonJson is! Map) {
      return null;
    }
    final lesson = Lesson.fromJson(lessonJson);
    return lesson.id == lessonId.trim() ? lesson : null;
  }

  List<Lesson> getOfflineLessons(String userId) => getOfflineLessonIds(userId)
      .map((lessonId) => getOfflineLesson(userId: userId, lessonId: lessonId))
      .whereType<Lesson>()
      .toList(growable: false);

  List<String> getOfflineLessonIds(String userId) {
    final normalizedUserId = _validateUserId(userId);
    final box = offlineLessonsBox();
    final ids = <String>[];
    for (final key in box.keys) {
      final keyString = key.toString();
      if (!keyString.startsWith('$normalizedUserId::')) {
        continue;
      }
      final value = box.get(key);
      if (value == null) {
        continue;
      }
      final normalized = _normalizeMap(value);
      if (normalized['userId'] != normalizedUserId) {
        continue;
      }
      final lessonId = normalized['lessonId'];
      if (lessonId is String && lessonId.isNotEmpty) {
        ids.add(lessonId);
      }
    }
    return ids;
  }

  bool hasOfflineLesson({required String userId, required String lessonId}) =>
      getOfflineLesson(userId: userId, lessonId: lessonId) != null;

  Future<void> deleteOfflineLesson({
    required String userId,
    required String lessonId,
  }) async {
    await offlineLessonsBox().delete(buildUserLessonKey(userId, lessonId));
  }

  /// Queues (or overwrites) a pending progress update for `item['lessonId']`
  /// so it can be sent to `POST /api/sync/progress` once the app is back
  /// online. Only the latest update per lesson is kept — an older queued
  /// update for the same lesson is superseded rather than duplicated.
  /// See docs/OFFLINE_FLOW.md.
  Future<void> queuePendingProgress(
    String userId,
    Map<String, dynamic> item,
  ) async {
    final normalizedUserId = _validateUserId(userId);
    final lessonId = item['lessonId'];
    if (lessonId is! String || lessonId.trim().isEmpty) {
      throw ArgumentError.value(
        lessonId,
        'lessonId',
        'Must be a non-empty string',
      );
    }
    final normalizedLessonId = lessonId.trim();
    await pendingProgressBox().put(
      buildUserLessonKey(normalizedUserId, normalizedLessonId),
      {...item, 'userId': normalizedUserId, 'lessonId': normalizedLessonId},
    );
  }

  /// Snapshot of everything currently queued, decoded to plain
  /// `Map<String, dynamic>` so callers don't need to know about Hive types.
  List<Map<String, dynamic>> pendingProgressItems(String userId) =>
      pendingProgressSnapshot(userId).values.toList(growable: false);

  Map<String, Map<String, dynamic>> pendingProgressSnapshot(String userId) {
    final normalizedUserId = _validateUserId(userId);
    final box = pendingProgressBox();
    final snapshot = <String, Map<String, dynamic>>{};
    for (final key in box.keys) {
      final keyString = key.toString();
      if (!keyString.startsWith('$normalizedUserId::')) {
        continue;
      }
      final value = box.get(key);
      if (value == null) {
        continue;
      }
      final normalized = _normalizeMap(value);
      if (normalized['userId'] != normalizedUserId) {
        continue;
      }
      final lessonId = normalized['lessonId'];
      if (lessonId is String && lessonId.isNotEmpty) {
        snapshot[keyString] = normalized;
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

  int pendingProgressCount(String userId) =>
      pendingProgressSnapshot(userId).length;

  bool hasPendingProgress(String userId) => pendingProgressCount(userId) > 0;

  String _validateUserId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must be a non-empty string');
    }
    return normalized;
  }

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
