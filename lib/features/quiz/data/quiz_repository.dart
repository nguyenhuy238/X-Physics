import '../../../shared/models/x_models.dart';

abstract class QuizRepository {
  Future<List<Question>> getQuestions(String lessonId);

  Future<QuizAttempt> submitQuiz(String lessonId, Map<String, int> answers);
}
