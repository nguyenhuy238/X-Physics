import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../providers/admin_provider.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly bai hoc')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const LoadingWidget();
          }
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: () => provider.fetchLessons());
          }

          final lessons = provider.lastLessons;

          if (lessons.isEmpty) {
            return const EmptyView(message: 'Chua co bai hoc');
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                child: ListTile(
                  title: Text(lesson['title'] ?? ''),
                  subtitle: Text('Chapter: ${lesson['chapterId']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(context, lesson),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(context, lesson['id'] as String),
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
        title: const Text('Xoa bai hoc?'),
        content: const Text('Hanh dong nay chi an bai hoc va khong xoa du lieu goc.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoa')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/lessons/$id');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Da xoa bai hoc')));
      await provider.fetchLessons();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openForm(BuildContext context, [Map<String, dynamic>? lesson]) async {
    final isEdit = lesson != null;
    final titleController = TextEditingController(text: lesson?['title'] ?? '');
    final chapterIdController = TextEditingController(text: lesson?['chapterId'] ?? '');
    final contentController = TextEditingController(text: lesson?['contentMarkdown'] ?? '');
    final minutesController = TextEditingController(text: (lesson?['estimatedMinutes'] ?? 10).toString());
    final orderController = TextEditingController(text: (lesson?['orderIndex'] ?? 0).toString());
    final published = lesson?['isPublished'] ?? true;
    final formulaController = TextEditingController(text: lesson?['formulaLatex'] ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sua bai hoc' : 'Them bai hoc'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tieu de')),
              const SizedBox(height: 12),
              TextField(controller: chapterIdController, decoration: const InputDecoration(labelText: 'Chapter ID')),
              const SizedBox(height: 12),
              TextField(controller: contentController, maxLines: 3, decoration: const InputDecoration(labelText: 'Noi dung')),
              const SizedBox(height: 12),
              TextField(controller: formulaController, decoration: const InputDecoration(labelText: 'Cong thuc LaTeX')),
              const SizedBox(height: 12),
              TextField(controller: minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'So phut')),
              const SizedBox(height: 12),
              TextField(controller: orderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Thu tu')),
              SwitchListTile(
                title: const Text('Hien thi'),
                value: published,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Luu')),
        ],
      ),
    );

    if (result != true || !context.mounted) return;

    final provider = context.read<AdminProvider>();
    final payload = <String, dynamic>{
      'id': lesson?['id'] ?? 'lesson_${DateTime.now().millisecondsSinceEpoch}',
      'chapterId': chapterIdController.text,
      'title': titleController.text,
      'contentMarkdown': contentController.text,
      'estimatedMinutes': int.tryParse(minutesController.text) ?? 10,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
      'isPublished': published,
      'formulaLatex': formulaController.text,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/lessons/${payload['id']}', payload);
      } else {
        await api.post('admin/lessons', payload);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Da cap nhat' : 'Da tao')));
      await provider.fetchLessons();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
