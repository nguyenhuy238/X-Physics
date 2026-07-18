import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/unsaved_changes_dialog.dart';
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

    final state = context.read<AppState>();
    var questions = const <Question>[];
    String? loadError;
    try {
      questions = await state.loadQuestions(widget.lessonId);
      loadError = questions.isEmpty ? state.quizLoadError : null;
    } catch (error) {
      loadError = state.quizLoadError ?? state.readableError(error);
    }
    if (!mounted) {
      return;
    }
    final draft = state.quizDraftFor(widget.lessonId);
    final restoredAnswers = draft?.totalQuestions == questions.length
        ? Map<String, int>.from(draft!.answers)
        : <String, int>{};
    final restoredIndex = draft?.totalQuestions == questions.length
        ? draft!.currentIndex.clamp(0, questions.length - 1).toInt()
        : 0;
    final restoredSecondsLeft = draft?.totalQuestions == questions.length
        ? draft!.secondsLeft.clamp(0, QuizScreen.initialSeconds).toInt()
        : QuizScreen.initialSeconds;
    setState(() {
      _questions = questions;
      _isLoading = false;
      _errorMessage = loadError;
      answers
        ..clear()
        ..addAll(restoredAnswers);
      index = restoredIndex;
      secondsLeft = restoredSecondsLeft;
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
        _persistDraft();
        _submit(autoSubmitted: true);
      } else {
        setState(() => secondsLeft--);
        _persistDraft();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get _durationSeconds => (QuizScreen.initialSeconds - secondsLeft)
      .clamp(0, QuizScreen.initialSeconds)
      .toInt();

  Future<void> _submit({required bool autoSubmitted}) async {
    if (_isSubmitting || _hasSubmitted) {
      return;
    }
    _stopTimer();
    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = autoSubmitted
          ? 'Hết giờ, đang tự nộp bài...'
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
      context.read<AppState>().clearQuizDraft(widget.lessonId);
      context.go('/quiz/${widget.lessonId}/result', extra: attempt);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submitErrorMessage =
          context.read<AppState>().quizSubmitError ?? 'Không thể nộp bài quiz.';
    });
    _startTimer();
  }

  Future<void> _confirmAndSubmit() async {
    if (_isSubmitting) {
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nộp bài?'),
            content: const Text('Bạn chắc chắn muốn nộp bài quiz này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Xem lại'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Nộp bài'),
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
    if (_hasSubmitted || _questions.isEmpty || !_hasUserProgress) {
      return true;
    }
    return showUnsavedChangesDialog(
      context: context,
      title: 'Rời bài quiz?',
      message:
          'Bạn đang làm dở câu ${index + 1}/${_questions.length}. Nếu thoát, kết quả chưa lưu có thể bị mất.',
      stayLabel: 'Tiếp tục làm bài',
      leaveLabel: 'Thoát bài',
    );
  }

  bool get _hasUserProgress => answers.isNotEmpty || index > 0;

  void _persistDraft() {
    if (_hasSubmitted || _questions.isEmpty) {
      return;
    }
    context.read<AppState>().saveQuizDraft(
      lessonId: widget.lessonId,
      currentIndex: index,
      secondsLeft: secondsLeft,
      answers: answers,
      totalQuestions: _questions.length,
    );
  }

  void _setIndex(int value) {
    setState(() => index = value);
    _persistDraft();
  }

  void _selectAnswer(String questionId, int optionIndex) {
    setState(() => answers[questionId] = optionIndex);
    _persistDraft();
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
        child: LoadingView(message: 'Đang tải câu hỏi...'),
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
        child: EmptyView(message: 'Bài học này chưa có câu hỏi.'),
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
          context.read<AppState>().clearQuizDraft(widget.lessonId);
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/lessons/${widget.lessonId}');
          }
        }
      },
      child: XScaffold(
        title: 'Quiz',
        fallbackRoute: '/lessons/${widget.lessonId}',
        handleSystemBack: false,
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
                          'Câu ${index + 1}/${_questions.length}',
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
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (index + 1) / _questions.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < _questions.length; i++)
                          Expanded(
                            child: Container(
                              height: 5,
                              margin: EdgeInsets.only(
                                right: i == _questions.length - 1 ? 0 : 5,
                              ),
                              decoration: BoxDecoration(
                                color: i < index
                                    ? AppColors.success
                                    : i == index
                                    ? AppColors.primary
                                    : AppColors.border,
                                borderRadius: BorderRadius.circular(999),
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
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: _questionText(question.question),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: question.options.length,
                        itemBuilder: (context, optionIndex) {
                          final option = question.options[optionIndex];
                          final isSelected = selected == optionIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: .06)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _isSubmitting
                                    ? null
                                    : () => _selectAnswer(
                                        question.id,
                                        optionIndex,
                                      ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                      width: isSelected ? 1.6 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
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
                              : () => _setIndex(index - 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Trước'),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _isSubmitting || selected == null
                              ? null
                              : isLast
                              ? _confirmAndSubmit
                              : () => _setIndex(index + 1),
                          icon: Icon(
                            isLast
                                ? Icons.task_alt_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          label: Text(
                            _isSubmitting
                                ? 'Đang nộp...'
                                : isLast
                                ? 'Nộp bài'
                                : 'Tiếp tục',
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
