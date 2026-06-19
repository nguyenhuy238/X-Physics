import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../progress/application/app_state.dart';

class ChapterDetailScreen extends StatelessWidget {
  const ChapterDetailScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chapter = state.repository.chapterById(chapterId);
    final lessons = state.repository.lessonsByChapter(chapterId);
    return XScaffold(
      title: chapter.title,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: lessons.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final lesson = lessons[index];
          final done = state.completedLessons.contains(lesson.id);
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Color(chapter.color).withValues(alpha: .12),
                child: Icon(
                  done ? Icons.check_rounded : Icons.menu_book_rounded,
                  color: Color(chapter.color),
                ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${lesson.estimatedMinutes} phút • ${lesson.questions.length} câu quiz',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/lessons/${lesson.id}'),
            ),
          );
        },
      ),
    );
  }
}
