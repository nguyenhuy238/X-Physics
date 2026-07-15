import '../../../shared/models/x_models.dart';

class QuizResultModel {
  const QuizResultModel({
    required this.lessonId,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.coinsEarned,
    required this.newBadges,
  });

  final String lessonId;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final int coinsEarned;
  final List<XBadge> newBadges;
}
