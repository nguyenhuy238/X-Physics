import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../providers/admin_provider.dart';

class AdminChaptersScreen extends StatefulWidget {
  const AdminChaptersScreen({super.key});

  @override
  State<AdminChaptersScreen> createState() => _AdminChaptersScreenState();
}

class _AdminChaptersScreenState extends State<AdminChaptersScreen> {
  bool _published = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly chuong')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const LoadingWidget();
          }
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: () => provider.fetchChapters());
          }

          final chapters = provider.lastChapters;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return Card(
                child: ListTile(
                  title: Text(chapter['title'] ?? ''),
                  subtitle: Text('Thu tu: ${chapter['orderIndex']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(context, chapter),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(context, chapter['id'] as String),
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
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
        title: const Text('Xoa chuong?'),
        content: const Text('Hanh dong nay chi an chuong va khong xoa du lieu goc.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xoa')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/chapters/$id');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Da xoa chuong')));
      await context.read<AdminProvider>().fetchChapters();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _openForm(BuildContext context, [Map<String, dynamic>? chapter]) async {
    final isEdit = chapter != null;
    final titleController = TextEditingController(text: chapter?['title'] ?? '');
    final descriptionController = TextEditingController(text: chapter?['description'] ?? '');
    final orderController = TextEditingController(text: chapter?['orderIndex']?.toString() ?? '');
    bool published = chapter?['isPublished'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sua chuong' : 'Them chuong'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tieu de')),
              const SizedBox(height: 12),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Mo ta')),
              const SizedBox(height: 12),
              TextField(controller: orderController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Thu tu')),
              SwitchListTile(
                title: const Text('Hien thi'),
                value: published,
                onChanged: (value) => setState(() => _published = value),
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
      'id': chapter?['id'] ?? 'chapter_${DateTime.now().millisecondsSinceEpoch}',
      'title': titleController.text,
      'description': descriptionController.text,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
      'isPublished': published,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/chapters/${payload['id']}', payload);
      } else {
        await api.post('admin/chapters', payload);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Da cap nhat' : 'Da tao')));
      await provider.fetchChapters();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
