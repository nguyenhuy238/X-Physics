import 'package:hive/hive.dart';

import '../../../shared/models/x_models.dart';
import '../data/offline_repository.dart';

class OfflineService implements OfflineRepository {
  OfflineService({Box<Map>? box})
    : _box = box ?? Hive.box<Map>('offline_lessons');

  final Box<Map> _box;

  @override
  Future<Lesson?> getLesson(String lessonId) async {
    final json = _box.get(lessonId);
    return json == null ? null : Lesson.fromJson(json);
  }

  @override
  Future<List<String>> getDownloadedLessonIds() async =>
      _box.keys.cast<String>().toList();

  @override
  Future<void> saveLesson(Lesson lesson) async {
    await _box.put(lesson.id, lesson.toJson());
  }
}
