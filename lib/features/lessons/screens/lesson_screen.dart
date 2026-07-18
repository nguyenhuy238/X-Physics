import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
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
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadLesson);
    scroll.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted ||
        !scroll.hasClients ||
        scroll.position.maxScrollExtent == 0) {
      return;
    }

    final nextProgress = (scroll.offset / scroll.position.maxScrollExtent)
        .clamp(0, 1)
        .toDouble();
    setState(() => progress = nextProgress);

    // Report reading progress once the student has effectively reached
    // the end of the lesson. Queued locally when offline and synced
    // later — see AppState.updateReadingProgress / docs/OFFLINE_FLOW.md.
    if (nextProgress >= 0.9 &&
        !_readingProgressReported &&
        widget.lessonId.trim().isNotEmpty) {
      _readingProgressReported = true;
      unawaited(
        context.read<AppState>().updateReadingProgress(
          widget.lessonId,
          (nextProgress * 100).round(),
        ),
      );
    }
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
  void dispose() {
    scroll.removeListener(_handleScroll);
    scroll.dispose();
    super.dispose();
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
          message:
              state.errorMessage ??
              'Bài học này chưa có dữ liệu. Hãy kiểm tra kết nối hoặc tải bài offline trước.',
          onRetry: _loadLesson,
        ),
      );
    }
    return XScaffold(
      title: currentLesson.title,
      actions: [
        IconButton(
          tooltip: state.downloadedLessons.contains(currentLesson.id)
              ? 'Đã tải offline'
              : 'Tải bài học offline',
          onPressed: _isDownloading
              ? null
              : () => _downloadLesson(context, currentLesson.id),
          icon: _isDownloading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
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
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(999),
          ),
          if (state.effectiveOffline) const _OfflineReadingBanner(),
          if (state.offlineLessonUpdateAvailable(currentLesson.id))
            _OfflineUpdateBanner(
              lessonId: currentLesson.id,
              onUpdated: _loadLesson,
            ),
          Expanded(
            child: ListView(
              key: PageStorageKey<String>('lesson-${currentLesson.id}-scroll'),
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: MarkdownBody(
                    data: currentLesson.content,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: Theme.of(context).textTheme.bodyLarge,
                          h1: Theme.of(context).textTheme.headlineMedium,
                          h2: Theme.of(context).textTheme.titleLarge,
                          blockquoteDecoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: .45),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(
                                color: AppColors.primary,
                                width: 4,
                              ),
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                if (currentLesson.formulaLatex.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Công thức cốt lõi',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Math.tex(
                              currentLesson.formulaLatex,
                              textStyle: const TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                              ),
                              onErrorFallback: (_) => Text(
                                currentLesson.formulaLatex,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (currentLesson.simulation.title.isNotEmpty)
                  FormulaSimulationWidget(config: currentLesson.simulation),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: currentLesson.questions.isEmpty
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.quiz_outlined),
                      label: const Text('Bài học này chưa có quiz'),
                    )
                  : FilledButton.icon(
                      onPressed: () =>
                          context.push('/quiz/${currentLesson.id}'),
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text('Làm bài tập'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadLesson(BuildContext context, String lessonId) async {
    setState(() => _isDownloading = true);
    try {
      await context.read<AppState>().downloadLesson(lessonId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Đã lưu bài học để đọc offline.')),
          );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}

class _OfflineReadingBanner extends StatelessWidget {
  const _OfflineReadingBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE0F2FE),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: const [
            Icon(Icons.cloud_off_rounded, color: AppColors.info),
            SizedBox(width: 10),
            Expanded(child: Text('Đang dùng dữ liệu bài học đã tải offline.')),
          ],
        ),
      ),
    );
  }
}

class _OfflineUpdateBanner extends StatefulWidget {
  const _OfflineUpdateBanner({required this.lessonId, required this.onUpdated});

  final String lessonId;
  final Future<void> Function() onUpdated;

  @override
  State<_OfflineUpdateBanner> createState() => _OfflineUpdateBannerState();
}

class _OfflineUpdateBannerState extends State<_OfflineUpdateBanner> {
  bool _updating = false;

  Future<void> _update() async {
    setState(() => _updating = true);
    try {
      await context.read<AppState>().updateOfflineLesson(widget.lessonId);
      await widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật bản offline.')),
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
    final offline = context.select<AppState, bool>(
      (state) => state.effectiveOffline,
    );
    return Material(
      color: const Color(0xFFFFF7E6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.system_update_alt_rounded,
              color: Color(0xFFB8860B),
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Có bản cập nhật cho bản offline.')),
            TextButton.icon(
              onPressed: offline || _updating ? null : _update,
              icon: _updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.update_rounded),
              label: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }
}
