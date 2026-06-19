import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../progress/application/app_state.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lesson = state.repository.lessonById(lessonId);
    final attempt = state.lastAttempt;
    if (attempt == null) {
      return const XScaffold(
        title: 'Kết quả',
        child: Center(child: Text('Chưa có kết quả quiz.')),
      );
    }
    final correct = lesson.questions
        .where((q) => attempt.answers[q.id] == q.correctOption)
        .length;
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
                    '$correct/${lesson.questions.length} câu đúng • +${attempt.coins} xu',
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
          for (final question in lesson.questions)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn chọn: ${question.options[attempt.answers[question.id] ?? 0]}',
                    ),
                    Text(
                      'Đáp án đúng: ${question.options[question.correctOption]}',
                    ),
                    Text('Giải thích: ${question.explanation}'),
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
}
