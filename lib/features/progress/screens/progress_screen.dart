import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../application/app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final total = state.lessonsByChapter.values.fold<int>(
      0,
      (sum, lessons) => sum + lessons.length,
    );
    final completed = state.completedLessons.length;
    return XScaffold(
      title: 'Tien do hoc tap',
      child: state.errorMessage != null && total == 0
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AppState>().loadHomeData(),
            )
          : total == 0
          ? const EmptyView(
              message: 'Mở một chương học để tải danh sách bài và tiến độ.',
            )
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$completed / $total bài đã hoàn thành',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
