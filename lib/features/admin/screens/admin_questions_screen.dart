import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

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
    return AdminLayout(
      title: 'Quản lý Câu hỏi',
      subtitle: 'Tất cả câu hỏi trắc nghiệm tự luyện trong các bài học',
      activeRoute: '/admin/questions',
      floatingActionButton: FloatingActionButton(
        tooltip: 'Thêm câu hỏi mới',
        onPressed: state.adminLessons.isEmpty
            ? null
            : () => _showQuestionDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
      child: state.isBusy && state.adminQuestions.isEmpty
          ? const LoadingView(message: 'Đang tải questions...')
          : state.errorMessage != null && state.adminQuestions.isEmpty
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AppState>().loadAdminQuestions(),
            )
          : state.adminQuestions.isEmpty
          ? const EmptyView(message: 'Chưa có question.')
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.adminQuestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final question = state.adminQuestions[index];
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
    );
  }

  Future<void> _showQuestionDialog(
    BuildContext context, {
    Question? question,
  }) async {
    final state = context.read<AppState>();
    final id = TextEditingController(text: question?.id ?? '');
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
    var lessonId = question?.lessonId ?? state.adminLessons.first.id;
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
                    TextFormField(
                      controller: id,
                      enabled: question == null,
                      decoration: const InputDecoration(labelText: 'ID'),
                      validator: _required,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: lessonId,
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
                      initialValue: correctOption,
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
                    id: id.text.trim(),
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
