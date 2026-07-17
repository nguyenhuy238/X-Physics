import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../formula_simulation/utils/formula_calculator.dart';
import '../../formula_simulation/widgets/formula_simulation_widget.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminLessonsScreen extends StatefulWidget {
  final String? chapterId;
  const AdminLessonsScreen({super.key, this.chapterId});

  @override
  State<AdminLessonsScreen> createState() => _AdminLessonsScreenState();
}

class _AdminLessonsScreenState extends State<AdminLessonsScreen> {
  String? _selectedChapterId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedChapterId = widget.chapterId;
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
          ? const LoadingView(message: 'Đang tải bài học...')
          : state.errorMessage != null && state.adminLessons.isEmpty
              ? ErrorView(
                  message: state.errorMessage!,
                  onRetry: () => Provider.of<AppState>(context, listen: false).loadAdminLessons(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 760;
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

                        // List content
                        isDesktop
                            ? _buildDesktopTable(filteredLessons, state, constraints.maxWidth)
                            : _buildMobileCards(filteredLessons, state),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildDesktopTable(List<Lesson> lessons, AppState state, double maxWidth) {
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
          constraints: BoxConstraints(
            minWidth: maxWidth - 48,
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5), // Tên bài học
              1: FlexColumnWidth(2),   // Chương
              2: FlexColumnWidth(1.5), // Số thứ tự
              3: FixedColumnWidth(80),  // Thời gian
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
                    bottom: BorderSide(
                      color: Color(0xFFF1F5F9),
                      width: 1.5,
                    ),
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
                      bottom: BorderSide(
                        color: Color(0xFFF1F5F9),
                        width: 1,
                      ),
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
                        onTap: () => context.push('/admin/questions?lessonId=${lesson.id}'),
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
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                            onPressed: () => _updateLessonOrder(context, lesson, true),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                          ),
                          Text(
                            '${lesson.orderIndex}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => _updateLessonOrder(context, lesson, false),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
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
                          tooltip: 'Xem học sinh',
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
                        // Quiz questions edit button
                        IconButton(
                          tooltip: 'Câu hỏi Quiz',
                          onPressed: () => context.push('/admin/questions?lessonId=${lesson.id}'),
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
                          onPressed: () => context.push('/admin/lessons/${lesson.id}'),
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
            onTap: () => context.push('/admin/questions?lessonId=${lesson.id}'),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            onPressed: () => _updateLessonOrder(context, lesson, true),
                            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
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
                            onPressed: () => _updateLessonOrder(context, lesson, false),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Xem nội dung',
                            onPressed: () => context.push('/admin/lessons/${lesson.id}'),
                            icon: const Icon(Icons.description_rounded, size: 16, color: Color(0xFF2563EB)),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Xóa',
                            onPressed: () => _confirmDelete(context, lesson.id),
                            icon: const Icon(Icons.delete_rounded, size: 16, color: Color(0xFFEF4444)),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => context.push('/admin/questions?lessonId=${lesson.id}'),
                            icon: const Icon(Icons.quiz_rounded, size: 12),
                            label: const Text('Quiz', style: TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  String _formatDate(String? createdAtStr) {
    if (createdAtStr == null) return '02/05/2026';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '02/05/2026';
    }
  }

  Future<void> _updateLessonOrder(BuildContext context, Lesson lesson, bool isUp) async {
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

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xóa bài học?'),
            content: const Text('Bài học và toàn bộ tài nguyên liên quan sẽ bị xóa hoặc ẩn.'),
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
      await Provider.of<AppState>(context, listen: false).deleteAdminLesson(id);
    }
  }

  Future<void> _showLessonDialog(BuildContext context, {Lesson? lesson}) async {
    final state = Provider.of<AppState>(context, listen: false);
    final id = TextEditingController(text: lesson?.id ?? '');
    final title = TextEditingController(text: lesson?.title ?? '');
    final content = TextEditingController(text: lesson?.content ?? '');
    final formula = TextEditingController(text: lesson?.formulaLatex ?? '');
    final minutes = TextEditingController(text: '${lesson?.estimatedMinutes ?? 10}');
    
    var chapterId = lesson?.chapterId ?? _selectedChapterId ?? (state.chapters.isNotEmpty ? state.chapters.first.id : '');
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
    var simulationEnabled = lesson?.simulation.title.isNotEmpty ?? false;
    final simulation = lesson?.simulation ?? FormulaSimulationConfig.empty();
    final simTitle = TextEditingController(text: simulation.title);
    final simFormula = TextEditingController(
      text: simulation.formula.isNotEmpty ? simulation.formula : formula.text,
    );
    final resultSymbol = TextEditingController(text: simulation.result.symbol);
    final resultLabel = TextEditingController(text: simulation.result.label);
    final resultUnit = TextEditingController(text: simulation.result.unit);
    final resultExpression =
        TextEditingController(text: simulation.result.expression);
    final decimalPlaces = TextEditingController(
      text: '${simulation.result.decimalPlaces}',
    );
    final simVariables = simulation.variables
        .map(_AdminSimulationVariableDraft.fromVariable)
        .toList();

    FormulaSimulationConfig? buildSimulationConfig() {
      if (!simulationEnabled) return FormulaSimulationConfig.empty();
      final variables = <FormulaVariable>[];
      for (final variable in simVariables) {
        final min = double.tryParse(variable.min.text.trim());
        final max = double.tryParse(variable.max.text.trim());
        final step = double.tryParse(variable.step.text.trim());
        final defaultValue = double.tryParse(variable.defaultValue.text.trim());
        if (min == null || max == null || step == null || defaultValue == null) {
          return null;
        }
        variables.add(
          FormulaVariable(
            symbol: variable.symbol.text.trim(),
            label: variable.label.text.trim(),
            unit: variable.unit.text.trim(),
            min: min,
            max: max,
            step: step,
            defaultValue: defaultValue,
          ),
        );
      }
      return FormulaSimulationConfig(
        title: simTitle.text.trim(),
        formula: simFormula.text.trim(),
        variables: variables,
        result: FormulaResult(
          symbol: resultSymbol.text.trim(),
          label: resultLabel.text.trim(),
          unit: resultUnit.text.trim(),
          expression: resultExpression.text.trim(),
          decimalPlaces: int.tryParse(decimalPlaces.text.trim()) ?? 2,
        ),
      );
    }

    final result = await showDialog<Lesson>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
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
                                      initialValue: chapterId,
                                      items: [
                                        for (final chapter in state.chapters)
                                          DropdownMenuItem(
                                            value: chapter.id,
                                            child: Text(chapter.title, style: const TextStyle(fontSize: 14)),
                                          ),
                                      ],
                                      onChanged: widget.chapterId != null ? null : (value) =>
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

                      _buildSimulationSection(
                        enabled: simulationEnabled,
                        onEnabledChanged: (value) =>
                            setDialogState(() => simulationEnabled = value),
                        title: simTitle,
                        formula: simFormula,
                        resultSymbol: resultSymbol,
                        resultLabel: resultLabel,
                        resultUnit: resultUnit,
                        resultExpression: resultExpression,
                        decimalPlaces: decimalPlaces,
                        variables: simVariables,
                        previewConfig: buildSimulationConfig(),
                        setDialogState: setDialogState,
                      ),
                      const SizedBox(height: 18),

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
                                  'THƯ TỰ SẮP XẾP',
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
                                        activeThumbColor: const Color(0xFF2563EB),
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
                              if (formKey.currentState?.validate() != true) {
                                return;
                              }
                              final simulationError = _validateSimulationDraft(
                                enabled: simulationEnabled,
                                variables: simVariables,
                              );
                              if (simulationError != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(simulationError)),
                                );
                                return;
                              }
                              final simulationConfig =
                                  buildSimulationConfig() ??
                                  FormulaSimulationConfig.empty();
                              Navigator.pop(
                                dialogContext,
                                Lesson(
                                  id: id.text.trim(),
                                  chapterId: chapterId,
                                  title: title.text.trim(),
                                  content: content.text.trim(),
                                  formulaLatex: formula.text.trim(),
                                  estimatedMinutes: int.tryParse(minutes.text) ?? 10,
                                  simulation: simulationEnabled
                                      ? simulationConfig
                                      : FormulaSimulationConfig.empty(),
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

  Widget _buildSimulationSection({
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TextEditingController title,
    required TextEditingController formula,
    required TextEditingController resultSymbol,
    required TextEditingController resultLabel,
    required TextEditingController resultUnit,
    required TextEditingController resultExpression,
    required TextEditingController decimalPlaces,
    required List<_AdminSimulationVariableDraft> variables,
    required FormulaSimulationConfig? previewConfig,
    required StateSetter setDialogState,
  }) {
    String? requiredWhenEnabled(String? value, String message) {
      if (!enabled) return null;
      return value == null || value.trim().isEmpty ? message : null;
    }

    String? symbolValidator(
      String? value,
      _AdminSimulationVariableDraft variable,
    ) {
      final required = requiredWhenEnabled(value, 'Bắt buộc');
      if (required != null) return required;
      if (!enabled) return null;
      final symbol = value!.trim();
      if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(symbol)) {
        return 'Bắt đầu bằng chữ/gạch dưới';
      }
      final count = variables
          .where((item) => item.symbol.text.trim() == symbol)
          .length;
      if (count > 1) return 'Symbol bị trùng';
      return null;
    }

    String? numberValidator(String? value, String label) {
      if (!enabled) return null;
      if (value == null || value.trim().isEmpty) return '$label là bắt buộc';
      return double.tryParse(value.trim()) == null ? '$label phải là số' : null;
    }

    String? expressionValidator(String? value) {
      final required = requiredWhenEnabled(value, 'Biểu thức là bắt buộc');
      if (required != null) return required;
      if (!enabled) return null;
      final expression = value!.trim();
      if (!FormulaCalculator.isSupported(expression)) {
        return 'Biểu thức không parse được';
      }
      final symbols = variables
          .map((variable) => variable.symbol.text.trim())
          .where((symbol) => symbol.isNotEmpty)
          .toSet();
      final identifiers = RegExp(r'[A-Za-z_][A-Za-z0-9_]*')
          .allMatches(expression)
          .map((match) => match.group(0)!)
          .toSet();
      final unknown = identifiers.where((symbol) => !symbols.contains(symbol));
      return unknown.isEmpty
          ? null
          : 'Symbol chưa khai báo: ${unknown.join(', ')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MÔ PHỎNG CÔNG THỨC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: const Color(0xFF2563EB),
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: title,
              decoration: _simulationInputDecoration('Tiêu đề mô phỏng'),
              validator: (value) =>
                  requiredWhenEnabled(value, 'Tiêu đề mô phỏng là bắt buộc'),
              onChanged: (_) => setDialogState(() {}),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: formula,
              decoration: _simulationInputDecoration('Công thức LaTeX'),
              validator: (value) =>
                  requiredWhenEnabled(value, 'Công thức là bắt buộc'),
              onChanged: (_) => setDialogState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: resultSymbol,
                    decoration: _simulationInputDecoration('Ký hiệu KQ'),
                    validator: (value) {
                      final required =
                          requiredWhenEnabled(value, 'Bắt buộc');
                      if (required != null) return required;
                      if (!enabled) return null;
                      return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$')
                              .hasMatch(value!.trim())
                          ? null
                          : 'Symbol không hợp lệ';
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: resultLabel,
                    decoration: _simulationInputDecoration('Tên kết quả'),
                    validator: (value) =>
                        requiredWhenEnabled(value, 'Tên kết quả là bắt buộc'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: resultUnit,
                    decoration: _simulationInputDecoration('Đơn vị'),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: resultExpression,
                    decoration: _simulationInputDecoration('Biểu thức tính'),
                    validator: expressionValidator,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: decimalPlaces,
                    keyboardType: TextInputType.number,
                    decoration: _simulationInputDecoration('Lẻ'),
                    validator: (value) {
                      if (!enabled) return null;
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null) return 'Phải là số';
                      if (parsed < 0 || parsed > 6) return '0-6';
                      return null;
                    },
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Biến đầu vào',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setDialogState(
                    () => variables.add(_AdminSimulationVariableDraft.empty()),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Thêm biến'),
                ),
              ],
            ),
            if (variables.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Cần ít nhất một biến đầu vào.',
                  style: TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                ),
              ),
            for (final variable in variables) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: variable.symbol,
                            decoration: _simulationInputDecoration('Symbol'),
                            validator: (value) =>
                                symbolValidator(value, variable),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: variable.label,
                            decoration: _simulationInputDecoration('Label'),
                            validator: (value) =>
                                requiredWhenEnabled(value, 'Bắt buộc'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: variable.unit,
                            decoration: _simulationInputDecoration('Unit'),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Xóa biến',
                          onPressed: () => setDialogState(
                            () => variables.remove(variable),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final item in [
                          (variable.min, 'Min'),
                          (variable.max, 'Max'),
                          (variable.step, 'Step'),
                          (variable.defaultValue, 'Default'),
                        ]) ...[
                          Expanded(
                            child: TextFormField(
                              controller: item.$1,
                              keyboardType: TextInputType.number,
                              decoration: _simulationInputDecoration(item.$2),
                              validator: (value) =>
                                  numberValidator(value, item.$2),
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          if (item.$2 != 'Default') const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
            Builder(
              builder: (_) {
                final config = previewConfig;
                if (config == null ||
                    config.title.isEmpty ||
                    config.variables.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FormulaSimulationWidget(config: config),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _simulationInputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  String? _validateSimulationDraft({
    required bool enabled,
    required List<_AdminSimulationVariableDraft> variables,
  }) {
    if (!enabled) return null;
    if (variables.isEmpty) return 'Mô phỏng cần ít nhất một biến đầu vào';
    for (final variable in variables) {
      final symbol = variable.symbol.text.trim();
      final min = double.tryParse(variable.min.text.trim());
      final max = double.tryParse(variable.max.text.trim());
      final step = double.tryParse(variable.step.text.trim());
      final defaultValue = double.tryParse(variable.defaultValue.text.trim());
      if (min == null || max == null || step == null || defaultValue == null) {
        return 'Biến $symbol có giá trị số chưa hợp lệ';
      }
      if (min >= max) return 'Biến $symbol phải có min < max';
      if (step <= 0) return 'Biến $symbol phải có step > 0';
      if (defaultValue < min || defaultValue > max) {
        return 'Biến $symbol phải có default nằm trong [min, max]';
      }
    }
    return null;
  }
}

class _AdminSimulationVariableDraft {
  _AdminSimulationVariableDraft({
    required this.symbol,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
  });

  factory _AdminSimulationVariableDraft.empty() => _AdminSimulationVariableDraft(
        symbol: TextEditingController(),
        label: TextEditingController(),
        unit: TextEditingController(),
        min: TextEditingController(text: '0'),
        max: TextEditingController(text: '100'),
        step: TextEditingController(text: '1'),
        defaultValue: TextEditingController(text: '0'),
      );

  factory _AdminSimulationVariableDraft.fromVariable(FormulaVariable variable) =>
      _AdminSimulationVariableDraft(
        symbol: TextEditingController(text: variable.symbol),
        label: TextEditingController(text: variable.label),
        unit: TextEditingController(text: variable.unit),
        min: TextEditingController(text: '${variable.min}'),
        max: TextEditingController(text: '${variable.max}'),
        step: TextEditingController(text: '${variable.step}'),
        defaultValue: TextEditingController(text: '${variable.defaultValue}'),
      );

  final TextEditingController symbol;
  final TextEditingController label;
  final TextEditingController unit;
  final TextEditingController min;
  final TextEditingController max;
  final TextEditingController step;
  final TextEditingController defaultValue;
}
