import 'package:hive/hive.dart';

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

  Box<Map> get _box => _injectedBox ?? Hive.box<Map>('offline_lessons');

  @override
  Lesson? getLesson(String lessonId) {
    final json = _box.get(lessonId);
    return json == null ? null : Lesson.fromJson(json);
  }

  @override
  List<String> getDownloadedLessonIds() => _box.keys.cast<String>().toList();

  @override
  Future<void> saveLesson(Lesson lesson) async {
    await _box.put(lesson.id, lesson.toJson());
  }
}
