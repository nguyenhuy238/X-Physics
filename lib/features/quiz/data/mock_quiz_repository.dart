import '../../../shared/models/x_models.dart';
import '../../lessons/data/mock_repository.dart';
import 'quiz_repository.dart';

class MockQuizRepository implements QuizRepository {
  MockQuizRepository({MockRepository? repository})
    : _repository = repository ?? MockRepository();

  final MockRepository _repository;

  @override
  Future<List<Question>> getQuestions(String lessonId) async =>
      _repository.lessonById(lessonId).questions;

  @override
  Future<QuizAttempt> submitQuiz(
    String lessonId,
    Map<String, int> answers,
  ) async {
    final lesson = _repository.lessonById(lessonId);
    final correct = lesson.questions
        .where((question) => answers[question.id] == question.correctOption)
        .length;
    final score = correct / lesson.questions.length * 10;
    return QuizAttempt(
      lessonId: lessonId,
      answers: answers,
      score: score,
      coins: score >= 8 ? 30 : 10,
      newBadges: score == 10 ? const ['Diem tuyet doi'] : const [],
    );
  }
}
