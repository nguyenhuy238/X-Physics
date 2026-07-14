import 'package:hive/hive.dart';

import '../../../core/storage/local_storage_service.dart';
import '../../../shared/models/x_models.dart';
import '../data/offline_repository.dart';

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
  Lesson? getLesson(String userId, String lessonId) {
    final value = _box.get(buildUserLessonKey(userId, lessonId));
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

  @override
  Future<void> saveLesson(String userId, Lesson lesson) async {
    await _box.put(buildUserLessonKey(userId, lesson.id), {
      'userId': userId.trim(),
      'lessonId': lesson.id.trim(),
      'lesson': lesson.toJson(),
    });
  }

  @override
  Future<void> deleteLesson(String userId, String lessonId) =>
      _box.delete(buildUserLessonKey(userId, lessonId));

  Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> source) {
    final normalized = <String, dynamic>{};
    source.forEach((key, value) {
      normalized[key.toString()] = value;
    });
    return normalized;
  }
}
