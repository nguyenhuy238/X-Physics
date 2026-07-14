import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class AdminLessonsScreen extends StatefulWidget {
  final String? chapterId;
  const AdminLessonsScreen({super.key, this.chapterId});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdminLessons();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lessons = widget.chapterId != null
        ? state.adminLessons.where((l) => l.chapterId == widget.chapterId).toList()
        : state.adminLessons;

    return XScaffold(
      title: 'Admin Lessons',
      actions: [
        IconButton(
          tooltip: 'Thêm lesson',
          onPressed: state.chapters.isEmpty
              ? null
              : () => _showLessonDialog(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context, state),
          Expanded(
            child: state.isBusy && state.adminLessons.isEmpty
                ? const LoadingView(message: 'Đang tải lessons...')
                : state.errorMessage != null && state.adminLessons.isEmpty
                ? ErrorView(
                    message: state.errorMessage!,
                    onRetry: () => context.read<AppState>().loadAdminLessons(),
                  )
                : lessons.isEmpty
                ? const EmptyView(message: 'Chưa có lesson.')
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: lessons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final lesson = lessons[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            lesson.isPublished
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          title: Text(lesson.title),
                          subtitle: Text(
                            '${lesson.id} • ${lesson.chapterId} • ${lesson.estimatedMinutes} phút',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Xem câu hỏi',
                                onPressed: () => context.go('/admin/questions?lessonId=${lesson.id}'),
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                              IconButton(
                                tooltip: 'Sửa',
                                onPressed: () =>
                                    _showLessonDialog(context, lesson: lesson),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => _confirmDelete(context, lesson.id),
                                icon: const Icon(Icons.delete_rounded),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, AppState state) {
    final chapter = widget.chapterId != null
        ? state.chapters.where((c) => c.id == widget.chapterId).firstOrNull
        : null;

    final items = [
      _BreadcrumbItem(label: 'Admin', onTap: () => context.go('/admin')),
      _BreadcrumbItem(label: 'Chapters', onTap: () => context.go('/admin/chapters')),
      if (chapter != null)
        _BreadcrumbItem(label: chapter.title),
      if (widget.chapterId == null)
        _BreadcrumbItem(label: 'All Lessons'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).cardColor.withOpacity(0.4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items.map((item) {
          final isLast = item == items.last;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.onTap != null && !isLast)
                GestureDetector(
                  onTap: item.onTap,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  item.label,
                  style: const TextStyle(color: Colors.grey),
                ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showLessonDialog(BuildContext context, {Lesson? lesson}) async {
    final state = context.read<AppState>();
    final title = TextEditingController(text: lesson?.title ?? '');
    final content = TextEditingController(text: lesson?.content ?? '');
    final formula = TextEditingController(text: lesson?.formulaLatex ?? '');
    final minutes = TextEditingController(
      text: '${lesson?.estimatedMinutes ?? 10}',
    );
    final order = TextEditingController(text: '${lesson?.orderIndex ?? 0}');
    var chapterId = lesson?.chapterId ?? widget.chapterId ?? state.chapters.first.id;
    var isPublished = lesson?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Lesson>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(lesson == null ? 'Thêm lesson' : 'Sửa lesson'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.chapterId == null)
                      DropdownButtonFormField<String>(
                        value: chapterId,
                        items: [
                          for (final chapter in state.chapters)
                            DropdownMenuItem(
                              value: chapter.id,
                              child: Text(chapter.title),
                            ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => chapterId = value ?? chapterId),
                        decoration: const InputDecoration(labelText: 'Chapter'),
                      ),
                    TextFormField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: content,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Content Markdown',
                      ),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: formula,
                      decoration: const InputDecoration(labelText: 'Formula LaTeX'),
                    ),
                    TextFormField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minutes'),
                    ),
                    TextFormField(
                      controller: order,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Order index'),
                    ),
                    SwitchListTile(
                      value: isPublished,
                      onChanged: (value) =>
                          setDialogState(() => isPublished = value),
                      title: const Text('Published'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.pop(
                  dialogContext,
                  Lesson(
                    id: lesson?.id ?? 'lesson_${DateTime.now().millisecondsSinceEpoch}',
                    chapterId: chapterId,
                    title: title.text.trim(),
                    content: content.text.trim(),
                    formulaLatex: formula.text.trim(),
                    estimatedMinutes: int.tryParse(minutes.text) ?? 10,
                    simulation: FormulaSimulationConfig.empty(),
                    questions: const [],
                    orderIndex: int.tryParse(order.text) ?? 0,
                    isPublished: isPublished,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    await context.read<AppState>().saveAdminLesson(
      result,
      isUpdate: lesson != null,
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bắt buộc' : null;

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa lesson?'),
            content: const Text('Lesson sẽ được ẩn khỏi luồng học sinh.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && context.mounted) {
      await context.read<AppState>().deleteAdminLesson(id);
    }
  }
}

class _BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  _BreadcrumbItem({required this.label, this.onTap});
}
