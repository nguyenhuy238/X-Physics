import '../../../shared/models/x_models.dart';
import 'lesson_repository.dart';
import 'mock_repository.dart';

class MockLessonRepository implements LessonRepository {
  MockLessonRepository({MockRepository? repository})
    : _repository = repository ?? MockRepository();

  final MockRepository _repository;

  @override
  Future<Lesson> getLesson(String id) async => _repository.lessonById(id);

  @override
  Future<List<Lesson>> getLessonsByChapter(String chapterId) async =>
      _repository.lessonsByChapter(chapterId);

  @override
  Future<List<Question>> getQuestions(String lessonId) async =>
      _repository.lessonById(lessonId).questions;
}
