import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminLessonDetailScreen extends StatefulWidget {
  final String lessonId;
  const AdminLessonDetailScreen({super.key, required this.lessonId});

  @override
  State<AdminLessonDetailScreen> createState() =>
      _AdminLessonDetailScreenState();
}

class _AdminLessonDetailScreenState extends State<AdminLessonDetailScreen> {
  bool _editing = false;
  bool _saving = false;

  // Controllers – lazily populated once lesson is found
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formulaCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPublished = true;
  bool _initialized = false;

  void _initControllers(Lesson lesson) {
    if (_initialized) return;
    _titleCtrl.text = lesson.title;
    _contentCtrl.text = lesson.content;
    _formulaCtrl.text = lesson.formulaLatex;
    _minutesCtrl.text = '${lesson.estimatedMinutes}';
    _orderCtrl.text = '${lesson.orderIndex}';
    _isPublished = lesson.isPublished;
    _initialized = true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _formulaCtrl.dispose();
    _minutesCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(Lesson original) async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final updated = Lesson(
      id: original.id,
      chapterId: original.chapterId,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      formulaLatex: _formulaCtrl.text.trim(),
      estimatedMinutes: int.tryParse(_minutesCtrl.text) ?? original.estimatedMinutes,
      simulation: original.simulation,
      questions: original.questions,
      orderIndex: int.tryParse(_orderCtrl.text) ?? original.orderIndex,
      isPublished: _isPublished,
      createdAt: original.createdAt,
    );
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.saveAdminLesson(updated, isUpdate: true);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu bài học thành công!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final lesson = state.adminLessons.cast<Lesson?>().firstWhere(
      (l) => l?.id == widget.lessonId,
      orElse: () => null,
    );

    if (lesson == null) {
      if (state.isBusy) {
        return const AdminLayout(
          title: 'Bài học',
          subtitle: '',
          activeRoute: '/admin/lessons',
          child: LoadingView(message: 'Đang tải bài học...'),
        );
      }
      return AdminLayout(
        title: 'Không tìm thấy',
        subtitle: '',
        activeRoute: '/admin/lessons',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy bài học "${widget.lessonId}"',
                style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    _initControllers(lesson);

    final chapter = state.chapters.cast<Chapter?>().firstWhere(
      (c) => c?.id == lesson.chapterId,
      orElse: () => null,
    );

    return AdminLayout(
      title: lesson.title,
      subtitle: 'Chương: ${chapter?.title ?? lesson.chapterId}',
      activeRoute: '/admin/lessons',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Top action bar ──────────────────────────────────────────────
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Quay lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/admin/questions?lessonId=${lesson.id}',
                ),
                icon: const Icon(Icons.quiz_rounded, size: 16),
                label: const Text('Câu hỏi Quiz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (!_editing)
                FilledButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Chỉnh sửa'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                )
              else ...[
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          // revert controllers to lesson values
                          _titleCtrl.text = lesson.title;
                          _contentCtrl.text = lesson.content;
                          _formulaCtrl.text = lesson.formulaLatex;
                          _minutesCtrl.text = '${lesson.estimatedMinutes}';
                          _orderCtrl.text = '${lesson.orderIndex}';
                          setState(() {
                            _isPublished = lesson.isPublished;
                            _editing = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Hủy'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : () => _save(lesson),
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // ── Lesson Info Cards ──────────────────────────────────────────
          _editing
              ? _buildEditForm(lesson, chapter)
              : _buildViewContent(lesson, chapter),
        ],
      ),
    );
  }

  // ── View Mode ──────────────────────────────────────────────────────────
  Widget _buildViewContent(Lesson lesson, Chapter? chapter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta info row
        _buildCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildMetaItem(
                      icon: Icons.book_rounded,
                      label: 'Tên bài học',
                      value: lesson.title,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  Expanded(
                    child: _buildMetaItem(
                      icon: Icons.folder_rounded,
                      label: 'Chương học',
                      value: chapter?.title ?? lesson.chapterId,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  Expanded(
                    child: _buildMetaItem(
                      icon: Icons.timer_rounded,
                      label: 'Thời lượng',
                      value: '${lesson.estimatedMinutes} phút',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  Expanded(
                    child: _buildMetaItem(
                      icon: Icons.sort_rounded,
                      label: 'Thứ tự',
                      value: '${lesson.orderIndex}',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Expanded(
                    child: _buildMetaItem(
                      icon: lesson.isPublished
                          ? Icons.public_rounded
                          : Icons.public_off_rounded,
                      label: 'Trạng thái',
                      value: lesson.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                      color: lesson.isPublished
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Formula row
        if (lesson.formulaLatex.isNotEmpty) ...[
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('CÔNG THỨC CHÍNH', Icons.functions_rounded),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    lesson.formulaLatex,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Content
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel(
                'NỘI DUNG BÀI HỌC (MARKDOWN)',
                Icons.article_rounded,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  lesson.content.isEmpty
                      ? '(Chưa có nội dung)'
                      : lesson.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: lesson.content.isEmpty
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quiz summary
        _buildCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Câu hỏi Quiz',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${lesson.questions.length} câu hỏi trong bài học này',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  '/admin/questions?lessonId=${lesson.id}',
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Quản lý'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Edit Mode ──────────────────────────────────────────────────────────
  Widget _buildEditForm(Lesson lesson, Chapter? chapter) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('THÔNG TIN CƠ BẢN', Icons.info_rounded),
                const SizedBox(height: 16),

                // Title
                _buildFieldLabel('TÊN BÀI HỌC'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: _inputDeco('Nhập tiêu đề bài học'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Minutes
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('ƯỚC LƯỢNG (PHÚT)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _minutesCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _inputDeco('10'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Order
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('THỨ TỰ SẮP XẾP'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _orderCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: _inputDeco('1'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Published toggle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('TRẠNG THÁI'),
                          const SizedBox(height: 8),
                          StatefulBuilder(
                            builder: (context, setInner) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isPublished ? 'Xuất bản' : 'Nháp',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _isPublished
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  Switch(
                                    value: _isPublished,
                                    activeThumbColor: const Color(0xFF2563EB),
                                    onChanged: (v) => setState(
                                      () => _isPublished = v,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formula
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(
                  'CÔNG THỨC CHÍNH (LATEX)',
                  Icons.functions_rounded,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _formulaCtrl,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Color(0xFF7C3AED),
                  ),
                  decoration: _inputDeco('VD: p = F / S'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel(
                  'NỘI DUNG BÀI HỌC (MARKDOWN)',
                  Icons.article_rounded,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  maxLines: 20,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    height: 1.6,
                  ),
                  decoration: _inputDeco('Nhập nội dung giảng dạy...'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: child,
    );
  }

  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
