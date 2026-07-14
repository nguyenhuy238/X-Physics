import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../providers/admin_provider.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  int? _correctOption;
  String? _difficulty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly cau hoi')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const LoadingWidget();
          }
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: () => provider.fetchQuestions());
          }

          final questions = provider.lastQuestions;

          if (questions.isEmpty) {
            return const EmptyView(message: 'Chua co cau hoi');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                child: ListTile(
                  title: Text(question['question'] ?? ''),
                  subtitle: Text('Lesson: ${question['lessonId']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(context, question),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(context, question['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String id) async {
    final provider = context.read<AdminProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa cau hoi?'),
        content: const Text('Hanh dong nay se xoa cau hoi khoi he thong.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoa')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/questions/$id');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Da xoa cau hoi')));
      await provider.fetchQuestions();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openForm(BuildContext context, [Map<String, dynamic>? question]) async {
    final isEdit = question != null;
    final lessonIdController = TextEditingController(text: question?['lessonId'] ?? '');
    final questionTextController = TextEditingController(text: question?['question'] ?? '');
    final explanationController = TextEditingController(text: question?['explanation'] ?? '');
    final orderController = TextEditingController(text: (question?['orderIndex'] ?? 0).toString());
    final options = List<String>.from(question?['options'] ?? List.filled(4, ''));

    int selectedCorrect = _correctOption ?? question?['correctOption'] ?? 0;
    String selectedDifficulty = _difficulty ?? question?['difficulty'] ?? 'MEDIUM';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Sua cau hoi' : 'Them cau hoi'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: lessonIdController, decoration: const InputDecoration(labelText: 'Lesson ID')),
                    const SizedBox(height: 12),
                    TextField(controller: questionTextController, maxLines: 3, decoration: const InputDecoration(labelText: 'Noi dung cau hoi')),
                    const SizedBox(height: 12),
                    for (var i = 0; i < options.length)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: TextEditingController(text: options[i]),
                          decoration: InputDecoration(labelText: 'Lua chon ${i + 1}'),
                          onChanged: (value) => options[i] = value,
                        ),
                      ),
                    DropdownButtonFormField<int>(
                      value: selectedCorrect,
                      decoration: const InputDecoration(labelText: 'Dap an dung'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Lua chon 1')),
                        DropdownMenuItem(value: 1, child: Text('Lua chon 2')),
                        DropdownMenuItem(value: 2, child: Text('Lua chon 3')),
                        DropdownMenuItem(value: 3, child: Text('Lua chon 4')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedCorrect = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      decoration: const InputDecoration(labelText: 'Do kho'),
                      items: const [
                        DropdownMenuItem(value: 'EASY', child: Text('De')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('Trung binh')),
                        DropdownMenuItem(value: 'HARD', child: Text('Kho')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedDifficulty = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: explanationController, maxLines: 3, decoration: const InputDecoration(labelText: 'Giai thich')),
                    const SizedBox(height: 12),
                    TextField(controller: orderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Thu tu')),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
            FilledButton(
              onPressed: () {
                _correctOption = selectedCorrect;
                _difficulty = selectedDifficulty;
                Navigator.pop(context, true);
              },
              child: const Text('Luu'),
            ),
          ],
        );
      },
    );

    if (result != true || !context.mounted) return;

    final provider = context.read<AdminProvider>();
    final payload = <String, dynamic>{
      'id': question?['id'] ?? 'question_${DateTime.now().millisecondsSinceEpoch}',
      'lessonId': lessonIdController.text,
      'questionText': questionTextController.text,
      'options': options,
      'correctOption': selectedCorrect,
      'difficulty': selectedDifficulty,
      'explanation': explanationController.text,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/questions/${payload['id']}', payload);
      } else {
        await api.post('admin/questions', payload);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Da cap nhat' : 'Da tao')));
      await provider.fetchQuestions();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
