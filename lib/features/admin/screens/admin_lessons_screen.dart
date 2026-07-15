import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
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
        ? state.adminLessons
            .where((l) => l.chapterId == widget.chapterId)
            .toList()
        : state.adminLessons;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(widget.chapterId != null ? '/admin/chapters' : '/admin'),
        ),
        title: const Text(
          'Quản lý Bài học',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm bài học',
            onPressed: state.chapters.isEmpty
                ? null
                : () => _showLessonDialog(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context, state),
          Expanded(
            child: state.isBusy && state.adminLessons.isEmpty
                ? const LoadingView(message: 'Đang tải lessons...')
                : state.errorMessage != null && state.adminLessons.isEmpty
                    ? ErrorView(
                        message: state.errorMessage!,
                        onRetry: () =>
                            context.read<AppState>().loadAdminLessons(),
                      )
                    : lessons.isEmpty
                        ? const EmptyView(message: 'Chưa có lesson.')
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: lessons.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final lesson = lessons[index];
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
                                              color: lesson.isPublished
                                                  ? const Color(0xFFECFDF5)
                                                  : const Color(0xFFFFFBEB),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              lesson.isPublished
                                                  ? Icons.visibility_rounded
                                                  : Icons.visibility_off_rounded,
                                              color: lesson.isPublished
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
                                                  lesson.title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Mã bài học: ${lesson.id}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF94A3B8),
                                                    fontSize: 12,
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
                                                  '${lesson.estimatedMinutes} phút',
                                                  Icons.timer_outlined,
                                                  const Color(0xFF3B82F6),
                                                ),
                                                _buildTag(
                                                  'Thứ tự: ${lesson.orderIndex}',
                                                  Icons.sort_rounded,
                                                  const Color(0xFF8B5CF6),
                                                ),
                                                _buildTag(
                                                  lesson.isPublished
                                                      ? 'Đã xuất bản'
                                                      : 'Bản nháp',
                                                  lesson.isPublished
                                                      ? Icons
                                                          .check_circle_outline_rounded
                                                      : Icons.help_outline_rounded,
                                                  lesson.isPublished
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFD97706),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Xem câu hỏi',
                                                onPressed: () => context.go(
                                                  '/admin/questions?lessonId=${lesson.id}',
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
                                                    _showLessonDialog(context,
                                                        lesson: lesson),
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
                                                  lesson.id,
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

  Widget _buildBreadcrumbs(BuildContext context, AppState state) {
    final chapter = widget.chapterId != null
        ? state.chapters.where((c) => c.id == widget.chapterId).firstOrNull
        : null;

    final items = [
      _BreadcrumbItem(label: 'Admin', onTap: () => context.go('/admin')),
      _BreadcrumbItem(
        label: 'Chapters',
        onTap: () => context.go('/admin/chapters'),
      ),
      if (chapter != null) _BreadcrumbItem(label: chapter.title),
      if (widget.chapterId == null) _BreadcrumbItem(label: 'Tất cả bài học'),
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

  Future<void> _showLessonDialog(BuildContext context, {Lesson? lesson}) async {
    final state = context.read<AppState>();
    final title = TextEditingController(text: lesson?.title ?? '');
    final content = TextEditingController(text: lesson?.content ?? '');
    final formula = TextEditingController(text: lesson?.formulaLatex ?? '');
    final minutes = TextEditingController(
      text: '${lesson?.estimatedMinutes ?? 10}',
    );
    final order = TextEditingController(text: '${lesson?.orderIndex ?? 0}');
    var chapterId =
        lesson?.chapterId ?? widget.chapterId ?? state.chapters.first.id;
    var isPublished = lesson?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Lesson>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(lesson == null ? 'Thêm bài học' : 'Sửa bài học'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.chapterId == null) ...[
                      DropdownButtonFormField<String>(
                        value: chapterId,
                        items: [
                          for (final chapter in state.chapters)
                            DropdownMenuItem(
                              value: chapter.id,
                              child: Text(chapter.title),
                            ),
                        ],
                        onChanged: (value) => setDialogState(
                            () => chapterId = value ?? chapterId),
                        decoration: InputDecoration(
                          labelText: 'Chương học',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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
                          return 'Vui lòng nhập tiêu đề bài học';
                        }
                        if (value.trim().length < 3) {
                          return 'Tiêu đề phải có ít nhất 3 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: content,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Nội dung lý thuyết (Markdown)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung lý thuyết';
                        }
                        if (value.trim().length < 10) {
                          return 'Nội dung phải có ít nhất 10 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: formula,
                      decoration: InputDecoration(
                        labelText: 'Công thức chính (LaTeX)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: minutes,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số phút ước tính',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập số phút ước tính';
                        }
                        final n = int.tryParse(value);
                        if (n == null || n <= 0) {
                          return 'Số phút phải là số nguyên dương';
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
                    id: lesson?.id ??
                        'lesson_${DateTime.now().millisecondsSinceEpoch}',
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xóa bài học?'),
            content: const Text('Bài học sẽ được ẩn khỏi luồng học sinh.'),
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
      await context.read<AppState>().deleteAdminLesson(id);
    }
  }
}

class _BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  _BreadcrumbItem({required this.label, this.onTap});
}
