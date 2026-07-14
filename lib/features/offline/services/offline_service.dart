import 'package:hive/hive.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../../shared/models/x_models.dart';
import '../data/offline_repository.dart';
import '../models/offline_lesson_model.dart';

class OfflineService implements OfflineRepository {
  /// [box] is only for tests. The real box is resolved lazily via [_box]
  /// (not in this constructor / an initializer list) so that constructing
  /// `OfflineService()` is always safe even before `Hive.openBox` has run —
  /// this class is instantiated eagerly as an `AppState` field, and
  /// `AppState` is constructed in dozens of existing widget tests
  /// (`FakeAppState`) that never open any Hive box.
  OfflineService({Box<Map>? box}) : _injectedBox = box;

  final Box<Map>? _injectedBox;

  Box<Map> get _box =>
      _injectedBox ?? const LocalStorageService().offlineLessonsBox();

  @override
  Lesson? getLesson(String userId, String lessonId) =>
      getSnapshot(userId, lessonId)?.lesson;

  @override
  OfflineLessonSnapshot? getSnapshot(String userId, String lessonId) {
    final value = _box.get(buildUserLessonKey(userId, lessonId));
    if (value == null) {
      return null;
    }
    final snapshot = _snapshotFromValue(value);
    if (snapshot == null || snapshot.metadata.userId != userId.trim()) {
      return null;
    }
    return snapshot.lesson.id == lessonId.trim() ? snapshot : null;
  }

  @override
  List<String> getDownloadedLessonIds(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'Must be a non-empty string');
    }
    final ids = <String>[];
    for (final key in _box.keys) {
      final keyString = key.toString();
      if (!keyString.startsWith('$normalizedUserId::')) {
        continue;
      }
      final value = _box.get(key);
      if (value == null) {
        continue;
      }
      final snapshot = _snapshotFromValue(value);
      if (snapshot == null || snapshot.metadata.userId != normalizedUserId) {
        continue;
      }
      if (snapshot.metadata.lessonId.isNotEmpty) {
        ids.add(snapshot.metadata.lessonId);
      }
    }
    return ids;
  }

  @override
  List<OfflineLessonSnapshot> getDownloadedLessons(String userId) =>
      getDownloadedLessonIds(userId)
          .map((lessonId) => getSnapshot(userId, lessonId))
          .whereType<OfflineLessonSnapshot>()
          .toList(growable: false);

  @override
  Future<void> saveLesson(String userId, Lesson lesson) async {
    final metadata = OfflineLessonVersioning.metadataForDownloadedLesson(
      userId: userId,
      lesson: lesson,
    );
    await saveSnapshot(OfflineLessonSnapshot(lesson: lesson, metadata: metadata));
  }

  @override
  Future<void> saveSnapshot(OfflineLessonSnapshot snapshot) async {
    await _box.put(
      buildUserLessonKey(snapshot.metadata.userId, snapshot.metadata.lessonId),
      snapshot.toCacheMap(),
    );
  }

  @override
  Future<void> updateMetadata(
    String userId,
    String lessonId,
    OfflineLessonMetadata metadata,
  ) async {
    final snapshot = getSnapshot(userId, lessonId);
    if (snapshot == null) {
      return;
    }
    await saveSnapshot(OfflineLessonSnapshot(lesson: snapshot.lesson, metadata: metadata));
  }

  @override
  Future<void> deleteLesson(String userId, String lessonId) =>
      _box.delete(buildUserLessonKey(userId, lessonId));

  OfflineLessonSnapshot? _snapshotFromValue(Map<dynamic, dynamic> value) {
    try {
      return OfflineLessonSnapshot.fromCacheMap(value);
    } catch (_) {
      return null;
    }
  }
}
