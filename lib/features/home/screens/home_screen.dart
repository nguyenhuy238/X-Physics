import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh({bool showFeedback = false}) async {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    final state = context.read<AppState>();
    await state.loadHomeData();
    if (!mounted) {
      return;
    }
    setState(() => _isRefreshing = false);
    if (showFeedback) {
      final message = state.errorMessage == null
          ? 'Đã làm mới dữ liệu học tập.'
          : state.errorMessage!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;
    return XScaffold(
      title: 'X-Physics',
      child: state.isBusy && state.chapters.isEmpty
          ? const LoadingView(message: 'Đang tải dữ liệu học tập...')
          : state.errorMessage != null && state.chapters.isEmpty
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AppState>().loadHomeData(),
            )
          : state.chapters.isEmpty
          ? const EmptyView(message: 'Chưa có chương học nào.')
          : RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth > 720
                      ? 32.0
                      : 20.0;
                  final bottomPadding =
                      MediaQuery.viewPaddingOf(context).bottom +
                      XScaffold.bottomNavigationHeight +
                      24;
                  return ListView(
                    key: const PageStorageKey<String>('home-scroll'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    children: [
                      _HomeHero(userName: user?.name, state: state),
                      const SizedBox(height: 18),
                      _ContinueLearningCard(state: state),
                      const SizedBox(height: 18),
                      _SectionHeader(
                        title: 'Chương học',
                        actionLabel: 'Làm mới',
                        isLoading: _isRefreshing || state.isBusy,
                        onAction: () => _refresh(showFeedback: true),
                      ),
                      const SizedBox(height: 10),
                      _ChapterGrid(chapters: state.chapters),
                      if (user?.role != 'STUDENT') ...[
                        const SizedBox(height: 18),
                        _AdminEntryCard(state: state),
                      ],
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.userName, required this.state});

  final String? userName;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final overallProgress = _overallProgress(state);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hôm nay là ngày học',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào ${userName?.trim().isNotEmpty == true ? userName : 'học sinh'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.coins}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tiến độ tổng thể',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${(overallProgress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: overallProgress,
                  minHeight: 9,
                  borderRadius: BorderRadius.circular(999),
                  backgroundColor: Colors.white.withValues(alpha: .20),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeroMetric(
                      label: 'Bài đã học',
                      value: '${state.completedLessons.length}',
                    ),
                    _HeroMetric(
                      label: 'Chương',
                      value: '${state.chapters.length}',
                    ),
                    _HeroMetric(
                      label: 'Offline',
                      value: '${state.downloadedLessons.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _overallProgress(AppState state) {
    final loadedLessons = state.lessonsByChapter.values.fold<int>(
      0,
      (sum, lessons) => sum + lessons.length,
    );
    if (loadedLessons == 0) {
      return 0;
    }
    return (state.completedLessons.length / loadedLessons)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lessons = state.lessonsById.values.toList()
      ..sort((left, right) => left.orderIndex.compareTo(right.orderIndex));
    final nextLesson = lessons
        .where((lesson) => !state.completedLessons.contains(lesson.id))
        .firstOrNull;
    final fallbackLesson = lessons.firstOrNull;
    final targetLesson = nextLesson ?? fallbackLesson;

    if (targetLesson == null) {
      final firstChapter = state.chapters.firstOrNull;
      if (firstChapter == null || state.completedLessons.isNotEmpty) {
        return const SizedBox.shrink();
      }
      return AppCard(
        onTap: () => context.push('/chapters/${firstChapter.id}'),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: AppColors.primary, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bắt đầu bài đầu tiên',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstChapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }

    final completed = state.completedLessons.contains(targetLesson.id);
    final progress = completed ? 1.0 : 0.0;
    return AppCard(
      onTap: () => context.push('/lessons/${targetLesson.id}'),
      padding: const EdgeInsets.all(18),
      child: Semantics(
        button: true,
        label:
            'Tiếp tục học ${targetLesson.title}, tiến độ ${(progress * 100).round()} phần trăm',
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    completed ? 'Ôn lại bài học' : 'Tiếp tục học',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    targetLesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: progress),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.push('/lessons/${targetLesson.id}'),
              child: const Text('Học tiếp'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.isLoading = false,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        TextButton.icon(
          onPressed: isLoading ? null : onAction,
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(isLoading ? 'Đang làm mới' : actionLabel),
        ),
      ],
    );
  }
}

class _ChapterGrid extends StatelessWidget {
  const _ChapterGrid({required this.chapters});

  final List<Chapter> chapters;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
            ? 2
            : 1;
        return GridView.builder(
          itemCount: chapters.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: columns == 1 ? 2.75 : 1.55,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final chapter = chapters[index];
            final progress = state.chapterProgress(chapter.id);
            final color = Color(chapter.color);
            return Semantics(
              button: true,
              label:
                  '${chapter.title}, ${chapter.lessonCount} bài học, tiến độ ${(progress * 100).round()} phần trăm',
              child: AppCard(
                onTap: () => context.push('/chapters/${chapter.id}'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  chapter.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chapter.lessonCount > 0
                                ? '${chapter.lessonCount} bài học'
                                : chapter.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  borderRadius: BorderRadius.circular(999),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(progress * 100).round()}%',
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminEntryCard extends StatelessWidget {
  const _AdminEntryCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin/Teacher dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '${state.chapters.length} chương đang lấy từ API thật.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/admin'),
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text('Vào Admin Dashboard'),
          ),
        ],
      ),
    );
  }
}
