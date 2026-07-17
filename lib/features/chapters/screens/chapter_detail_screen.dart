import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
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
                final downloaded = state.downloadedLessons.contains(lesson.id);
                final color = Color(chapter?.color ?? 0xFF2563EB);
                return AppCard(
                  onTap: () => context.go('/lessons/${lesson.id}'),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.menu_book_rounded,
                          color: done ? AppColors.success : color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _LessonChip(
                                  icon: Icons.schedule_rounded,
                                  label: '${lesson.estimatedMinutes} phút',
                                ),
                                _LessonChip(
                                  icon: done
                                      ? Icons.check_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  label: done ? 'Đã học' : 'Học tiếp',
                                  color: done ? AppColors.success : color,
                                ),
                                if (downloaded)
                                  const _LessonChip(
                                    icon: Icons.offline_pin_rounded,
                                    label: 'Offline',
                                    color: AppColors.info,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
