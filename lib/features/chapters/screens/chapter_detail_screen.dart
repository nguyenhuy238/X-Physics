import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class ChapterDetailScreen extends StatefulWidget {
  const ChapterDetailScreen({super.key, required this.chapterId});
  final String chapterId;

  @override
  State<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends State<ChapterDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadChapterDetail(widget.chapterId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chapter = state.chapterById(widget.chapterId);
    final lessons = state.lessonsByChapter[widget.chapterId] ?? const [];
    return XScaffold(
      title: chapter?.title ?? 'Chương học',
      child: state.isBusy && lessons.isEmpty
          ? const LoadingView(message: 'Đang tải bài học...')
          : state.errorMessage != null && lessons.isEmpty
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () =>
                  context.read<AppState>().loadChapterDetail(widget.chapterId),
            )
          : lessons.isEmpty
          ? const EmptyView(message: 'Chương này chưa có bài học.')
          : ListView.separated(
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
                backgroundColor: Color(
                  chapter?.color ?? 0xFF2563EB,
                ).withValues(alpha: .12),
                child: Icon(
                  done ? Icons.check_rounded : Icons.menu_book_rounded,
                  color: Color(chapter?.color ?? 0xFF2563EB),
                ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text(
                '${lesson.estimatedMinutes} phút',
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
