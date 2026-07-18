import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/unsaved_changes_dialog.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminChaptersScreen extends StatefulWidget {
  const AdminChaptersScreen({super.key});

  @override
  State<AdminChaptersScreen> createState() => _AdminChaptersScreenState();
}

class _AdminChaptersScreenState extends State<AdminChaptersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChapters();
    });
  }

  void _loadChapters() {
    if (!mounted) return;
    context.read<AppState>().loadAdminChapters();
  }

  String _formatDate(String? createdAtStr) {
    if (createdAtStr == null) return '01/05/2026';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      return '$day/$month/${dt.year}';
    } catch (_) {
      return '01/05/2026';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return AdminLayout(
      title: 'Quản lý Chương học',
      subtitle: 'Tất cả chương học hiện có trên hệ thống',
      activeRoute: '/admin/chapters',
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildChaptersView(state),
      ),
    );
  }

  Widget _buildChaptersView(AppState state) {
    final filteredChapters = state.chapters.where((chapter) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return chapter.title.toLowerCase().contains(q) ||
          chapter.id.toLowerCase().contains(q) ||
          chapter.description.toLowerCase().contains(q);
    }).toList();

    return state.isBusy && state.chapters.isEmpty
        ? const LoadingView(message: 'Đang tải danh sách chương học...')
        : state.errorMessage != null && state.chapters.isEmpty
        ? ErrorView(message: state.errorMessage!, onRetry: _loadChapters)
        : LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 760;
              final totalChapters = filteredChapters.length;
              final publishedChapters = filteredChapters
                  .where((c) => c.isPublished)
                  .length;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalChapters chương - $publishedChapters đã xuất bản',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showChapterFormDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Thêm chương'),
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
                  isDesktop
                      ? _buildDesktopTable(
                          filteredChapters,
                          constraints.maxWidth,
                        )
                      : _buildMobileCards(filteredChapters, state),
                ],
              );
            },
          );
  }

  Widget _buildDesktopTable(List<Chapter> chapters, double maxWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: maxWidth - 48),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            dataRowMinHeight: 60,
            dataRowMaxHeight: double.infinity,
            columns: const [
              DataColumn(
                label: Text(
                  'MÃ / TÊN CHƯƠNG',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'SỐ THỨ TỰ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'SỐ BÀI HỌC',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'TRẠNG THÁI',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'NGÀY TẠO',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'THAO TÁC',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: chapters.map((chapter) {
              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onTap: () => context.push(
                        '/admin/lessons?chapterId=${chapter.id}',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chapter.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${chapter.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              _updateChapterOrder(context, chapter, true),
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                          ),
                        ),
                        Text(
                          '${chapter.orderIndex}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () =>
                              _updateChapterOrder(context, chapter, false),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text('${chapter.lessonCount} bài học')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: chapter.isPublished
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        chapter.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                        style: TextStyle(
                          color: chapter.isPublished
                              ? const Color(0xFF065F46)
                              : const Color(0xFF92400E),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text(_formatDate(chapter.createdAt))),
                  DataCell(
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.push(
                            '/admin/lessons?chapterId=${chapter.id}',
                          ),
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                          ),
                          label: const Text('Bài học'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _showChapterFormDialog(context, chapter: chapter),
                          icon: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF2563EB),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              _confirmDeleteChapter(context, chapter.id),
                          icon: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFEF2F2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCards(List<Chapter> chapters, AppState state) {
    if (chapters.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text('Không tìm thấy chương học nào.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/admin/lessons?chapterId=${chapter.id}'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${chapter.id}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: chapter.isPublished
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          chapter.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                          style: TextStyle(
                            color: chapter.isPublished
                                ? const Color(0xFF065F46)
                                : const Color(0xFF92400E),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${chapter.lessonCount} bài học',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDate(chapter.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Lên',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _updateChapterOrder(context, chapter, true),
                            icon: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${chapter.orderIndex}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Xuống',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _updateChapterOrder(context, chapter, false),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Sửa',
                            onPressed: () => _showChapterFormDialog(
                              context,
                              chapter: chapter,
                            ),
                            icon: const Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () =>
                                _confirmDeleteChapter(context, chapter.id),
                            icon: const Icon(
                              Icons.delete_rounded,
                              size: 16,
                              color: Color(0xFFEF4444),
                            ),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => context.push(
                              '/admin/lessons?chapterId=${chapter.id}',
                            ),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                            ),
                            label: const Text(
                              'Bài học',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
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
        );
      },
    );
  }

  Future<void> _updateChapterOrder(
    BuildContext context,
    Chapter chapter,
    bool isUp,
  ) async {
    final state = Provider.of<AppState>(context, listen: false);
    final newOrder = chapter.orderIndex + (isUp ? -1 : 1);
    if (newOrder < 0) return;

    final updated = Chapter(
      id: chapter.id,
      title: chapter.title,
      description: chapter.description,
      orderIndex: newOrder,
      icon: chapter.icon,
      color: chapter.color,
      isPublished: chapter.isPublished,
    );

    await state.updateAdminChapter(updated);
  }

  Future<void> _confirmDeleteChapter(BuildContext context, String id) async {
    final state = Provider.of<AppState>(context, listen: false);
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Xóa chương học?'),
            content: const Text(
              'Tất cả bài học và câu hỏi trong chương này sẽ bị ảnh hưởng.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && context.mounted) {
      await state.deleteAdminChapter(id);
    }
  }

  Future<void> _showChapterFormDialog(
    BuildContext context, {
    Chapter? chapter,
  }) async {
    final state = Provider.of<AppState>(context, listen: false);
    final maxOrder = state.chapters.isEmpty
        ? 0
        : state.chapters
              .map((c) => c.orderIndex)
              .reduce((a, b) => a > b ? a : b);
    final defaultOrder = chapter?.orderIndex ?? (maxOrder + 1);

    final id = TextEditingController(text: chapter?.id ?? '');
    final title = TextEditingController(text: chapter?.title ?? '');
    final description = TextEditingController(text: chapter?.description ?? '');
    final order = TextEditingController(text: '$defaultOrder');
    var isPublished = chapter?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();
    final initialId = id.text.trim();
    final initialTitle = title.text.trim();
    final initialDescription = description.text.trim();
    final initialOrder = order.text.trim();
    final initialPublished = isPublished;
    bool hasChanges() =>
        id.text.trim() != initialId ||
        title.text.trim() != initialTitle ||
        description.text.trim() != initialDescription ||
        order.text.trim() != initialOrder ||
        isPublished != initialPublished;
    Future<void> requestClose(BuildContext dialogContext) async {
      final canClose = await confirmDiscardChanges(
        context: dialogContext,
        hasChanges: hasChanges(),
        title: chapter == null ? 'Hủy thêm chương?' : 'Hủy sửa chương?',
        message: 'Thông tin chương học đã nhập chưa được lưu.',
      );
      if (canClose && dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    }

    final result = await showDialog<Chapter>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (!didPop) {
              await requestClose(dialogContext);
            }
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              chapter == null
                                  ? 'Thêm Chương học'
                                  : 'Cập nhật Chương học',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            IconButton(
                              onPressed: () => requestClose(dialogContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tạo mới hoặc chỉnh sửa chương để chứa các bài học.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Divider(color: Color(0xFFF1F5F9), height: 32),
                        const Text(
                          'MÃ CHƯƠNG (ID)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: id,
                          enabled: chapter == null,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'VD: motion, force, electric',
                            filled: true,
                            fillColor: chapter == null
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFFE2E8F0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Mã chương là bắt buộc';
                            }
                            final trimmed = value.trim();
                            if (trimmed.length < 3 || trimmed.length > 50) {
                              return 'Độ dài mã chương phải từ 3 đến 50 ký tự';
                            }
                            if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(trimmed)) {
                              return 'Chỉ dùng chữ thường (a-z), số (0-9) và dấu gạch ngang (-)';
                            }
                            if (chapter == null &&
                                state.chapters.any((c) => c.id == trimmed)) {
                              return 'Mã chương đã tồn tại';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'TÊN CHƯƠNG HỌC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: 'VD: Chuyển động cơ học',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Tên chương là bắt buộc';
                            }
                            final trimmed = value.trim();
                            if (trimmed.length < 3 || trimmed.length > 100) {
                              return 'Tên chương học phải từ 3 đến 100 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'MÔ TẢ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: description,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Nhập mô tả tóm tắt nội dung chương',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Mô tả là bắt buộc';
                            }
                            final trimmed = value.trim();
                            if (trimmed.length < 5 || trimmed.length > 500) {
                              return 'Mô tả phải từ 5 đến 500 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'THƯ TỰ SẮP XẾP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: order,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Bắt buộc';
                                      }
                                      final val = int.tryParse(value.trim());
                                      if (val == null) {
                                        return 'Phải là số nguyên';
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TRẠNG THÁI',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          isPublished ? 'Xuất bản' : 'Nháp',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isPublished
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                        Switch(
                                          value: isPublished,
                                          onChanged: (val) => setDialogState(
                                            () => isPublished = val,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => requestClose(dialogContext),
                              child: const Text('Hủy'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() != true) {
                                  return;
                                }
                                Navigator.pop(
                                  dialogContext,
                                  Chapter(
                                    id: id.text.trim(),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;
    if (chapter == null) {
      await state.saveAdminChapter(result);
    } else {
      await state.updateAdminChapter(result);
    }
  }
}
