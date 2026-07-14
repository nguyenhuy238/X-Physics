import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../progress/application/app_state.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<AppState>().checkDownloadedLessonsForUpdates(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lessons = state.downloadedLessons
        .map(state.loadOfflineLesson)
        .whereType<Lesson>()
        .toList();

    return XScaffold(
      title: 'Bài học offline',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SyncStatusBanner(state: state),
          if (state.chapters.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Tải cả chương',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...state.chapters.map(
              (chapter) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChapterDownloadTile(chapter: chapter),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Đã tải về máy',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (state.isCheckingOfflineUpdates) ...[
            const LinearProgressIndicator(minHeight: 3),
            const SizedBox(height: 8),
          ],
          if (lessons.isEmpty)
            const EmptyView(message: 'Chưa có bài học nào được tải offline.')
          else
            ...lessons.map(
              (lesson) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OfflineLessonTile(lesson: lesson),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfflineLessonTile extends StatefulWidget {
  const _OfflineLessonTile({required this.lesson});

  final Lesson lesson;

  @override
  State<_OfflineLessonTile> createState() => _OfflineLessonTileState();
}

class _OfflineLessonTileState extends State<_OfflineLessonTile> {
  bool _updating = false;

  Future<void> _update() async {
    setState(() => _updating = true);
    try {
      final updated = await context.read<AppState>().updateOfflineLesson(
        widget.lesson.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated
                  ? 'Đã cập nhật bản offline.'
                  : 'Bản offline hiện tại không bị thay đổi.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final updateAvailable = state.offlineLessonUpdateAvailable(
      widget.lesson.id,
    );
    final bytes = state.estimatedOfflineSizeBytes(widget.lesson.id);
    final subtitleParts = <String>[
      if (bytes != null) _formatSize(bytes),
      if (updateAvailable) 'Có bản cập nhật',
    ];

    return Card(
      child: ListTile(
        leading: Icon(
          updateAvailable
              ? Icons.system_update_alt_rounded
              : Icons.offline_pin_rounded,
          color: updateAvailable ? const Color(0xFFB8860B) : null,
        ),
        title: Text(
          widget.lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' • ')),
        trailing: updateAvailable
            ? _updating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip: 'Cập nhật bản offline',
                      icon: const Icon(Icons.update_rounded),
                      onPressed: state.effectiveOffline ? null : _update,
                    )
            : null,
        onTap: () => context.go('/lessons/${widget.lesson.id}'),
      ),
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  return '${(bytes / 1024).toStringAsFixed(1)} KB';
}

class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingSyncCount;
    if (pending == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_done_rounded, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Expanded(child: Text('Đã đồng bộ tiến độ đọc bài.')),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: Color(0xFFB8860B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.effectiveOffline
                  ? '$pending mục đang chờ đồng bộ (đang offline).'
                  : '$pending mục đang chờ đồng bộ.',
            ),
          ),
          if (!state.effectiveOffline)
            TextButton(
              onPressed: () => state.syncNow(),
              child: const Text('Đồng bộ ngay'),
            ),
        ],
      ),
    );
  }
}

class _ChapterDownloadTile extends StatefulWidget {
  const _ChapterDownloadTile({required this.chapter});
  final Chapter chapter;

  @override
  State<_ChapterDownloadTile> createState() => _ChapterDownloadTileState();
}

class _ChapterDownloadTileState extends State<_ChapterDownloadTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await context.read<AppState>().downloadChapter(widget.chapter.id);
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lessons = state.lessonsByChapter[widget.chapter.id];
    final total = lessons?.length;
    final downloaded =
        lessons
            ?.where((lesson) => state.downloadedLessons.contains(lesson.id))
            .length ??
        0;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.menu_book_rounded),
        title: Text(widget.chapter.title),
        subtitle: total == null
            ? const Text('Chạm nút tải để lấy danh sách bài học')
            : Text('Đã tải $downloaded/$total bài'),
        trailing: _downloading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                tooltip: 'Tải cả chương',
                icon: const Icon(Icons.download_for_offline_rounded),
                onPressed: (total != null && downloaded == total)
                    ? null
                    : _download,
              ),
      ),
    );
  }
}
