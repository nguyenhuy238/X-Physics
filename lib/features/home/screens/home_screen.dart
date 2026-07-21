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
import '../../notifications/widgets/notification_icon.dart';
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
      showAppBar: false,
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
                  final contentWidth = constraints.maxWidth >= 720
                      ? 430.0
                      : constraints.maxWidth;
                  final horizontalPadding = constraints.maxWidth >= 720
                      ? 20.0
                      : 12.0;
                  final bottomPadding =
                      MediaQuery.viewPaddingOf(context).bottom +
                      XScaffold.bottomNavigationHeight +
                      18;
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
                      Center(
                        child: ConstrainedBox(
                          key: const ValueKey('home-content'),
                          constraints: BoxConstraints(maxWidth: contentWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              HomeHeroHeader(
                                userName: user?.name,
                                state: state,
                              ),
                              const SizedBox(height: 18),
                              _SectionHeader(
                                title: 'Chương học',
                                actionLabel: 'Xem tất cả',
                                isLoading: _isRefreshing || state.isBusy,
                                onAction: () => _refresh(showFeedback: true),
                              ),
                              const SizedBox(height: 10),
                              _ChapterList(chapters: state.chapters),
                              if (user?.role != 'STUDENT') ...[
                                const SizedBox(height: 18),
                                _AdminEntryCard(state: state),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.userName,
    required this.state,
  });

  final String? userName;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final name = userName?.trim().isNotEmpty == true
        ? userName!.trim()
        : 'học sinh';
    return Container(
      key: const ValueKey('home-hero-header'),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hôm nay là ngày học!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .76),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chào $name 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _CoinPill(coins: _dashboardCoins(state)),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const NotificationIcon(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OverallProgressCard(state: state),
        ],
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: AppColors.secondary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$coins',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class OverallProgressCard extends StatelessWidget {
  const OverallProgressCard({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.progressDashboard;
    final isLoading = dashboard == null && state.isProgressDashboardLoading;
    final progress = ((dashboard?.overallProgress ?? 0) / 100)
        .clamp(0.0, 1.0)
        .toDouble();
    final completedLessons =
        dashboard?.completedLessons ?? state.completedLessons.length;
    final averageScore = dashboard?.averageScore ?? 0;
    final coins = _dashboardCoins(state);
    final streakDays = _streakDays(state);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
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
                    fontSize: 13,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.secondary,
                  ),
                )
              else
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: isLoading ? null : progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: Colors.white.withValues(alpha: .22),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              HomeStatisticItem(label: 'Bài học', value: '$completedLessons'),
              HomeStatisticItem(
                label: 'Điểm TB',
                value: _formatScore(averageScore),
              ),
              HomeStatisticItem(label: 'Xu', value: '$coins'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.warning,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays ngày',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeStatisticItem extends StatelessWidget {
  const HomeStatisticItem({
    super.key,
    required this.label,
    required this.value,
  });

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(
          onPressed: isLoading ? null : onAction,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(actionLabel),
        ),
      ],
    );
  }
}

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.chapters});

  final List<Chapter> chapters;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ListView.separated(
      itemCount: chapters.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        final progressSummary = state.progressDashboard?.chapterProgress
            .where((item) => item.chapterId == chapter.id)
            .firstOrNull;
        final progressIsLoading =
            state.progressDashboard == null && state.isProgressDashboardLoading;
        final progress = progressSummary == null
            ? state.chapterProgress(chapter.id)
            : (progressSummary.progressPercent / 100)
                  .clamp(0.0, 1.0)
                  .toDouble();
        return ChapterLearningCard(
          chapter: chapter,
          index: index,
          progress: progress,
          progressIsLoading: progressIsLoading,
          targetRoute: _chapterTargetRoute(state, chapter, progress),
        );
      },
    );
  }
}

class ChapterLearningCard extends StatelessWidget {
  const ChapterLearningCard({
    super.key,
    required this.chapter,
    required this.index,
    required this.progress,
    required this.progressIsLoading,
    required this.targetRoute,
  });

