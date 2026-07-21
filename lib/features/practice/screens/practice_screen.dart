import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _random = Random();
  var _items = <_PracticeItem>[];
  final _answers = <String, int>{};
  DateTime? _startedAt;
  bool _loading = true;
  bool _submitted = false;
  String? _error;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await context.read<AppState>().loadPracticeQuestions(
        widget.lessonId,
        notify: false,
      );
      if (!mounted) return;
      setState(() {
        _items = _shuffleQuestions(questions);
        _answers.clear();
        _index = 0;
        _submitted = false;
        _startedAt = DateTime.now().toUtc();
        _loading = false;
        _error = questions.isEmpty
            ? 'Bài học này chưa có câu hỏi luyện tập.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      final state = context.read<AppState>();
      setState(() {
        _loading = false;
        _error = state.practiceLoadError ?? state.readableError(error);
      });
    }
  }

  List<_PracticeItem> _shuffleQuestions(List<Question> questions) {
    final items = questions.map((question) {
      final indexed = [
        for (var i = 0; i < question.options.length; i++)
          _Option(text: question.options[i], originalIndex: i),
      ]..shuffle(_random);
      final correctIndex = indexed.indexWhere(
        (option) => option.originalIndex == question.correctOption,
      );
      return _PracticeItem(
        question: question,
        options: indexed.map((option) => option.text).toList(),
        correctIndex: correctIndex < 0 ? 0 : correctIndex,
      );
    }).toList();
    items.shuffle(_random);
    return items;
  }

  Future<void> _select(int optionIndex) async {
    final item = _items[_index];
    if (_answers.containsKey(item.question.id)) {
      return;
    }
    setState(() => _answers[item.question.id] = optionIndex);
    if (_answers.length == _items.length && !_submitted) {
      _submitted = true;
      final answers = _items
          .map(
            (item) => {
              'questionId': item.question.id,
              'selectedOption': item.originalSelectedOption(
                _answers[item.question.id] ?? -1,
              ),
            },
          )
          .toList();
      await context.read<AppState>().recordPracticeSession(
        lessonId: widget.lessonId,
        sessionId: _newSessionId(),
        startedAt: _startedAt ?? DateTime.now().toUtc(),
        completedAt: DateTime.now().toUtc(),
        answers: answers,
        correctCount: _correctCount,
      );
    }
  }

  int get _correctCount => _items
      .where((item) => _answers[item.question.id] == item.correctIndex)
      .length;

  String _newSessionId() {
    final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return '${widget.lessonId}-$timestamp';
  }

  void _restart() {
    setState(() {
      _items = _shuffleQuestions(_items.map((item) => item.question).toList());
      _answers.clear();
      _index = 0;
      _submitted = false;
      _startedAt = DateTime.now().toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const XScaffold(
        title: 'Luyện tập',
        child: LoadingView(message: 'Đang tải câu hỏi luyện tập...'),
      );
    }
    if (_error != null || _items.isEmpty) {
      return XScaffold(
        title: 'Luyện tập',
        child: ErrorView(
          message: _error ?? 'Không có câu hỏi luyện tập.',
          onRetry: _load,
        ),
      );
    }

    final item = _items[_index];
    final selected = _answers[item.question.id];
    final answered = selected != null;
    final isLast = _index == _items.length - 1;

    return XScaffold(
      title: 'Luyện tập',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: (_answers.length / _items.length)
                      .clamp(0, 1)
                      .toDouble(),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Text('${_answers.length}/${_items.length}'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Câu ${_index + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            item.question.question,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (item.question.hint.isNotEmpty) ...[
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.question.hint)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          for (var i = 0; i < item.options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: answered ? null : () => _select(i),
                icon: Icon(_optionIcon(item, selected, i)),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.options[i]),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          if (answered) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected == item.correctIndex
                    ? const Color(0xFFE8F7EE)
                    : const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  selected == item.correctIndex
                      ? 'Chính xác. ${item.question.explanation}'
                      : 'Đáp án đúng: ${item.options[item.correctIndex]}. ${item.question.explanation}',
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Làm lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: !answered
                      ? null
                      : isLast
                      ? _restart
                      : () => setState(() => _index++),
                  icon: Icon(isLast ? Icons.replay_rounded : Icons.arrow_forward),
                  label: Text(isLast ? 'Lượt mới' : 'Câu tiếp'),
                ),
              ),
            ],
          ),
          if (_answers.length == _items.length) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Kết quả lượt này: $_correctCount/${_items.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _optionIcon(_PracticeItem item, int? selected, int optionIndex) {
    if (selected == null) {
      return Icons.radio_button_unchecked_rounded;
    }
    if (optionIndex == item.correctIndex) {
      return Icons.check_circle_rounded;
    }
    if (optionIndex == selected) {
      return Icons.cancel_rounded;
    }
    return Icons.radio_button_unchecked_rounded;
  }
}

class _PracticeItem {
  const _PracticeItem({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final Question question;
  final List<String> options;
  final int correctIndex;

  int originalSelectedOption(int selectedIndex) {
    if (selectedIndex < 0 || selectedIndex >= options.length) {
      return selectedIndex;
    }
    return question.options.indexOf(options[selectedIndex]);
  }
}

class _Option {
  const _Option({required this.text, required this.originalIndex});

  final String text;
  final int originalIndex;
}
