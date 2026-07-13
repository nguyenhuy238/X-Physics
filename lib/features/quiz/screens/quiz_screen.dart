import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lessonId});

  static const initialSeconds = 300;

  final String lessonId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int index = 0;
  int secondsLeft = QuizScreen.initialSeconds;
  final answers = <String, int>{};

  Timer? _timer;
  List<Question> _questions = const [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;
  String? _errorMessage;
  String? _submitErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  @override
  void didUpdateWidget(covariant QuizScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessonId != widget.lessonId) {
      answers.clear();
      _questions = const [];
      _hasSubmitted = false;
      _isSubmitting = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    _stopTimer();
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _submitErrorMessage = null;
        secondsLeft = QuizScreen.initialSeconds;
        index = 0;
        answers.clear();
      });
    }

    final questions = await context.read<AppState>().loadQuestions(
      widget.lessonId,
    );
    if (!mounted) {
      return;
    }
    final stateError = context.read<AppState>().quizLoadError;
    setState(() {
      _questions = questions;
      _isLoading = false;
      _errorMessage = questions.isEmpty ? stateError : null;
    });
    if (questions.isNotEmpty) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_timer != null || _hasSubmitted || _isSubmitting) {
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isSubmitting || _hasSubmitted) {
        return;
      }
      if (secondsLeft <= 1) {
        setState(() => secondsLeft = 0);
        _submit(autoSubmitted: true);
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get _durationSeconds => (QuizScreen.initialSeconds - secondsLeft).clamp(
    0,
    QuizScreen.initialSeconds,
  );

  Future<void> _submit({required bool autoSubmitted}) async {
    if (_isSubmitting || _hasSubmitted) {
      return;
    }
    _stopTimer();
    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = autoSubmitted
          ? 'Het gio, dang tu nop bai...'
          : null;
    });

    final attempt = await context.read<AppState>().submitQuiz(
      widget.lessonId,
      answers,
      durationSeconds: _durationSeconds,
    );
    if (!mounted) {
      return;
    }
    if (attempt != null) {
      _hasSubmitted = true;
      context.go('/quiz/${widget.lessonId}/result', extra: attempt);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submitErrorMessage =
          context.read<AppState>().quizSubmitError ?? 'Khong the nop bai quiz.';
    });
  }

  Future<void> _confirmAndSubmit() async {
    if (_isSubmitting) {
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nop bai?'),
            content: const Text('Ban chac chan muon nop bai quiz nay?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Xem lai'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nop bai'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && mounted) {
      await _submit(autoSubmitted: false);
    }
  }

  Future<bool> _confirmLeave() async {
    if (_hasSubmitted || _questions.isEmpty) {
      return true;
    }
    final leave =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Roi bai quiz?'),
            content: const Text('Cac cau tra loi chua nop se khong duoc luu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('O lai'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Roi bai'),
              ),
            ],
          ),
        ) ??
        false;
    return leave;
  }

  Widget _questionText(String value) {
    final text = value.trim();
    final looksLikeLatex =
        text.contains(r'\') || (text.startsWith(r'$') && text.endsWith(r'$'));
    if (!looksLikeLatex) {
      return Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      );
    }
    return Math.tex(
      text.replaceAll(r'$', ''),
      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      onErrorFallback: (_) => Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const XScaffold(
        title: 'Quiz',
        child: LoadingView(message: 'Dang tai cau hoi...'),
      );
    }
    if (_errorMessage != null && _questions.isEmpty) {
      return XScaffold(
        title: 'Quiz',
        child: ErrorView(message: _errorMessage!, onRetry: _loadQuestions),
      );
    }
    if (_questions.isEmpty) {
      return const XScaffold(
        title: 'Quiz',
        child: EmptyView(message: 'Bai hoc nay chua co cau hoi.'),
      );
    }
    if (index >= _questions.length) {
      index = _questions.length - 1;
    }

    final question = _questions[index];
    final selected = answers[question.id];
    final isLast = index == _questions.length - 1;
    final isStaleQuizError =
        _submitErrorMessage?.contains('Bộ câu hỏi đã được cập nhật') == true ||
        _submitErrorMessage?.contains('question set') == true;
    final timerColor = secondsLeft <= 30
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: _hasSubmitted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        if (await _confirmLeave() && context.mounted) {
          context.pop();
        }
      },
      child: XScaffold(
        title: 'Quiz',
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth > 700
                  ? 48.0
                  : 20.0;
              return Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Cau ${index + 1}/${_questions.length}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const Spacer(),
                        Chip(
                          avatar: Icon(
                            Icons.timer_rounded,
                            color: timerColor,
                            size: 18,
                          ),
                          label: Text(
                            '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: timerColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_submitErrorMessage != null) ...[
                      const SizedBox(height: 12),
                      MaterialBanner(
                        content: Text(_submitErrorMessage!),
                        actions: [
                          if (isStaleQuizError)
                            TextButton(
                              onPressed: _isSubmitting ? null : _loadQuestions,
                              child: const Text('Tải lại quiz'),
                            ),
                          TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submit(autoSubmitted: false),
                            child: const Text('Thu lai'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _questionText(question.question),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, optionIndex) {
                          final option = question.options[optionIndex];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () =>
                                            answers[question.id] = optionIndex,
                                      ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected == optionIndex
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: selected == optionIndex
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(option)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSubmitting || index == 0
                              ? null
                              : () => setState(() => index--),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Truoc'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _isSubmitting || selected == null
                              ? null
                              : isLast
                              ? _confirmAndSubmit
                              : () => setState(() => index++),
                          icon: Icon(
                            isLast
                                ? Icons.task_alt_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          label: Text(
                            _isSubmitting
                                ? 'Dang nop...'
                                : isLast
                                ? 'Nop bai'
                                : 'Tiep tuc',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
