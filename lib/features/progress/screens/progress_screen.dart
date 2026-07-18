import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/app_state.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.progressDashboard == null &&
          !state.isProgressDashboardLoading) {
        state.loadProgressDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final dashboard = state.progressDashboard;
    final error = state.progressDashboardError;

    return XScaffold(
      title: 'Tiến độ học tập',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: state.isProgressDashboardLoading ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (state.isProgressDashboardLoading && dashboard == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && dashboard == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ErrorView(
                      message: error,
                      onRetry: context
                          .read<AppState>()
                          .refreshProgressDashboard,
                    ),
                  ),
                ],
              );
            }
            if (dashboard == null || dashboard.isEmpty) {
              return const _RefreshableEmptyState();
            }
            return _DashboardView(dashboard: dashboard);
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    final hadData = state.progressDashboard != null;
    await state.refreshProgressDashboard();
    if (!mounted || !hadData || state.progressDashboardError == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.progressDashboardError!)));
  }
}

class _RefreshableEmptyState extends StatelessWidget {
  const _RefreshableEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: const EmptyView(
            message:
                'Chưa có tiến độ học tập. Hãy hoàn thành một bài quiz đầu tiên.',
          ),
        ),
      ],
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.dashboard});

  final ProgressDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey<String>('progress-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _OverallCard(dashboard: dashboard),
        const SizedBox(height: 16),
        _RecentAttemptsChart(attempts: dashboard.recentAttempts),
        const SizedBox(height: 16),
        Text(
          'Tiến độ từng chương',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...dashboard.chapterProgress.map(_ChapterProgressTile.new),
      ],
    );
  }
}

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.dashboard});

  final ProgressDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final progressValue = (dashboard.overallProgress / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${dashboard.overallProgress.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progressValue),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Bài đã xong',
                  value:
                      '${dashboard.completedLessons}/${dashboard.totalLessons}',
                ),
                _MetricChip(
                  label: 'Điểm TB',
                  value: dashboard.averageScore.toStringAsFixed(2),
                ),
                _MetricChip(label: 'Xu', value: '${dashboard.totalCoins}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ChapterProgressTile extends StatelessWidget {
  const _ChapterProgressTile(this.chapter);

  final ChapterProgressSummary chapter;

  @override
  Widget build(BuildContext context) {
    final progressValue = (chapter.progressPercent / 100).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chapter.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  '${chapter.completedLessons}/${chapter.totalLessons}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progressValue),
          ],
        ),
      ),
    );
  }
}

class _RecentAttemptsChart extends StatelessWidget {
  const _RecentAttemptsChart({required this.attempts});

  final List<RecentQuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final chronological = attempts.reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5 quiz gần nhất',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: chronological.isEmpty
                  ? const Center(child: Text('Chưa có lần làm quiz nào.'))
                  : BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: 10,
                        barGroups: [
                          for (var i = 0; i < chronological.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: chronological[i].score,
                                  width: 18,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                        ],
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 2,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= chronological.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: 48,
                                    child: Text(
                                      chronological[index].lessonTitle.isEmpty
                                          ? 'Quiz ${index + 1}'
                                          : chronological[index].lessonTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
