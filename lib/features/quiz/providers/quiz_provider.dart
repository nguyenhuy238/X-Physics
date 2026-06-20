import 'package:flutter/foundation.dart';

import '../../../shared/models/x_models.dart';
import '../data/quiz_repository.dart';

class QuizProvider extends ChangeNotifier {
  QuizProvider(this._repository);

  final QuizRepository _repository;
  List<Question> questions = const [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadQuestions(String lessonId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      questions = await _repository.getQuestions(lessonId);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
