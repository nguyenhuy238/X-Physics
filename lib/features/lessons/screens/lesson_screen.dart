import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
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

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (!scroll.hasClients || scroll.position.maxScrollExtent == 0) {
        return;
      }
      setState(
        () => progress = (scroll.offset / scroll.position.maxScrollExtent)
            .clamp(0, 1),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final Lesson? lesson = state.loadLesson(widget.lessonId);
    if (lesson == null) {
      return XScaffold(
        title: 'Không có dữ liệu offline',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Bài học này chưa được tải offline. Hãy bật mạng lại hoặc tải bài trước khi học offline.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }
    return XScaffold(
      title: lesson.title,
      actions: [
        IconButton(
          tooltip: 'Tải bài học',
          onPressed: () async {
            await context.read<AppState>().downloadLesson(lesson);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu bài học để đọc offline.')),
              );
            }
          },
          icon: Icon(
            state.downloadedLessons.contains(lesson.id)
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
                MarkdownBody(data: lesson.content, selectable: true),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Center(
                      child: Math.tex(
                        lesson.formulaLatex,
                        textStyle: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FormulaSimulationWidget(config: lesson.simulation),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/quiz/${lesson.id}'),
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
