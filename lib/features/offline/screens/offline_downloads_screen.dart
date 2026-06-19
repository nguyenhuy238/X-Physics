import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../progress/application/app_state.dart';

class OfflineDownloadsScreen extends StatelessWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lessons = state.downloadedLessons
        .map(state.repository.lessonById)
        .toList();
    return XScaffold(
      title: 'Bài học offline',
      child: lessons.isEmpty
          ? const Center(child: Text('Chưa có bài học nào được tải offline.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: lessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) => Card(
                child: ListTile(
                  leading: const Icon(Icons.offline_pin_rounded),
                  title: Text(
                    lessons[index].title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => context.go('/lessons/${lessons[index].id}'),
                ),
              ),
            ),
    );
  }
}
