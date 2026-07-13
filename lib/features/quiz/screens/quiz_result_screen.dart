import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../progress/application/app_state.dart';

class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({
    super.key,
    required this.lessonId,
    this.initialAttempt,
  });

  final String lessonId;
  final QuizAttempt? initialAttempt;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final attempt = _resolveAttempt(state);
    if (attempt == null) {
      return XScaffold(
        title: 'Ket qua',
        child: _MissingResultView(lessonId: lessonId),
      );
    }

    final nextLessonId = _nextLessonId(state, lessonId);
    return XScaffold(
      title: 'Ket qua',
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 760 ? 48.0 : 20.0;
            return ListView(
              padding: EdgeInsets.all(horizontalPadding),
              children: [
                _ResultHeader(attempt: attempt),
                if (attempt.newBadges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _NewBadgesView(badges: attempt.newBadges),
                ],
                const SizedBox(height: 16),
                Text(
                  'Review dap an',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                if (attempt.review.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Chua co du lieu review cho lan lam nay.'),
                    ),
                  )
                else
                  for (final item in attempt.review) _ReviewCard(item: item),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Ve trang chu'),
                    ),
                    OutlinedButton.icon(
                      onPressed: nextLessonId == null
                          ? () => context.go('/lessons/$lessonId')
                          : () => context.go('/lessons/$nextLessonId'),
                      icon: Icon(
                        nextLessonId == null
                            ? Icons.menu_book_rounded
                            : Icons.skip_next_rounded,
                      ),
                      label: Text(
                        nextLessonId == null
                            ? 'On lai bai hoc'
                            : 'Hoc bai tiep theo',
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  QuizAttempt? _resolveAttempt(AppState state) {
    if (initialAttempt != null && initialAttempt!.lessonId == lessonId) {
      return initialAttempt;
    }
    final cached = state.quizResultsByLesson[lessonId];
    if (cached != null) {
      return cached;
    }
    final last = state.lastAttempt;
    if (last != null && last.lessonId == lessonId) {
      return last;
    }
    return null;
  }

  String? _nextLessonId(AppState state, String currentLessonId) {
    for (final lessons in state.lessonsByChapter.values) {
      final index = lessons.indexWhere(
        (lesson) => lesson.id == currentLessonId,
      );
      if (index != -1 && index + 1 < lessons.length) {
        return lessons[index + 1].id;
      }
    }
    final current = state.lessonsById[currentLessonId];
    if (current == null) {
      return null;
    }
    final lessons =
        state.lessonsByChapter[current.chapterId] ?? const <Lesson>[];
    final index = lessons.indexWhere((lesson) => lesson.id == currentLessonId);
    if (index != -1 && index + 1 < lessons.length) {
      return lessons[index + 1].id;
    }
    return null;
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              attempt.score.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${attempt.correctCount}/${attempt.totalQuestions} cau dung',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.timer_rounded),
                  label: Text(_formatDuration(attempt.durationSeconds)),
                ),
                Chip(
                  avatar: const Icon(Icons.monetization_on_rounded),
                  label: Text(
                    attempt.earnedCoins == 0
                        ? 'Khong nhan them xu'
                        : '+${attempt.earnedCoins} xu',
                  ),
                ),
                if (attempt.totalCoins > 0)
                  Chip(
                    avatar: const Icon(Icons.account_balance_wallet_rounded),
                    label: Text('Tong ${attempt.totalCoins} xu'),
                  ),
              ],
            ),
            if (attempt.attemptId.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Attempt ${attempt.attemptId}',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final minutes = safeSeconds ~/ 60;
    final remainingSeconds = safeSeconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _NewBadgesView extends StatelessWidget {
  const _NewBadgesView({required this.badges});

  final List<XBadge> badges;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Huy hieu moi',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            for (final badge in badges)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _BadgeIcon(iconUrl: badge.iconUrl),
                title: Text(badge.name),
                subtitle: badge.description.isEmpty
                    ? null
                    : Text(badge.description),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.iconUrl});

  final String iconUrl;

  @override
  Widget build(BuildContext context) {
    final value = iconUrl.trim();
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return ClipOval(
        child: Image.network(
          value,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const CircleAvatar(child: Icon(Icons.workspace_premium_rounded)),
        ),
      );
    }
    return const CircleAvatar(child: Icon(Icons.workspace_premium_rounded));
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.item});

  final QuizReviewItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: item.isCorrect ? Colors.green : colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(child: _SmartText(item.question)),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < item.options.length; i++)
              _OptionReviewRow(
                index: i,
                text: item.options[i],
                selected: item.selectedOption == i,
                correct: item.correctOption == i,
              ),
            if (item.selectedOption == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Ban chua chon dap an.'),
              ),
            if (item.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Giai thich',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              _SmartText(item.explanation, baseFontSize: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionReviewRow extends StatelessWidget {
  const _OptionReviewRow({
    required this.index,
    required this.text,
    required this.selected,
    required this.correct,
  });

  final int index;
  final String text;
  final bool selected;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = correct
        ? Colors.green.withValues(alpha: .12)
        : selected
        ? colorScheme.error.withValues(alpha: .10)
        : colorScheme.surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: correct
              ? Colors.green
              : selected
              ? colorScheme.error
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}.',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(child: _SmartText(text, baseFontSize: 14)),
          if (correct) const Icon(Icons.check_rounded, color: Colors.green),
          if (selected && !correct)
            Icon(Icons.close_rounded, color: colorScheme.error),
        ],
      ),
    );
  }
}

class _SmartText extends StatelessWidget {
  const _SmartText(this.value, {this.baseFontSize = 16});

  final String value;
  final double baseFontSize;

  @override
  Widget build(BuildContext context) {
    final text = value.trim();
    final looksLikeLatex =
        text.contains(r'\') || (text.startsWith(r'$') && text.endsWith(r'$'));
    if (!looksLikeLatex) {
      return Text(value, softWrap: true);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(
        text.replaceAll(r'$', ''),
        textStyle: TextStyle(fontSize: baseFontSize),
        onErrorFallback: (_) => Text(value, softWrap: true),
      ),
    );
  }
}

class _MissingResultView extends StatelessWidget {
  const _MissingResultView({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 42),
            const SizedBox(height: 12),
            const Text(
              'Khong tim thay ket qua quiz cho lan lam nay.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Ve trang chu'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/lessons/$lessonId'),
                  child: const Text('Quay lai bai hoc'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
