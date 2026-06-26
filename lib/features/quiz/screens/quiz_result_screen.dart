import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../progress/application/app_state.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final questions = state.questionsByLesson[lessonId] ?? const [];
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const XScaffold(
        title: 'Kết quả',
        child: Center(child: Text('Chưa có kết quả quiz.')),
      );
    }
    final questionsById = {for (final question in questions) question.id: question};
    return XScaffold(
      title: 'Kết quả',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    attempt.score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    '${attempt.correctCount}/${attempt.totalQuestions} câu đúng • +${attempt.coins} xu',
                  ),
                  if (attempt.newBadges.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Huy hiệu mới: ${attempt.newBadges.join(', ')}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final review in attempt.review)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionsById[review.questionId]?.question ??
                          'Câu hỏi ${review.questionId}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn chọn: ${_optionText(questionsById[review.questionId], review.selectedOption)}',
                    ),
                    Text(
                      'Đáp án đúng: ${_optionText(questionsById[review.questionId], review.correctOption)}',
                    ),
                    Text('Giải thích: ${review.explanation}'),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }

  String _optionText(Question? question, int? index) {
    if (question == null || index == null) {
      return 'Chưa chọn';
    }
    if (index < 0 || index >= question.options.length) {
      return 'Không hợp lệ';
    }
    return question.options[index];
  }
}
