import '../../../shared/models/x_models.dart';

abstract class LessonRepository {
  Future<List<Lesson>> getLessonsByChapter(String chapterId);

  Future<Lesson> getLesson(String id);

  Future<List<Question>> getQuestions(String lessonId);
}
