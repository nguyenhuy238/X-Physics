import 'package:hive/hive.dart';

import '../../features/offline/models/offline_lesson_model.dart';
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

  Box<Map> practiceQuestionsBox() => Hive.box<Map>('practice_questions');

  Box<Map> pendingPracticeSyncBox() => Hive.box<Map>('pending_practice_sync');

  Future<void> saveOfflineLesson({
    required String userId,
    required Lesson lesson,
  }) async {
    final metadata = OfflineLessonVersioning.metadataForDownloadedLesson(
      userId: userId,
      lesson: lesson,
    );
    await offlineLessonsBox().put(
      buildUserLessonKey(metadata.userId, metadata.lessonId),
      OfflineLessonSnapshot(lesson: lesson, metadata: metadata).toCacheMap(),
    );
  }

  Lesson? getOfflineLesson({required String userId, required String lessonId}) {
    return getOfflineLessonSnapshot(userId: userId, lessonId: lessonId)?.lesson;
  }

  OfflineLessonSnapshot? getOfflineLessonSnapshot({
    required String userId,
    required String lessonId,
  }) {
    final value = offlineLessonsBox().get(buildUserLessonKey(userId, lessonId));
    if (value == null) {
      return null;
    }
    try {
      final snapshot = OfflineLessonSnapshot.fromCacheMap(value);
      if (snapshot.metadata.userId != userId.trim()) {
        return null;
      }
      return snapshot.lesson.id == lessonId.trim() ? snapshot : null;
    } catch (_) {
      return null;
    }
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
      final snapshot = _offlineSnapshotFromValue(value);
      if (snapshot == null || snapshot.metadata.userId != normalizedUserId) {
        continue;
      }
      if (snapshot.metadata.lessonId.isNotEmpty) {
        ids.add(snapshot.metadata.lessonId);
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
    await practiceQuestionsBox().delete(buildUserLessonKey(userId, lessonId));
  }

  Future<void> savePracticeQuestions({
    required String userId,
    required String lessonId,
    required List<Question> questions,
  }) async {
    final normalizedUserId = _validateUserId(userId);
    final normalizedLessonId = _validateLessonId(lessonId);
    await practiceQuestionsBox().put(
      buildUserLessonKey(normalizedUserId, normalizedLessonId),
      {
        'userId': normalizedUserId,
        'lessonId': normalizedLessonId,
        'questions': questions.map((question) => question.toJson()).toList(),
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  List<Question> getPracticeQuestions({
    required String userId,
    required String lessonId,
  }) {
    final value = practiceQuestionsBox().get(buildUserLessonKey(userId, lessonId));
    if (value == null) {
      return const [];
    }
    final normalized = _normalizeMap(value);
    if (normalized['userId'] != userId.trim() ||
        normalized['lessonId'] != lessonId.trim()) {
      return const [];
    }
    final questions = normalized['questions'];
    if (questions is! List) {
      return const [];
    }
    return questions
        .whereType<Map>()
        .map((item) => Question.fromJson(item))
        .toList(growable: false);
  }

  bool hasPracticeQuestions({
    required String userId,
    required String lessonId,
  }) => getPracticeQuestions(userId: userId, lessonId: lessonId).isNotEmpty;

  Future<void> queuePendingPracticeSession(
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
    final sessionId = item['id'];
    if (sessionId is! String || sessionId.trim().isEmpty) {
      throw ArgumentError.value(
        sessionId,
        'id',
        'Must be a non-empty string',
      );
    }
    final normalizedLessonId = lessonId.trim();
    final normalizedSessionId = sessionId.trim();
    final key = _practiceSessionKey(
      normalizedUserId,
      normalizedLessonId,
      normalizedSessionId,
    );
    final existing = pendingPracticeSyncBox().get(key);
    final existingMap = existing == null ? null : _normalizeMap(existing);
    final now = DateTime.now().toUtc().toIso8601String();
    await pendingPracticeSyncBox().put(key, {
      ...?existingMap,
      ...item,
      'userId': normalizedUserId,
      'lessonId': normalizedLessonId,
      'id': normalizedSessionId,
      'createdAt': _readNonEmptyString(existingMap?['createdAt']) ?? now,
      'retryCount': _readInt(existingMap?['retryCount']) ?? 0,
      'lastError': existingMap?['lastError'],
      'nextRetryAt': existingMap?['nextRetryAt'],
    });
  }

  Map<String, Map<String, dynamic>> pendingPracticeSnapshot(String userId) {
    final normalizedUserId = _validateUserId(userId);
    final box = pendingPracticeSyncBox();
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
      final sessionId = normalized['id'];
      if (lessonId is String &&
          lessonId.isNotEmpty &&
          sessionId is String &&
          sessionId.isNotEmpty) {
        snapshot[keyString] = normalized;
      }
    }
    return snapshot;
  }

  Future<void> removePendingPracticeSnapshot(
    Map<String, Map<String, dynamic>> snapshot,
  ) async {
    final box = pendingPracticeSyncBox();
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

  Future<void> markPendingPracticeSnapshotFailed(
    Map<String, Map<String, dynamic>> snapshot,
    Object error,
  ) async {
    final box = pendingPracticeSyncBox();
    final now = DateTime.now().toUtc();
    for (final entry in snapshot.entries) {
      final current = box.get(entry.key);
      if (current == null) {
        continue;
      }
      final normalized = _normalizeMap(current);
      if (!_mapsEqual(normalized, entry.value)) {
        continue;
      }
      final retryCount = (_readInt(normalized['retryCount']) ?? 0) + 1;
      final delaySeconds = (1 << retryCount).clamp(2, 300).toInt();
      await box.put(entry.key, {
        ...normalized,
        'retryCount': retryCount,
        'lastError': error.toString(),
        'nextRetryAt': now
            .add(Duration(seconds: delaySeconds))
            .toIso8601String(),
      });
    }
  }

  int pendingPracticeCount(String userId) =>
      pendingPracticeSnapshot(userId).length;

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
    final key = buildUserLessonKey(normalizedUserId, normalizedLessonId);
    final existing = pendingProgressBox().get(key);
    final existingMap = existing == null ? null : _normalizeMap(existing);
    final now = DateTime.now().toUtc().toIso8601String();
    final incomingPercent = _readInt(
      item['progressPercent'],
    )?.clamp(0, 100).toInt();
    final existingPercent =
        _readInt(existingMap?['progressPercent'])?.clamp(0, 100).toInt() ?? 0;
    final mergedPercent = incomingPercent == null
        ? existingPercent
        : (incomingPercent < existingPercent
              ? existingPercent
              : incomingPercent);
    final operationId =
        _readNonEmptyString(item['operationId']) ??
        (incomingPercent != null && incomingPercent > existingPercent
            ? null
            : _readNonEmptyString(existingMap?['operationId'])) ??
        _newOperationId(normalizedUserId, normalizedLessonId);

    await pendingProgressBox().put(key, {
      ...?existingMap,
      ...item,
      'userId': normalizedUserId,
      'lessonId': normalizedLessonId,
      'progressPercent': mergedPercent,
      'isCompleted': item['isCompleted'] == true || mergedPercent >= 100,
      'operationId': operationId,
      'clientUpdatedAt':
          _readNonEmptyString(item['clientUpdatedAt']) ??
          _readNonEmptyString(existingMap?['clientUpdatedAt']) ??
          now,
      'createdAt': _readNonEmptyString(existingMap?['createdAt']) ?? now,
      'retryCount': _readInt(existingMap?['retryCount']) ?? 0,
      'lastError': existingMap?['lastError'],
      'nextRetryAt': existingMap?['nextRetryAt'],
    });
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

  Future<void> markPendingProgressSnapshotFailed(
    Map<String, Map<String, dynamic>> snapshot,
    Object error,
  ) async {
    final box = pendingProgressBox();
    final now = DateTime.now().toUtc();
    for (final entry in snapshot.entries) {
      final current = box.get(entry.key);
      if (current == null) {
        continue;
      }
      final normalized = _normalizeMap(current);
      if (!_mapsEqual(normalized, entry.value)) {
        continue;
      }
      final retryCount = (_readInt(normalized['retryCount']) ?? 0) + 1;
      final delaySeconds = (1 << retryCount).clamp(2, 300).toInt();
      await box.put(entry.key, {
        ...normalized,
        'retryCount': retryCount,
        'lastError': error.toString(),
        'nextRetryAt': now
            .add(Duration(seconds: delaySeconds))
            .toIso8601String(),
      });
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

  String _validateLessonId(String lessonId) {
    final normalized = lessonId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        lessonId,
        'lessonId',
        'Must be a non-empty string',
      );
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

  OfflineLessonSnapshot? _offlineSnapshotFromValue(
    Map<dynamic, dynamic> value,
  ) {
    try {
      return OfflineLessonSnapshot.fromCacheMap(value);
    } catch (_) {
      return null;
    }
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

  int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? _readNonEmptyString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  String _newOperationId(String userId, String lessonId) {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    final userHash = userId.hashCode.toUnsigned(32).toRadixString(16);
    final lessonHash = lessonId.hashCode.toUnsigned(32).toRadixString(16);
    return '$userHash-$lessonHash-$timestamp';
  }

  String _practiceSessionKey(String userId, String lessonId, String sessionId) =>
      '${buildUserLessonKey(userId, lessonId)}::$sessionId';
}
