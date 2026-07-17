import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({super.key});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String? _selectedChapterId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppState>(context, listen: false).loadAdminLessons();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final filteredLessons = state.adminLessons.where((l) {
      if (_selectedChapterId != null && l.chapterId != _selectedChapterId) {
        return false;
      }
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return l.title.toLowerCase().contains(q) ||
          l.id.toLowerCase().contains(q) ||
          l.content.toLowerCase().contains(q);
    }).toList();

    return AdminLayout(
      title: 'Quản lý Bài học',
      subtitle: 'Soạn nội dung, công thức và bài tập',
      activeRoute: '/admin/lessons',
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      child: state.isBusy && state.adminLessons.isEmpty
          ? const LoadingView(message: 'Đang tải lessons...')
          : state.errorMessage != null && state.adminLessons.isEmpty
              ? ErrorView(
                  message: state.errorMessage!,
                  onRetry: () => Provider.of<AppState>(context, listen: false).loadAdminLessons(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Subtitle, Dropdown Filter & "+ Thêm bài học" row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _selectedChapterId,
                                      icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Row(
                                            children: [
                                              Icon(Icons.filter_list_rounded, color: Color(0xFF64748B), size: 16),
                                              SizedBox(width: 8),
                                              Text('Tất cả chương'),
                                            ],
                                          ),
                                        ),
                                        ...state.chapters.map((chapter) => DropdownMenuItem<String?>(
                                          value: chapter.id,
                                          child: Text(chapter.title),
                                        )),
                                      ],
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedChapterId = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${filteredLessons.length} bài học',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.icon(
                              onPressed: state.chapters.isEmpty
                                  ? null
                                  : () => _showLessonDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Thêm bài học'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Table Card
                        Container(
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
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),   // Tên bài học
                                  1: FlexColumnWidth(2),   // Chương
                                  2: FlexColumnWidth(3),   // Tóm tắt
                                  3: FixedColumnWidth(80),  // Thời gian
                                  4: FixedColumnWidth(130), // Trạng thái
                                  5: FixedColumnWidth(130), // Ngày tạo
                                  6: FixedColumnWidth(150), // Thao tác
                                },
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: [
                                  // Table Headers Row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFF1F5F9),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      _buildHeaderCell('TÊN BÀI HỌC', alignment: TextAlign.left),
                                      _buildHeaderCell('CHƯƠNG', alignment: TextAlign.left),
                                      _buildHeaderCell('TÓM TẮT', alignment: TextAlign.left),
                                      _buildHeaderCell('THỜI GIAN'),
                                      _buildHeaderCell('TRẠNG THÁI'),
                                      _buildHeaderCell('NGÀY TẠO'),
                                      _buildHeaderCell('THAO TÁC'),
                                    ],
                                  ),

                                  // Table Data Rows
                                  for (final lesson in filteredLessons)
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFF1F5F9),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        // Tên bài học
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          child: Text(
                                            lesson.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        // Chương
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            _getChapterTitle(state, lesson.chapterId),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        // Tóm tắt (derived from markdown description)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            _getSummary(lesson),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                        // Thời gian (m)
                                        Center(
                                          child: Text(
                                            '${lesson.estimatedMinutes}m',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        // Trạng thái capsule
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: lesson.isPublished
                                                  ? const Color(0xFFD1FAE5)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              lesson.isPublished ? 'Đã xuất bản' : 'Nháp',
                                              style: TextStyle(
                                                color: lesson.isPublished
                                                    ? const Color(0xFF065F46)
                                                    : const Color(0xFF92400E),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Ngày tạo
                                        Center(
                                          child: Text(
                                            _formatDate(lesson.createdAt),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // Thao tác circle actions
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // View details button (Eye icon)
                                            IconButton(
                                              onPressed: () => context.push('/lessons/${lesson.id}'),
                                              icon: const Icon(Icons.visibility_rounded),
                                              iconSize: 15,
                                              color: const Color(0xFF64748B),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFF1F5F9),
                                                padding: const EdgeInsets.all(6),
                                                minimumSize: const Size(28, 28),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Edit button
                                            IconButton(
                                              onPressed: () => _showLessonDialog(context, lesson: lesson),
                                              icon: const Icon(Icons.edit_rounded),
                                              iconSize: 15,
                                              color: const Color(0xFF2563EB),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFEFF6FF),
                                                padding: const EdgeInsets.all(6),
                                                minimumSize: const Size(28, 28),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Delete button
                                            IconButton(
                                              onPressed: () => _confirmDelete(context, lesson.id),
                                              icon: const Icon(Icons.delete_rounded),
                                              iconSize: 15,
                                              color: const Color(0xFFEF4444),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEF2F2),
                                                padding: const EdgeInsets.all(6),
                                                minimumSize: const Size(28, 28),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildHeaderCell(String label, {TextAlign alignment = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Text(
        label,
        textAlign: alignment,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  String _getChapterTitle(AppState state, String chapterId) {
    final chapter = state.chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => const Chapter(id: '', title: '', description: ''),
    );
    return chapter.title.isEmpty ? 'Không rõ' : chapter.title;
  }

  String _getSummary(Lesson lesson) {
    String content = lesson.content;
    content = content
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'\*'), '')
        .replaceAll(RegExp(r'\$'), '')
        .replaceAll(RegExp(r'\n'), ' ')
        .trim();
    if (content.length > 50) {
      return '${content.substring(0, 48)}...';
    }
    return content.isEmpty ? 'Không có mô tả' : content;
  }

  String _formatDate(String? createdAtStr) {
    if (createdAtStr == null) return '02/05/2026';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '02/05/2026';
    }
  }

  Future<void> _showLessonDialog(BuildContext context, {Lesson? lesson}) async {
    final state = Provider.of<AppState>(context, listen: false);
    final id = TextEditingController(text: lesson?.id ?? '');
    final title = TextEditingController(text: lesson?.title ?? '');
    final content = TextEditingController(text: lesson?.content ?? '');
    final formula = TextEditingController(text: lesson?.formulaLatex ?? '');
    final minutes = TextEditingController(text: '${lesson?.estimatedMinutes ?? 10}');
    
    // Auto-calculate default order index for new lesson under selected chapter
    var chapterId = lesson?.chapterId ?? state.chapters.first.id;
    final maxOrder = state.adminLessons.where((l) => l.chapterId == chapterId).isEmpty
        ? 0
        : state.adminLessons
            .where((l) => l.chapterId == chapterId)
            .map((l) => l.orderIndex)
            .reduce((a, b) => a > b ? a : b);
    final defaultOrder = lesson?.orderIndex ?? (maxOrder + 1);
    final order = TextEditingController(text: '$defaultOrder');
    
    var isPublished = lesson?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Lesson>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lesson == null ? 'Thêm Bài học mới' : 'Cập nhật Bài học',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF64748B),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập thông tin chi tiết bài học lý thuyết vật lý.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 32),

                      // ID & Chapter Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MÃ BÀI HỌC (ID)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: id,
                                  enabled: lesson == null,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: 'VD: force-1',
                                    filled: true,
                                    fillColor: lesson == null ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) {
                                     if (value == null || value.trim().isEmpty) {
                                       return 'Mã bài học là bắt buộc';
                                     }
                                     final trimmed = value.trim();
                                     if (trimmed.length < 3 || trimmed.length > 50) {
                                       return 'Độ bài học phải từ 3 đến 50 ký tự';
                                     }
                                     if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(trimmed)) {
                                       return 'Chỉ dùng chữ thường (a-z), số (0-9) và dấu gạch ngang (-)';
                                     }
                                     if (lesson == null && state.adminLessons.any((l) => l.id == trimmed)) {
                                       return 'Mã bài học đã tồn tại';
                                     }
                                     return null;
                                   },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHƯƠNG HỌC',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButtonFormField<String>(
                                      value: chapterId,
                                      items: [
                                        for (final chapter in state.chapters)
                                          DropdownMenuItem(
                                            value: chapter.id,
                                            child: Text(chapter.title, style: const TextStyle(fontSize: 14)),
                                          ),
                                      ],
                                      onChanged: (value) =>
                                          setDialogState(() => chapterId = value ?? chapterId),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Title Field
                      const Text(
                        'TÊN BÀI HỌC',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: title,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề bài học',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tên bài học là bắt buộc';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 3 || trimmed.length > 100) {
                            return 'Tên bài học phải từ 3 đến 100 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Content Field
                      const Text(
                        'NỘI DUNG CHI TIẾT (MARKDOWN)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: content,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Nhập nội dung giảng dạy của bài học...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nội dung là bắt buộc';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length < 10 || trimmed.length > 10000) {
                            return 'Nội dung bài học phải từ 10 đến 10000 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Formula Field
                      const Text(
                        'CÔNG THỨC CHÍNH (LATEX)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: formula,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: 'VD: p = F / S',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value != null && value.trim().length > 500) {
                            return 'Công thức tối đa 500 ký tự';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Minutes, Order & Publish Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ƯỚC LƯỢNG (PHÚT)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: minutes,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Bắt buộc';
                                    }
                                    final val = int.tryParse(value.trim());
                                    if (val == null) {
                                      return 'Phải là số';
                                    }
                                    if (val < 1 || val > 180) {
                                      return 'Ước lượng từ 1 đến 180 phút';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'THỨ TỰ SẮP XẾP',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: order,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Bắt buộc';
                                    }
                                    final val = int.tryParse(value.trim());
                                    if (val == null) {
                                      return 'Phải là số';
                                    }
                                    if (val < 0) {
                                      return 'Phải >= 0';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TRẠNG THÁI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isPublished ? 'Xuất bản' : 'Nháp',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        ),
                                      ),
                                      Switch(
                                        value: isPublished,
                                        activeColor: const Color(0xFF2563EB),
                                        onChanged: (value) =>
                                            setDialogState(() => isPublished = value),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            child: const Text(
                              'Hủy bỏ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() != true) return;
                              Navigator.pop(
                                dialogContext,
                                Lesson(
                                  id: id.text.trim(),
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: const Text(
                              'Lưu bài học',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    await Provider.of<AppState>(context, listen: false).saveAdminLesson(
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
            title: const Text('Xóa bài học?'),
            content: const Text('Bài học và toàn bộ tài nguyên liên quan sẽ bị xóa hoặc ẩn.'),
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
      await Provider.of<AppState>(context, listen: false).deleteAdminLesson(id);
    }
  }
}
