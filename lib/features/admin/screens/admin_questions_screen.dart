import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
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
        ? state.adminQuestions
            .where((q) => q.lessonId == widget.lessonId)
            .toList()
        : state.adminQuestions;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(widget.lessonId != null ? '/admin/lessons' : '/admin'),
        ),
        title: const Text(
          'Quản lý Câu hỏi',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Thêm câu hỏi',
            onPressed: state.adminLessons.isEmpty
                ? null
                : () => _showQuestionDialog(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBreadcrumbs(context, state),
          Expanded(
            child: state.isBusy && state.adminQuestions.isEmpty
                ? const LoadingView(message: 'Đang tải questions...')
                : state.errorMessage != null && state.adminQuestions.isEmpty
                    ? ErrorView(
                        message: state.errorMessage!,
                        onRetry: () =>
                            context.read<AppState>().loadAdminQuestions(),
                      )
                    : questions.isEmpty
                        ? const EmptyView(message: 'Chưa có question.')
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: questions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final question = questions[index];
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
                                              color: const Color(0xFFFDF2F8),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.quiz_rounded,
                                              color: Color(0xFFEC4899),
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
                                                  question.question,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Mã câu hỏi: ${question.id}',
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
                                      if (question.options.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              for (var i = 0;
                                                  i < question.options.length;
                                                  i++)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${String.fromCharCode(65 + i)}. ',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: question
                                                                      .correctOption ==
                                                                  i
                                                              ? const Color(
                                                                  0xFF10B981)
                                                              : const Color(
                                                                  0xFF64748B),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          question.options[i],
                                                          style: TextStyle(
                                                            color: question
                                                                        .correctOption ==
                                                                    i
                                                                ? const Color(
                                                                    0xFF0F172A)
                                                                : const Color(
                                                                    0xFF475569),
                                                            fontWeight: question
                                                                        .correctOption ==
                                                                    i
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                                                  'Đáp án: ${String.fromCharCode(65 + (question.correctOption ?? 0))}',
                                                  Icons.check_circle_rounded,
                                                  const Color(0xFF10B981),
                                                ),
                                                _buildTag(
                                                  'Thứ tự: ${question.orderIndex}',
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
                                                tooltip: 'Sửa',
                                                onPressed: () =>
                                                    _showQuestionDialog(context,
                                                        question: question),
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
                                                  question.id,
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
    final lesson = widget.lessonId != null
        ? state.adminLessons.where((l) => l.id == widget.lessonId).firstOrNull
        : null;
    final chapter = lesson != null
        ? state.chapters.where((c) => c.id == lesson.chapterId).firstOrNull
        : null;

    final items = [
      _BreadcrumbItem(label: 'Admin', onTap: () => context.go('/admin')),
      _BreadcrumbItem(
        label: 'Chapters',
        onTap: () => context.go('/admin/chapters'),
      ),
      if (chapter != null)
        _BreadcrumbItem(
          label: chapter.title,
          onTap: () => context.go('/admin/lessons?chapterId=${chapter.id}'),
        ),
      if (lesson != null) _BreadcrumbItem(label: lesson.title),
      if (widget.lessonId == null) _BreadcrumbItem(label: 'Tất cả câu hỏi'),
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
    var lessonId =
        question?.lessonId ?? widget.lessonId ?? state.adminLessons.first.id;
    var correctOption = question?.correctOption ?? 0;
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Question>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(question == null ? 'Thêm câu hỏi' : 'Sửa câu hỏi'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.lessonId == null) ...[
                      DropdownButtonFormField<String>(
                        value: lessonId,
                        items: [
                          for (final lesson in state.adminLessons)
                            DropdownMenuItem(
                              value: lesson.id,
                              child: Text(lesson.title),
                            ),
                        ],
                        onChanged: (value) => setDialogState(
                            () => lessonId = value ?? lessonId),
                        decoration: InputDecoration(
                          labelText: 'Bài học',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: text,
                      decoration: InputDecoration(
                        labelText: 'Nội dung câu hỏi',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập nội dung câu hỏi';
                        }
                        if (value.trim().length < 5) {
                          return 'Câu hỏi phải có ít nhất 5 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < options.length; i++) ...[
                      TextFormField(
                        controller: options[i],
                        decoration: InputDecoration(
                          labelText: 'Lựa chọn ${String.fromCharCode(65 + i)}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập lựa chọn ${String.fromCharCode(65 + i)}';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      value: correctOption,
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Lựa chọn A'),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Lựa chọn B'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child: Text('Lựa chọn C'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text('Lựa chọn D'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => correctOption = value ?? correctOption,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Đáp án đúng',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: explanation,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Lời giải chi tiết',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập lời giải chi tiết';
                        }
                        if (value.trim().length < 5) {
                          return 'Lời giải phải có ít nhất 5 ký tự';
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
                    id: question?.id ??
                        'question_${DateTime.now().millisecondsSinceEpoch}',
                    lessonId: lessonId,
                    question: text.text.trim(),
                    options: options.map((item) => item.text.trim()).toList(),
                    correctOption: correctOption,
                    explanation: explanation.text.trim(),
                    orderIndex: int.tryParse(order.text) ?? 0,
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xóa câu hỏi?'),
            content: const Text('Câu hỏi sẽ bị xóa khỏi ngân hàng câu hỏi.'),
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
      await context.read<AppState>().deleteAdminQuestion(id);
    }
  }
}

class _BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  _BreadcrumbItem({required this.label, this.onTap});
}
