import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        title: const Text(
          'Quản lý Chương học',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm chương học',
            onPressed: () => _showChapterDialog(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context),
          Expanded(
            child: state.isBusy && state.chapters.isEmpty
                ? const LoadingView(message: 'Đang tải chapters...')
                : state.errorMessage != null && state.chapters.isEmpty
                    ? ErrorView(
                        message: state.errorMessage!,
                        onRetry: () =>
                            context.read<AppState>().loadAdminChapters(),
                      )
                    : state.chapters.isEmpty
                        ? const EmptyView(message: 'Chưa có chapter.')
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: state.chapters.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final chapter = state.chapters[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.01),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: chapter.isPublished
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFFFFBEB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              chapter.isPublished
                                                  ? Icons.visibility_rounded
                                                  : Icons.visibility_off_rounded,
                                              color: chapter.isPublished
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFD97706),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  chapter.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  chapter.description,
                                                  style: const TextStyle(
                                                    color: Color(0xFF64748B),
                                                    fontSize: 14,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                        color: Color(0xFFF1F5F9),
                                        height: 1,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                _buildTag(
                                                  '${chapter.lessonCount} bài học',
                                                  Icons.menu_book_rounded,
                                                  const Color(0xFF3B82F6),
                                                ),
                                                _buildTag(
                                                  'Thứ tự: ${chapter.orderIndex}',
                                                  Icons.sort_rounded,
                                                  const Color(0xFF8B5CF6),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Xem bài học',
                                                onPressed: () => context.go(
                                                  '/admin/lessons?chapterId=${chapter.id}',
                                                ),
                                                icon: const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Color(0xFF2563EB),
                                                  size: 20,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFEFF6FF),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Sửa',
                                                onPressed: () =>
                                                    _showChapterDialog(context,
                                                        chapter: chapter),
                                                icon: const Icon(
                                                  Icons.edit_rounded,
                                                  color: Color(0xFF475569),
                                                  size: 20,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFF1F5F9),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Xóa',
                                                onPressed: () => _confirmDelete(
                                                  context,
                                                  chapter.id,
                                                ),
                                                icon: const Icon(
                                                  Icons.delete_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 20,
                                                ),
                                                style: IconButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFFEF2F2),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
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

  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
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
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(chapter == null ? 'Thêm chapter' : 'Sửa chapter'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: title,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề chương học';
                      }
                      if (value.trim().length < 3) {
                        return 'Tiêu đề phải có ít nhất 3 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: description,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập mô tả chương học';
                      }
                      if (value.trim().length < 5) {
                        return 'Mô tả phải có ít nhất 5 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: order,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Thứ tự hiển thị',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập thứ tự hiển thị';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Thứ tự hiển thị phải là số nguyên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isPublished,
                    onChanged: (value) =>
                        setDialogState(() => isPublished = value),
                    title: const Text(
                      'Hiển thị cho học sinh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    contentPadding: EdgeInsets.zero,
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
                    id: chapter?.id ??
                        'chapter_${DateTime.now().millisecondsSinceEpoch}',
                    title: title.text.trim(),
                    description: description.text.trim(),
                    orderIndex: int.tryParse(order.text) ?? 0,
                    isPublished: isPublished,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xóa chapter?'),
            content: const Text('Chapter sẽ được ẩn khỏi luồng học sinh.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
