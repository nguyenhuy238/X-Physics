import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

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
      child: state.isBusy && state.adminLessons.isEmpty
          ? const LoadingView(message: 'Đang tải lessons...')
          : state.errorMessage != null && state.adminLessons.isEmpty
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AppState>().loadAdminLessons(),
            )
          : state.adminLessons.isEmpty
          ? const EmptyView(message: 'Chưa có lesson.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.adminLessons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final lesson = state.adminLessons[index];
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
    );
  }

  Future<void> _showLessonDialog(BuildContext context, {Lesson? lesson}) async {
    final state = context.read<AppState>();
    final id = TextEditingController(text: lesson?.id ?? '');
    final title = TextEditingController(text: lesson?.title ?? '');
    final content = TextEditingController(text: lesson?.content ?? '');
    final formula = TextEditingController(text: lesson?.formulaLatex ?? '');
    final minutes = TextEditingController(
      text: '${lesson?.estimatedMinutes ?? 10}',
    );
    final order = TextEditingController(text: '${lesson?.orderIndex ?? 0}');
    var chapterId = lesson?.chapterId ?? state.chapters.first.id;
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
                    TextFormField(
                      controller: id,
                      enabled: lesson == null,
                      decoration: const InputDecoration(labelText: 'ID'),
                      validator: _required,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: chapterId,
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
                    id: id.text.trim(),
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
