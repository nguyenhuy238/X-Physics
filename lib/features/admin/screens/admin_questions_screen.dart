import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class AdminQuestionsScreen extends StatefulWidget {
  final String? lessonId;
  const AdminQuestionsScreen({super.key, this.lessonId});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdminQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final questions = widget.lessonId != null
        ? state.adminQuestions.where((q) => q.lessonId == widget.lessonId).toList()
        : state.adminQuestions;

    return XScaffold(
      title: 'Admin Questions',
      actions: [
        IconButton(
          tooltip: 'Thêm question',
          onPressed: state.adminLessons.isEmpty
              ? null
              : () => _showQuestionDialog(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context, state),
          Expanded(
            child: state.isBusy && state.adminQuestions.isEmpty
                ? const LoadingView(message: 'Đang tải questions...')
                : state.errorMessage != null && state.adminQuestions.isEmpty
                ? ErrorView(
                    message: state.errorMessage!,
                    onRetry: () => context.read<AppState>().loadAdminQuestions(),
                  )
                : questions.isEmpty
                ? const EmptyView(message: 'Chưa có question.')
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final question = questions[index];
                      return Card(
                        child: ListTile(
                          title: Text(question.question),
                          subtitle: Text(
                            '${question.id} • ${question.lessonId} • đáp án ${question.correctOption ?? 0}',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Sửa',
                                onPressed: () =>
                                    _showQuestionDialog(context, question: question),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => _confirmDelete(context, question.id),
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
    final lesson = widget.lessonId != null
        ? state.adminLessons.where((l) => l.id == widget.lessonId).firstOrNull
        : null;
    final chapter = lesson != null
        ? state.chapters.where((c) => c.id == lesson.chapterId).firstOrNull
        : null;

    final items = [
      _BreadcrumbItem(label: 'Admin', onTap: () => context.go('/admin')),
      _BreadcrumbItem(label: 'Chapters', onTap: () => context.go('/admin/chapters')),
      if (chapter != null)
        _BreadcrumbItem(
          label: chapter.title,
          onTap: () => context.go('/admin/lessons?chapterId=${chapter.id}'),
        ),
      if (lesson != null)
        _BreadcrumbItem(label: lesson.title),
      if (widget.lessonId == null)
        _BreadcrumbItem(label: 'All Questions'),
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

  Future<void> _showQuestionDialog(
    BuildContext context, {
    Question? question,
  }) async {
    final state = context.read<AppState>();
    final text = TextEditingController(text: question?.question ?? '');
    final explanation = TextEditingController(text: question?.explanation ?? '');
    final order = TextEditingController(text: '${question?.orderIndex ?? 0}');
    final options = List.generate(
      4,
      (index) => TextEditingController(
        text: index < (question?.options.length ?? 0)
            ? question!.options[index]
            : '',
      ),
    );
    var lessonId = question?.lessonId ?? widget.lessonId ?? state.adminLessons.first.id;
    var correctOption = question?.correctOption ?? 0;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Question>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(question == null ? 'Thêm question' : 'Sửa question'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.lessonId == null)
                      DropdownButtonFormField<String>(
                        value: lessonId,
                        items: [
                          for (final lesson in state.adminLessons)
                            DropdownMenuItem(
                              value: lesson.id,
                              child: Text(lesson.title),
                            ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => lessonId = value ?? lessonId),
                        decoration: const InputDecoration(labelText: 'Lesson'),
                      ),
                    TextFormField(
                      controller: text,
                      decoration: const InputDecoration(labelText: 'Question'),
                      validator: _required,
                    ),
                    for (var i = 0; i < options.length; i++)
                      TextFormField(
                        controller: options[i],
                        decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                        validator: _required,
                      ),
                    DropdownButtonFormField<int>(
                      value: correctOption,
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Option 1')),
                        DropdownMenuItem(value: 1, child: Text('Option 2')),
                        DropdownMenuItem(value: 2, child: Text('Option 3')),
                        DropdownMenuItem(value: 3, child: Text('Option 4')),
                      ],
                      onChanged: (value) => setDialogState(
                        () => correctOption = value ?? correctOption,
                      ),
                      decoration: const InputDecoration(labelText: 'Correct'),
                    ),
                    TextFormField(
                      controller: explanation,
                      decoration: const InputDecoration(labelText: 'Explanation'),
                      validator: _required,
                    ),
                    TextFormField(
                      controller: order,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Order index'),
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
                  Question(
                    id: question?.id ?? 'question_${DateTime.now().millisecondsSinceEpoch}',
                    lessonId: lessonId,
                    question: text.text.trim(),
                    options: options.map((item) => item.text.trim()).toList(),
                    correctOption: correctOption,
                    explanation: explanation.text.trim(),
                    orderIndex: int.tryParse(order.text) ?? 0,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    for (final controller in options) {
      controller.dispose();
    }
    if (result == null || !context.mounted) return;
    await context.read<AppState>().saveAdminQuestion(
      result,
      isUpdate: question != null,
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bắt buộc' : null;

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa question?'),
            content: const Text('Question sẽ bị xóa khỏi ngân hàng câu hỏi.'),
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
      await context.read<AppState>().deleteAdminQuestion(id);
    }
  }
}

class _BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  _BreadcrumbItem({required this.label, this.onTap});
}
