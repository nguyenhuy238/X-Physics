import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thong ke')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const LoadingWidget();
          }
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: provider.fetchStatistics);
          }

          final statistics = provider.lastStatistics;
          if (statistics == null) {
            return const EmptyView(message: 'Chua co du lieu thong ke');
          }

          final trend = statistics['activeTrend'] as List<dynamic>? ?? <dynamic>[];
          final difficult = statistics['difficultLessons'] as List<dynamic>? ?? <dynamic>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Hoc vien', value: '${statistics['activeStudents'] ?? 0}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: 'Huy hieu', value: '${statistics['totalBadgesAwarded'] ?? 0}')),
                ],
              ),
              const SizedBox(height: 24),
              Text('Hoc vien hoat dong', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _ActiveStudentsChart(trend: trend),
              const SizedBox(height: 24),
              Text('Ti le hoan thanh: ${((statistics['completionRate'] ?? 0) * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Bai hoc kho nhat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (difficult.isEmpty)
                const EmptyView(message: 'Chua co du lieu')
              else
                ...difficult.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text('${item['title']}'),
                      trailing: Text('Sai: ${item['wrongCount']}'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _ActiveStudentsChart extends StatelessWidget {
  const _ActiveStudentsChart({required this.trend});

  final List<dynamic> trend;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < trend.length; i++) {
      final point = trend[i];
      spots.add(FlSpot(i.toDouble(), (point['activeStudents'] ?? 0).toDouble()));
      final raw = point['date']?.toString() ?? '';
      labels.add(raw.length >= 5 ? raw.substring(5) : raw);
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          barGroups: spots
              .map(
                (spot) => BarChartGroupData(
                  x: spot.x.toInt(),
                  barRods: [BarChartRodData(toY: spot.y, color: Theme.of(context).colorScheme.primary)],
                ),
              )
              .toList(),
          titlesData: FlTitlesData(
            bottom: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(labels[index], style: const TextStyle(fontSize: 10)),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
            ),
            left: const FlTitlesData(show: false),
            top: const FlTitlesData(show: false),
            right: const FlTitlesData(show: false),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
