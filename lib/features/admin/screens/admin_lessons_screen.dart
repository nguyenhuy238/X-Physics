import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminLessonsScreen extends StatefulWidget {
  const AdminLessonsScreen({
    super.key,
    this.chapterId,
    this.status,
    this.search,
  });

  final String? chapterId;
  final String? status;
  final String? search;

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String? _selectedChapterId;
  String? _selectedStatus;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _selectedChapterId = widget.chapterId;
    _selectedStatus = _normalizeStatus(widget.status);
    _searchQuery = widget.search ?? '';
    _searchController.text = _searchQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AppState>(context, listen: false).loadAdminLessons();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdminLessonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextStatus = _normalizeStatus(widget.status);
    if (widget.chapterId != _selectedChapterId ||
        nextStatus != _selectedStatus ||
        (widget.search ?? '') != _searchQuery) {
      _selectedChapterId = widget.chapterId;
      _selectedStatus = nextStatus;
      _searchQuery = widget.search ?? '';
      if (_searchController.text != _searchQuery) {
        _searchController.text = _searchQuery;
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedChapter = _selectedChapter(state);
    final filteredLessons = state.adminLessons.where((l) {
      if (_selectedChapterId != null && l.chapterId != _selectedChapterId) {
        return false;
      }
      if (_selectedStatus == 'published' && !l.isPublished) {
        return false;
      }
      if (_selectedStatus == 'draft' && l.isPublished) {
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
      subtitle: selectedChapter == null
          ? 'Soạn nội dung, công thức và bài tập'
          : 'Đang lọc theo chương ${selectedChapter.title}',
      activeRoute: '/admin/lessons',
      backFallbackRoute: selectedChapter == null ? '/admin' : '/admin/chapters',
      breadcrumbs: [
        const AdminBreadcrumbItem(label: 'Quản lý nội dung'),
        if (selectedChapter != null)
          AdminBreadcrumbItem(
            label: selectedChapter.title,
            route: '/admin/chapters',
          ),
        const AdminBreadcrumbItem(label: 'Bài học'),
      ],
      searchController: _searchController,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
        _searchDebounce?.cancel();
        _searchDebounce = Timer(
          const Duration(milliseconds: 420),
          () => _updateLocation(),
        );
      },
      child: state.isBusy && state.adminLessons.isEmpty
          ? const LoadingView(message: 'Đang tải bài học...')
          : state.errorMessage != null && state.adminLessons.isEmpty
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => Provider.of<AppState>(
                context,
                listen: false,
              ).loadAdminLessons(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 760;
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildToolbar(state, filteredLessons.length),
                    const SizedBox(height: 18),

                    // List content
                    isDesktop
                        ? _buildDesktopTable(
                            filteredLessons,
                            state,
                            constraints.maxWidth,
                          )
                        : _buildMobileCards(filteredLessons, state),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDesktopTable(
    List<Lesson> lessons,
    AppState state,
    double maxWidth,
  ) {
    return Container(
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
          constraints: BoxConstraints(minWidth: maxWidth - 48),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Tên bài học
              1: FlexColumnWidth(2), // Chương
              2: FlexColumnWidth(1.5), // Số thứ tự
              3: FixedColumnWidth(80), // Thời gian
              4: FixedColumnWidth(130), // Trạng thái
              5: FixedColumnWidth(130), // Ngày tạo
              6: FixedColumnWidth(180), // Thao tác
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Table Headers Row
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
                  ),
                ),
                children: [
                  _buildHeaderCell('TÊN BÀI HỌC', alignment: TextAlign.left),
                  _buildHeaderCell('CHƯƠNG', alignment: TextAlign.left),
                  _buildHeaderCell('SỐ THỨ TỰ'),
                  _buildHeaderCell('THỜI GIAN'),
                  _buildHeaderCell('TRẠNG THÁI'),
                  _buildHeaderCell('NGÀY TẠO'),
                  _buildHeaderCell('THAO TÁC'),
                ],
              ),

              // Table Data Rows
              for (final lesson in lessons)
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                  ),
                  children: [
                    // Tên bài học clickable
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: InkWell(
                        onTap: () => context.push(_lessonDetailRoute(lesson)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lesson.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${lesson.id}',
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
                    // Chương
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _getChapterTitle(state, lesson.chapterId),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Số thứ tự reorder
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                _updateLessonOrder(context, lesson, true),
                            icon: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 18,
                            ),
                          ),
                          Text(
                            '${lesson.orderIndex}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () =>
                                _updateLessonOrder(context, lesson, false),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                          ),
                        ],
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
                          tooltip: 'Xem bài học phía học sinh',
                          onPressed: () =>
                              context.push('/lessons/${lesson.id}'),
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
                        // Quiz questions edit button
                        IconButton(
                          tooltip: 'Câu hỏi Quiz',
                          onPressed: () =>
                              context.push(_questionsRoute(lesson)),
                          icon: const Icon(Icons.quiz_rounded),
                          iconSize: 15,
                          color: const Color(0xFFF59E0B),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFBEB),
                            padding: const EdgeInsets.all(6),
                            minimumSize: const Size(28, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // View content button
                        IconButton(
                          tooltip: 'Xem nội dung',
                          onPressed: () =>
                              context.push(_lessonDetailRoute(lesson)),
                          icon: const Icon(Icons.description_rounded),
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
                          tooltip: 'Xóa',
                          onPressed: () => _confirmDelete(context, lesson),
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
    );
  }

  Widget _buildMobileCards(List<Lesson> lessons, AppState state) {
    if (lessons.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text('Không tìm thấy bài học nào.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
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
            onTap: () => context.push(_lessonDetailRoute(lesson)),
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
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${lesson.id} • ${_getChapterTitle(state, lesson.chapterId)}',
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
                          color: lesson.isPublished
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          lesson.isPublished ? 'Đã xuất bản' : 'Bản nháp',
                          style: TextStyle(
                            color: lesson.isPublished
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
                        '${lesson.estimatedMinutes} phút đọc',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDate(lesson.createdAt),
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
                                _updateLessonOrder(context, lesson, true),
                            icon: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${lesson.orderIndex}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Xuống',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _updateLessonOrder(context, lesson, false),
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
                            tooltip: 'Xem nội dung',
                            onPressed: () =>
                                context.push(_lessonDetailRoute(lesson)),
                            icon: const Icon(
                              Icons.description_rounded,
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
                            onPressed: () => _confirmDelete(context, lesson),
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
                            onPressed: () =>
                                context.push(_questionsRoute(lesson)),
                            icon: const Icon(Icons.quiz_rounded, size: 12),
                            label: const Text(
                              'Quiz',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
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

  Widget _buildHeaderCell(
    String label, {
    TextAlign alignment = TextAlign.center,
  }) {
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

  Widget _buildToolbar(AppState state, int total) {
    final chapterValue = state.chapters.any((c) => c.id == _selectedChapterId)
        ? _selectedChapterId
        : null;
    final hasFilter =
        chapterValue != null ||
        _selectedStatus != null ||
        _searchQuery.trim().isNotEmpty;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
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
              value: chapterValue,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Color(0xFF64748B),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text('Tất cả chương'),
                    ],
                  ),
                ),
                ...state.chapters.map(
                  (chapter) => DropdownMenuItem<String?>(
                    value: chapter.id,
                    child: Text(chapter.title),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedChapterId = value);
                _updateLocation();
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedStatus,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: Color(0xFF64748B),
              ),
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Tất cả trạng thái'),
                ),
                DropdownMenuItem(
                  value: 'published',
                  child: Text('Đã xuất bản'),
                ),
                DropdownMenuItem(value: 'draft', child: Text('Bản nháp')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _updateLocation();
              },
            ),
          ),
        ),
        Text(
          '$total bài học',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (hasFilter)
          TextButton.icon(
            onPressed: () {
              _searchDebounce?.cancel();
              setState(() {
                _selectedChapterId = null;
                _selectedStatus = null;
                _searchQuery = '';
                _searchController.clear();
              });
              _updateLocation();
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Xem tất cả bài học'),
          ),
        FilledButton.icon(
          onPressed: state.chapters.isEmpty
              ? null
              : () => context.push(
                  Uri(
                    path: '/admin/lessons/new',
                    queryParameters: {
                      if (_selectedChapterId != null &&
                          _selectedChapterId!.isNotEmpty)
                        'chapterId': _selectedChapterId!,
                    },
                  ).toString(),
                ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm bài học'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Chapter? _selectedChapter(AppState state) {
    final id = _selectedChapterId;
    if (id == null || id.isEmpty) return null;
    return state.chapters.cast<Chapter?>().firstWhere(
      (chapter) => chapter?.id == id,
      orElse: () => null,
    );
  }

  String? _normalizeStatus(String? value) {
    return value == 'published' || value == 'draft' ? value : null;
  }

  void _updateLocation() {
    if (!mounted) return;
    final query = <String, String>{};
    final chapterId = _selectedChapterId;
    final status = _selectedStatus;
    final search = _searchQuery.trim();
    if (chapterId != null && chapterId.isNotEmpty) {
      query['chapterId'] = chapterId;
    }
    if (status != null) {
      query['status'] = status;
    }
    if (search.isNotEmpty) {
      query['search'] = search;
    }
    context.go(Uri(path: '/admin/lessons', queryParameters: query).toString());
  }

  String _lessonDetailRoute(Lesson lesson) {
    final query = <String, String>{'from': 'lessons'};
    final chapterId = _selectedChapterId;
    if (chapterId != null && chapterId.isNotEmpty) {
      query['chapterId'] = chapterId;
    }
    return Uri(
      path: '/admin/lessons/${lesson.id}',
      queryParameters: query,
    ).toString();
  }

  String _questionsRoute(Lesson lesson) {
    final query = <String, String>{
      'lessonId': lesson.id,
      'chapterId': lesson.chapterId,
    };
    return Uri(path: '/admin/questions', queryParameters: query).toString();
  }

  String _getChapterTitle(AppState state, String chapterId) {
    final chapter = state.chapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => const Chapter(id: '', title: '', description: ''),
    );
    return chapter.title.isEmpty ? 'Không rõ' : chapter.title;
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

  Future<void> _updateLessonOrder(
    BuildContext context,
    Lesson lesson,
    bool isUp,
  ) async {
    final state = Provider.of<AppState>(context, listen: false);
    final newOrder = lesson.orderIndex + (isUp ? -1 : 1);
    if (newOrder < 0) return;

    final updated = Lesson(
      id: lesson.id,
      chapterId: lesson.chapterId,
      title: lesson.title,
      content: lesson.content,
      formulaLatex: lesson.formulaLatex,
      estimatedMinutes: lesson.estimatedMinutes,
      simulation: lesson.simulation,
      questions: lesson.questions,
      orderIndex: newOrder,
      isPublished: lesson.isPublished,
    );

    await state.saveAdminLesson(updated, isUpdate: true);
  }

  Future<void> _confirmDelete(BuildContext context, Lesson lesson) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Xóa bài học?'),
            content: Text(
              'Bạn sắp xóa "${lesson.title}". Bài học và toàn bộ tài nguyên liên quan sẽ bị xóa hoặc ẩn.',
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
      await Provider.of(context, listen: false).deleteAdminLesson(lesson.id);
    }
  }
}
