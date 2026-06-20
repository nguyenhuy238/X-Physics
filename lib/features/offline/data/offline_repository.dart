import '../../../shared/models/x_models.dart';

abstract class OfflineRepository {
  Future<void> saveLesson(Lesson lesson);

  Future<Lesson?> getLesson(String lessonId);

  Future<List<String>> getDownloadedLessonIds();
}
