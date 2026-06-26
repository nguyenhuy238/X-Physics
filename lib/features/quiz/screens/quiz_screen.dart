import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lessonId});
  final String lessonId;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int secondsLeft = 300;
  final answers = <String, int>{};
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadQuestions(widget.lessonId);
      }
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secondsLeft <= 1) {
        _submit();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    timer?.cancel();
    final attempt = await context.read<AppState>().submitQuiz(
      widget.lessonId,
      answers,
    );
    if (attempt != null && mounted) {
      context.go('/quiz/${widget.lessonId}/result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final questions = state.questionsByLesson[widget.lessonId] ?? const [];
    if (state.isBusy && questions.isEmpty) {
      return const XScaffold(
        title: 'Quiz',
        child: LoadingView(message: 'Đang tải câu hỏi...'),
      );
    }
    if (state.errorMessage != null && questions.isEmpty) {
      return XScaffold(
        title: 'Quiz',
        child: ErrorView(
          message: state.errorMessage!,
          onRetry: () => context.read<AppState>().loadQuestions(widget.lessonId),
        ),
      );
    }
    if (questions.isEmpty) {
      return const XScaffold(
        title: 'Quiz',
        child: EmptyView(message: 'Bài học này chưa có câu hỏi.'),
      );
    }
    if (index >= questions.length) {
      index = questions.length - 1;
    }
    final question = questions[index];
    final selected = answers[question.id];
    final isLast = index == questions.length - 1;
    return XScaffold(
      title: 'Quiz',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Câu ${index + 1}/${questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => setState(() => answers[question.id] = i),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            selected == i
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: selected == i
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(question.options[i])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      if (isLast) {
                        final ok =
                            await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Nộp bài?'),
                                content: const Text(
                                  'Bạn chắc chắn muốn nộp bài quiz này?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Xem lại'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Nộp bài'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                        if (ok) {
                          await _submit();
                        }
                      } else {
                        setState(() => index++);
                      }
                    },
              child: Text(isLast ? 'Nộp bài' : 'Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }
}