  final Chapter chapter;
  final int index;
  final double progress;
  final bool progressIsLoading;
  final String targetRoute;

  @override
  Widget build(BuildContext context) {
    final style = _chapterStyle(chapter, index);
    final isComplete = progress >= .999;
    final buttonText = isComplete ? 'Ôn lại' : 'Tiếp tục học';
    return Semantics(
      button: true,
      label:
          '${chapter.title}, ${chapter.lessonCount} bài học, tiến độ ${(progress * 100).round()} phần trăm',
      child: AppCard(
        key: ValueKey('chapter-learning-card-${chapter.id}'),
        onTap: () => context.go(targetRoute),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(style.icon, color: style.color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${chapter.lessonCount} bài học',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressIsLoading ? null : progress,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: AppColors.border.withValues(alpha: .75),
                    valueColor: AlwaysStoppedAnimation<Color>(style.color),
                  ),
                ),
                const SizedBox(width: 10),
                if (progressIsLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: style.color,
                    ),
                  )
                else
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${(progress * 100).round()}%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: style.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  elevation: 0,
                  backgroundColor: style.buttonBackground,
                  foregroundColor: style.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => context.go(targetRoute),
                icon: Icon(
                  isComplete ? Icons.replay_rounded : Icons.play_arrow_rounded,
                  size: 14,
                ),
                label: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

class _ChapterVisualStyle {
  const _ChapterVisualStyle({
    required this.color,
    required this.background,
    required this.buttonBackground,
    required this.icon,
  });

  final Color color;
  final Color background;
  final Color buttonBackground;
  final IconData icon;
}

_ChapterVisualStyle _chapterStyle(Chapter chapter, int index) {
  final palette = [
    const Color(0xFF2563EB),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFF06B6D4),
    const Color(0xFF22C55E),
    const Color(0xFFEF4444),
  ];
  final icons = [
    Icons.rocket_launch_rounded,
    Icons.balance_rounded,
    Icons.bolt_rounded,
    Icons.science_rounded,
    Icons.auto_stories_rounded,
    Icons.explore_rounded,
  ];
  final seed = chapter.id.hashCode.abs() + index;
  final color = palette[seed % palette.length];
  return _ChapterVisualStyle(
    color: color,
    background: color.withValues(alpha: .13),
    buttonBackground: color.withValues(alpha: .14),
    icon: icons[seed % icons.length],
  );
}

String _chapterTargetRoute(AppState state, Chapter chapter, double progress) {
  final lessons =
      (state.lessonsByChapter[chapter.id] ?? const <Lesson>[]).toList()
        ..sort((left, right) => left.orderIndex.compareTo(right.orderIndex));
  if (lessons.isEmpty) {
    return '/chapters/${chapter.id}';
  }
  if (progress >= .999) {
    return '/lessons/${lessons.first.id}';
  }
  final nextLesson = lessons
      .where((lesson) => !state.completedLessons.contains(lesson.id))
      .firstOrNull;
  return '/lessons/${(nextLesson ?? lessons.first).id}';
}

int _dashboardCoins(AppState state) {
  final dashboardCoins = state.progressDashboard?.totalCoins;
  if (dashboardCoins != null && dashboardCoins > 0) {
    return dashboardCoins;
  }
  return state.coins;
}

int _streakDays(AppState state) {
  final profile = state.profileSummary;
  if (profile == null) {
    return 0;
  }
  final streakBadges = [
    ...profile.earnedBadges,
    ...profile.lockedBadges,
  ].where((badge) => badge.ruleKey.toLowerCase().contains('streak'));
  if (streakBadges.isEmpty) {
    return 0;
  }
  return streakBadges
      .map(
        (badge) =>
            badge.isEarned ? badge.progressTarget : badge.progressCurrent,
      )
      .fold<int>(0, (best, value) => value > best ? value : best);
}

String _formatScore(double score) {
  if (score == score.roundToDouble()) {
    return score.toStringAsFixed(0);
  }
  return score.toStringAsFixed(1);
}
