import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class AdminChaptersScreen extends StatefulWidget {
  const AdminChaptersScreen({super.key});

  @override
  State<AdminChaptersScreen> createState() => _AdminChaptersScreenState();
}

class _AdminChaptersScreenState extends State<AdminChaptersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdminChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return XScaffold(
      title: 'Admin Chapters',
      actions: [
        IconButton(
          tooltip: 'Thêm chapter',
          onPressed: () => _showChapterDialog(context),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context),
          Expanded(
            child: state.isBusy && state.chapters.isEmpty
                ? const LoadingView(message: 'Đang tải chapters...')
                : state.errorMessage != null && state.chapters.isEmpty
                ? ErrorView(
                    message: state.errorMessage!,
                    onRetry: () => context.read<AppState>().loadAdminChapters(),
                  )
                : state.chapters.isEmpty
                ? const EmptyView(message: 'Chưa có chapter.')
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.chapters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final chapter = state.chapters[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            chapter.isPublished
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                          title: Text(chapter.title),
                          subtitle: Text(
                            '${chapter.id} • ${chapter.lessonCount} bài học • order ${chapter.orderIndex}\n${chapter.description}',
                          ),
                          isThreeLine: true,
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: 'Xem bài học',
                                onPressed: () => context.go('/admin/lessons?chapterId=${chapter.id}'),
                                icon: const Icon(Icons.arrow_forward_rounded),
                              ),
                              IconButton(
                                tooltip: 'Sửa',
                                onPressed: () =>
                                    _showChapterDialog(context, chapter: chapter),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                onPressed: () => _confirmDelete(context, chapter.id),
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

  Widget _buildBreadcrumbs(BuildContext context) {
    final items = [
      _BreadcrumbItem(label: 'Admin', onTap: () => context.go('/admin')),
      _BreadcrumbItem(label: 'Chapters'),
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

  Future<void> _showChapterDialog(
    BuildContext context, {
    Chapter? chapter,
  }) async {
    final title = TextEditingController(text: chapter?.title ?? '');
    final description = TextEditingController(text: chapter?.description ?? '');
    final order = TextEditingController(text: '${chapter?.orderIndex ?? 0}');
    var isPublished = chapter?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Chapter>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(chapter == null ? 'Thêm chapter' : 'Sửa chapter'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
                  ),
                  TextFormField(
                    controller: description,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
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
                  Chapter(
                    id: chapter?.id ?? 'chapter_${DateTime.now().millisecondsSinceEpoch}',
                    title: title.text.trim(),
                    description: description.text.trim(),
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
    final state = context.read<AppState>();
    if (chapter == null) {
      await state.saveAdminChapter(result);
    } else {
      await state.updateAdminChapter(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa chapter?'),
            content: const Text('Chapter sẽ được ẩn khỏi luồng học sinh.'),
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
      await context.read<AppState>().deleteAdminChapter(id);
    }
  }
}

class _BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  _BreadcrumbItem({required this.label, this.onTap});
}
