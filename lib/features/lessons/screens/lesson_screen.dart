import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/formula_simulation_widget.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lessonId});
  final String lessonId;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final scroll = ScrollController();
  double progress = 0;
  Lesson? lesson;
  bool _readingProgressReported = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLesson);
    scroll.addListener(() {
      if (!scroll.hasClients || scroll.position.maxScrollExtent == 0) {
        return;
      }
      setState(
        () => progress = (scroll.offset / scroll.position.maxScrollExtent)
            .clamp(0, 1),
      );
      // Report reading progress once the student has effectively reached
      // the end of the lesson. Queued locally when offline and synced
      // later — see AppState.updateReadingProgress / docs/OFFLINE_FLOW.md.
      if (progress >= 0.9 && !_readingProgressReported) {
        _readingProgressReported = true;
        context.read<AppState>().updateReadingProgress(
          widget.lessonId,
          (progress * 100).round(),
        );
      }
    });
  }

  Future<void> _loadLesson() async {
    final loaded = await context.read<AppState>().loadLessonDetail(
      widget.lessonId,
    );
    if (mounted) {
      setState(() => lesson = loaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currentLesson = lesson ?? state.lessonsById[widget.lessonId];
    if (state.isBusy && currentLesson == null) {
      return const XScaffold(
        title: 'Bài học',
        child: LoadingView(message: 'Đang tải bài học...'),
      );
    }
    if (currentLesson == null) {
      return XScaffold(
        title: state.effectiveOffline ? 'Không có dữ liệu offline' : 'Bài học',
        child: ErrorView(
          message: state.errorMessage ??
              'Bài học này chưa có dữ liệu. Hãy kiểm tra kết nối hoặc tải bài offline trước.',
          onRetry: _loadLesson,
        ),
      );
    }
    return XScaffold(
      title: currentLesson.title,
      actions: [
        IconButton(
          tooltip: 'Tải bài học',
          onPressed: () async {
            await context.read<AppState>().downloadLesson(currentLesson.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu bài học để đọc offline.')),
              );
            }
          },
          icon: Icon(
            state.downloadedLessons.contains(currentLesson.id)
                ? Icons.download_done_rounded
                : Icons.download_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Bookmark',
          onPressed: () {},
          icon: const Icon(Icons.bookmark_border_rounded),
        ),
      ],
      child: Column(
        children: [
          LinearProgressIndicator(value: progress, minHeight: 5),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                MarkdownBody(data: currentLesson.content, selectable: true),
                const SizedBox(height: 16),
                if (currentLesson.formulaLatex.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Center(
                        child: Math.tex(
                          currentLesson.formulaLatex,
                          textStyle: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                if (currentLesson.simulation.title.isNotEmpty)
                  FormulaSimulationWidget(config: currentLesson.simulation),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/quiz/${currentLesson.id}'),
                  icon: const Icon(Icons.quiz_rounded),
                  label: const Text('Làm bài tập'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
