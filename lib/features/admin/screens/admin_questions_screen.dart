import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_design.dart';
import '../widgets/admin_layout.dart';

class AdminQuestionsScreen extends StatefulWidget {
  final String? lessonId;
  const AdminQuestionsScreen({super.key, this.lessonId});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  var _questions = <Question>[];
  var _page = 1;
  var _limit = 20;
  var _total = 0;
  var _totalPages = 0;
  var _requestSerial = 0;
  var _initialLoading = true;
  var _refreshing = false;
  var _pageLoading = false;
  var _saving = false;
  String? _error;
  String? _chapterId;
  String? _lessonId;
  String? _difficulty;
  String? _deletingQuestionId;

  bool get _hasFilters =>
      _chapterId != null ||
      _lessonId != null ||
      _difficulty != null ||
      _search.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _lessonId = widget.lessonId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceData();
      _loadQuestions(initial: true);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    final state = context.read<AppState>();
    if (state.chapters.isEmpty) {
      await state.loadAdminChapters();
    }
    if (state.adminLessons.isEmpty) {
      await state.loadAdminLessons();
    }
    if (_lessonId != null && _chapterId == null) {
      final lesson = state.adminLessons.firstWhere(
        (l) => l.id == _lessonId,
        orElse: () => Lesson(
          id: '',
          chapterId: '',
          title: '',
          content: '',
          formulaLatex: '',
          estimatedMinutes: 0,
          simulation: FormulaSimulationConfig.empty(),
          questions: const [],
          orderIndex: 0,
          isPublished: false,
        ),
      );
      if (lesson.id.isNotEmpty && mounted) {
        setState(() {
          _chapterId = lesson.chapterId;
        });
      }
    }
  }

  Future<void> _loadQuestions({
    bool initial = false,
    bool refresh = false,
    bool pageChange = false,
  }) async {
    final serial = ++_requestSerial;
    setState(() {
      _error = null;
      _initialLoading = initial;
      _refreshing = refresh;
      _pageLoading = pageChange;
    });
    try {
      final state = context.read<AppState>();
      final result = await state.fetchAdminQuestions(
        lessonId: _lessonId,
        chapterId: _chapterId,
        search: _search.text,
        difficulty: _difficulty,
        page: _page,
        limit: _limit,
      );
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _questions = result.items;
        _page = result.page;
        _limit = result.limit;
        _total = result.total;
        _totalPages = result.totalPages;
      });
    } catch (error) {
      if (!mounted || serial != _requestSerial) return;
      setState(() => _error = context.read<AppState>().readableError(error));
    } finally {
      if (mounted && serial == _requestSerial) {
        setState(() {
          _initialLoading = false;
          _refreshing = false;
          _pageLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 420), () {
      _page = 1;
      _loadQuestions(refresh: _questions.isNotEmpty);
    });
  }

  void _resetFilters() {
    setState(() {
      _chapterId = null;
      _lessonId = null;
      _difficulty = null;
      _search.clear();
      _page = 1;
    });
    _loadQuestions(refresh: _questions.isNotEmpty, initial: _questions.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.canAccessAdmin) {
      return const Scaffold(
        body: ErrorView(message: 'Bạn không có quyền truy cập Admin.'),
      );
    }

    final lesson = state.adminLessons.firstWhere(
      (l) => l.id == widget.lessonId,
      orElse: () => Lesson(
        id: '',
        chapterId: '',
        title: '',
        content: '',
        formulaLatex: '',
        estimatedMinutes: 0,
        simulation: FormulaSimulationConfig.empty(),
        questions: const [],
        orderIndex: 0,
        isPublished: false,
      ),
    );
    final lessonTitle = lesson.title.isNotEmpty ? lesson.title : 'Bài học';

    return AdminLayout(
      activeRoute: '/admin/questions',
      title: widget.lessonId != null ? 'Câu hỏi: $lessonTitle' : 'Quản lý Câu hỏi',
      subtitle: widget.lessonId != null ? 'Danh sách câu hỏi trắc nghiệm' : 'Ngân hàng câu hỏi trắc nghiệm',
      onSearchChanged: _onSearchChanged,
      child: RefreshIndicator(
        onRefresh: () => _loadQuestions(refresh: true),
        child: ListView(
          padding: const EdgeInsets.all(AdminDesign.pagePadding),
          children: [
            _Toolbar(
              total: _total,
              selectedChapterId: _chapterId,
              selectedLessonId: _lessonId,
              selectedDifficulty: _difficulty,
              onChapterChanged: _setChapter,
              onLessonChanged: _setLesson,
              onDifficultyChanged: _setDifficulty,
              onClear: _hasFilters ? _resetFilters : null,
              onAdd: state.adminLessons.isEmpty ? null : () => _openForm(),
              searchController: _search,
              onSearchChanged: _onSearchChanged,
              reorderEnabled: _lessonId != null && _questions.isNotEmpty,
              onReorder: _lessonId == null || _questions.isEmpty
                  ? null
                  : () => _openReorderDialog(),
              hideLessonFilters: widget.lessonId != null,
            ),
            const SizedBox(height: 22),
            if (_initialLoading)
              const _TableCard(
                child: LoadingView(message: 'Đang tải câu hỏi...'),
              )
            else if (_error != null && _questions.isEmpty)
              _TableCard(
                child: ErrorView(
                  message: _friendlyError(_error!),
                  onRetry: () => _loadQuestions(initial: true),
                ),
              )
            else if (_questions.isEmpty)
              _TableCard(
                child: _EmptyQuestionsView(
                  message: _hasFilters
                      ? 'Không tìm thấy câu hỏi phù hợp.'
                      : 'Chưa có câu hỏi nào.',
                  onAction: _hasFilters ? _resetFilters : null,
                ),
              )
            else
              Stack(
                children: [
                  _QuestionTableCard(
                    questions: _questions,
                    page: _page,
                    limit: _limit,
                    total: _total,
                    totalPages: _totalPages,
                    deletingQuestionId: _deletingQuestionId,
                    onView: _openDetail,
                    onEdit: (question) => _openForm(question: question),
                    onDelete: _confirmDelete,
                    onPrevious: _page > 1
                        ? () {
                            setState(() => _page -= 1);
                            _loadQuestions(pageChange: true);
                          }
                        : null,
                    onNext: _page < _totalPages
                        ? () {
                            setState(() => _page += 1);
                            _loadQuestions(pageChange: true);
                          }
                        : null,
                  ),
                  if (_refreshing || _pageLoading)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            if (_error != null && _questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _friendlyError(_error!),
                  style: const TextStyle(color: AdminDesign.danger),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setChapter(String? value) {
    setState(() {
      _chapterId = value;
      final lessons = _filteredLessonsFor(value);
      if (_lessonId != null &&
          !lessons.any((lesson) => lesson.id == _lessonId)) {
        _lessonId = null;
      }
      _page = 1;
    });
    _loadQuestions(refresh: _questions.isNotEmpty, initial: _questions.isEmpty);
  }

  void _setLesson(String? value) {
    setState(() {
      _lessonId = value;
      _page = 1;
    });
    _loadQuestions(refresh: _questions.isNotEmpty, initial: _questions.isEmpty);
  }

  void _setDifficulty(String? value) {
    setState(() {
      _difficulty = value;
      _page = 1;
    });
    _loadQuestions(refresh: _questions.isNotEmpty, initial: _questions.isEmpty);
  }

  List<Lesson> _filteredLessonsFor(String? chapterId) {
    final lessons = context.read<AppState>().adminLessons;
    if (chapterId == null) return lessons;
    return lessons.where((lesson) => lesson.chapterId == chapterId).toList();
  }

  Future<void> _openDetail(Question question) async {
    Question detail = question;
    try {
      detail = await context.read<AppState>().fetchAdminQuestionDetail(
        question.id,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(context.read<AppState>().readableError(error)),
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _QuestionDetailDialog(question: detail),
    );
  }

  Future<void> _openForm({Question? question, Question? draft}) async {
    final isUpdate = question != null;
    final result = await showDialog<Question>(
      context: context,
      barrierDismissible: !_saving,
      builder: (_) => _QuestionFormDialog(
        question: draft ?? question,
        isUpdate: isUpdate,
        saving: _saving,
        defaultChapterId: _chapterId,
        defaultLessonId: _lessonId,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().writeAdminQuestion(
        result,
        isUpdate: isUpdate,
      );
      if (!mounted) return;
      await _loadQuestions(
        refresh: _questions.isNotEmpty,
        initial: _questions.isEmpty,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            question == null ? 'Đã thêm câu hỏi.' : 'Đã lưu câu hỏi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(context.read<AppState>().readableError(error)),
          ),
        ),
      );
      await _openForm(question: question, draft: result);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete(Question question) async {
    final ok =
        await showDialog<bool>(
          context: context,
          barrierDismissible: _deletingQuestionId == null,
          builder: (_) => _DeleteQuestionDialog(question: question),
        ) ??
        false;
    if (!ok || !mounted) return;
    setState(() => _deletingQuestionId = question.id);
    try {
      await context.read<AppState>().removeAdminQuestion(question.id);
      if (!mounted) return;
      final nextTotal = _total - 1;
      if (_questions.length == 1 &&
          _page > 1 &&
          nextTotal <= (_page - 1) * _limit) {
        _page -= 1;
      }
      await _loadQuestions(refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa câu hỏi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(context.read<AppState>().readableError(error)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingQuestionId = null);
    }
  }

  Future<void> _openReorderDialog() async {
    final lessonId = _lessonId;
    if (lessonId == null) return;
    final orderedQuestions = [..._questions]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _QuestionReorderDialog(questions: orderedQuestions),
    );
    if (result == null || !mounted) return;
    try {
      await context.read<AppState>().reorderAdminQuestions(
        lessonId: lessonId,
        questionIds: result,
      );
      if (!mounted) return;
      await _loadQuestions(refresh: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã sắp xếp câu hỏi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(context.read<AppState>().readableError(error)),
          ),
        ),
      );
      await _openReorderDialog();
    }
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.total,
    required this.selectedChapterId,
    required this.selectedLessonId,
    required this.selectedDifficulty,
    required this.onChapterChanged,
    required this.onLessonChanged,
    required this.onDifficultyChanged,
    required this.onClear,
    required this.onAdd,
    required this.searchController,
    required this.onSearchChanged,
    required this.reorderEnabled,
    required this.onReorder,
    this.hideLessonFilters = false,
  });

  final int total;
  final String? selectedChapterId;
  final String? selectedLessonId;
  final String? selectedDifficulty;
  final ValueChanged<String?> onChapterChanged;
  final ValueChanged<String?> onLessonChanged;
  final ValueChanged<String?> onDifficultyChanged;
  final VoidCallback? onClear;
  final VoidCallback? onAdd;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool reorderEnabled;
  final VoidCallback? onReorder;
  final bool hideLessonFilters;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chapters = _uniqueById(state.chapters, (chapter) => chapter.id);
    final chapterValue = _validDropdownValue(
      selectedChapterId,
      chapters.map((chapter) => chapter.id),
    );
    final allLessons = _uniqueById(state.adminLessons, (lesson) => lesson.id);
    final lessons = chapterValue == null
        ? allLessons
        : allLessons
              .where((lesson) => lesson.chapterId == chapterValue)
              .toList();
    final lessonValue = _validDropdownValue(
      selectedLessonId,
      lessons.map((lesson) => lesson.id),
    );
    final difficultyValue = _validDropdownValue(
      selectedDifficulty,
      const ['EASY', 'MEDIUM', 'HARD'],
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!hideLessonFilters) ...[
          _FilterPill(
            width: 210,
            icon: Icons.filter_alt_outlined,
            value: selectedChapterId,
            hint: 'Tất cả chương',
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tất cả chương'),
              ),
              for (final chapter in state.chapters)
                DropdownMenuItem(value: chapter.id, child: Text(chapter.title)),
            ],
            onChanged: onChapterChanged,
          ),
          _FilterPill(
            width: 230,
            icon: Icons.filter_alt_outlined,
            value: selectedLessonId,
            hint: 'Tất cả bài học',
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tất cả bài học'),
              ),
              for (final lesson in lessons)
                DropdownMenuItem(value: lesson.id, child: Text(lesson.title)),
            ],
            onChanged: onLessonChanged,
          ),
          _FilterPill(
            width: 160,
            icon: Icons.tune_rounded,
            value: selectedDifficulty,
            hint: 'Độ khó',
            items: const [
              DropdownMenuItem<String>(value: null, child: Text('Tất cả độ khó')),
              DropdownMenuItem(value: 'EASY', child: Text('Dễ')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Trung bình')),
              DropdownMenuItem(value: 'HARD', child: Text('Khó')),
            ],
            onChanged: onDifficultyChanged,
          ),
        ],
        SizedBox(
          width: 240,
          height: 48,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminDesign.pillRadius),
                borderSide: const BorderSide(color: AdminDesign.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminDesign.pillRadius),
                borderSide: const BorderSide(color: AdminDesign.border),
              ),
            ),
          ),
        ),
        Text(
          '$total câu hỏi',
          style: const TextStyle(
            color: AdminDesign.mutedText,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (!hideLessonFilters && onClear != null)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Xóa bộ lọc'),
          ),
        Tooltip(
          message: reorderEnabled
              ? 'Sắp xếp câu hỏi trong bài học'
              : 'Chọn một bài học để sắp xếp câu hỏi',
          child: OutlinedButton.icon(
            onPressed: reorderEnabled ? onReorder : null,
            icon: const Icon(Icons.swap_vert_rounded),
            label: const Text('Sắp xếp'),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: onAdd,
          style: FilledButton.styleFrom(
            backgroundColor: AdminDesign.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Thêm câu hỏi'),
        ),
      ],
    );
  }
}

class _QuestionTableCard extends StatelessWidget {
  const _QuestionTableCard({
    required this.questions,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.deletingQuestionId,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.onPrevious,
    required this.onNext,
  });

  final List<Question> questions;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String? deletingQuestionId;
  final ValueChanged<Question> onView;
  final ValueChanged<Question> onEdit;
  final ValueChanged<Question> onDelete;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return _TableCard(
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  AdminDesign.tableHeader,
                ),
                headingTextStyle: const TextStyle(
                  color: AdminDesign.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                dataRowMinHeight: 60,
                dataRowMaxHeight: double.infinity,
                columnSpacing: 28,
                horizontalMargin: 22,
                dividerThickness: .6,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('CÂU HỎI')),
                  DataColumn(label: Text('BÀI HỌC')),
                  DataColumn(label: Text('ĐÁP ÁN ĐÚNG')),
                  DataColumn(label: Text('ĐỘ KHÓ')),
                  DataColumn(label: Text('NGÀY TẠO')),
                  DataColumn(label: Text('THAO TÁC')),
                ],
                rows: [
                  for (var i = 0; i < questions.length; i++)
                    _questionRow(
                      context,
                      questions[i],
                      (page - 1) * limit + i + 1,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Row(
              children: [
                Text(
                  'Trang $page/$totalPages • $total câu hỏi',
                  style: const TextStyle(color: AdminDesign.mutedText),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onPrevious,
                  child: const Text('Trước'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: onNext, child: const Text('Sau')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _questionRow(BuildContext context, Question question, int index) {
    final deleting = deletingQuestionId == question.id;
    return DataRow(
      cells: [
        DataCell(
          Text('$index', style: const TextStyle(color: AdminDesign.mutedText)),
        ),
        DataCell(
          SizedBox(
            width: 280,
            child: Tooltip(
              message: question.question,
              child: Text(
                question.question,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: 130,
            child: Text(question.lessonTitleOrId, maxLines: 2),
          ),
        ),
        DataCell(_CorrectAnswerText(question: question)),
        DataCell(_DifficultyChip(difficulty: question.difficulty)),
        DataCell(Text(_formatDate(question.createdAt))),
        DataCell(
          Row(
            children: [
              _ActionButton(
                tooltip: 'Xem',
                icon: Icons.visibility_outlined,
                color: AdminDesign.mutedText,
                background: const Color(0xFFF3F7FD),
                onPressed: deleting ? null : () => onView(question),
              ),
              _ActionButton(
                tooltip: 'Sửa',
                icon: Icons.edit_rounded,
                color: AdminDesign.primary,
                background: const Color(0xFFEAF1FF),
                onPressed: deleting ? null : () => onEdit(question),
              ),
              deleting
                  ? const SizedBox(
                      width: 34,
                      height: 34,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _ActionButton(
                      tooltip: 'Xóa',
                      icon: Icons.delete_outline_rounded,
                      color: AdminDesign.danger,
                      background: const Color(0xFFFFECEF),
                      onPressed: () => onDelete(question),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyQuestionsView extends StatelessWidget {
  const _EmptyQuestionsView({required this.message, this.onAction});

  final String message;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmptyView(message: message),
          if (onAction != null)
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Xóa bộ lọc'),
            ),
        ],
      ),
    );
  }
}

class _QuestionFormDialog extends StatefulWidget {
  const _QuestionFormDialog({
    this.question,
    required this.isUpdate,
    required this.saving,
    this.defaultChapterId,
    this.defaultLessonId,
  });

  final Question? question;
  final bool isUpdate;
  final bool saving;
  final String? defaultChapterId;
  final String? defaultLessonId;

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final TextEditingController _explanation;
  late final TextEditingController _order;
  late final List<TextEditingController> _options;
  late String? _chapterId;
  late String? _lessonId;
  late int _correctOption;
  late String _difficulty;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _question = TextEditingController(text: question?.question ?? '');
    _explanation = TextEditingController(text: question?.explanation ?? '');
    _order = TextEditingController(text: '${question?.orderIndex ?? 1}');
    _options = List.generate(
      4,
      (index) => TextEditingController(
        text: index < (question?.options.length ?? 0)
            ? question!.options[index]
            : '',
      ),
    );
    _chapterId = question?.chapterId ?? widget.defaultChapterId;
    _lessonId = question?.lessonId ?? widget.defaultLessonId;
    _correctOption = question?.correctOption ?? 0;
    _difficulty = question?.difficulty ?? 'MEDIUM';
  }

  @override
  void dispose() {
    _question.dispose();
    _explanation.dispose();
    _order.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final chapters = _uniqueById(state.chapters, (chapter) => chapter.id);
    final allLessons = _uniqueById(state.adminLessons, (lesson) => lesson.id);
    _chapterId = _validDropdownValue(
      _chapterId,
      chapters.map((chapter) => chapter.id),
    );
    final lessons = _chapterId == null
        ? allLessons
        : allLessons
              .where((lesson) => lesson.chapterId == _chapterId)
              .toList();
    _lessonId = _validDropdownValue(
      _lessonId,
      lessons.map((lesson) => lesson.id),
    );
    if (_lessonId == null && lessons.isNotEmpty) {
      _lessonId = lessons.first.id;
    }
    final chapterValue = _validDropdownValue(
      _chapterId,
      chapters.map((chapter) => chapter.id),
    );
    final lessonValue = _validDropdownValue(
      _lessonId,
      lessons.map((lesson) => lesson.id),
    );
    return AlertDialog(
      title: Text(widget.isUpdate ? 'Sửa câu hỏi' : 'Thêm câu hỏi'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.defaultLessonId == null) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _chapterId,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả chương'),
                      ),
                      for (final chapter in state.chapters)
                        DropdownMenuItem(
                          value: chapter.id,
                          child: Text(chapter.title),
                        ),
                    ],
                    onChanged: widget.defaultChapterId != null
                        ? null
                        : (value) => setState(() {
                              _chapterId = value;
                              final nextLessons = value == null
                                  ? state.adminLessons
                                  : state.adminLessons
                                      .where((lesson) => lesson.chapterId == value)
                                      .toList();
                              if (!nextLessons.any((lesson) => lesson.id == _lessonId)) {
                                _lessonId = nextLessons.isEmpty
                                    ? null
                                    : nextLessons.first.id;
                              }
                            }),
                    decoration: const InputDecoration(labelText: 'Chương học'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _lessonId,
                    isExpanded: true,
                    items: [
                      for (final lesson in lessons)
                        DropdownMenuItem(
                          value: lesson.id,
                          child: Text(lesson.title),
                        ),
                    ],
                    validator: (value) => value == null || value.isEmpty
                        ? 'Phải chọn bài học'
                        : null,
                    onChanged: widget.defaultLessonId != null
                        ? null
                        : (value) => setState(() => _lessonId = value),
                    decoration: const InputDecoration(labelText: 'Bài học'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _question,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Nội dung câu hỏi'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < 4; i++) ...[
                  TextFormField(
                    controller: _options[i],
                    decoration: InputDecoration(
                      labelText: 'Đáp án ${_letter(i)}',
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<int>(
                  initialValue: _correctOption,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('A')),
                    DropdownMenuItem(value: 1, child: Text('B')),
                    DropdownMenuItem(value: 2, child: Text('C')),
                    DropdownMenuItem(value: 3, child: Text('D')),
                  ],
                  onChanged: (value) =>
                      setState(() => _correctOption = value ?? 0),
                  decoration: const InputDecoration(
                    labelText: 'Đáp án đúng',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _explanation,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Lời giải chi tiết'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'EASY', child: Text('Dễ')),
                    DropdownMenuItem(
                      value: 'MEDIUM',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(value: 'HARD', child: Text('Khó')),
                  ],
                  onChanged: (value) =>
                      setState(() => _difficulty = value ?? 'MEDIUM'),
                  decoration: const InputDecoration(labelText: 'Độ khó'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _order,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thứ tự hiển thị'),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1) {
                      return 'Thứ tự hiển thị phải >= 1';
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
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: AdminDesign.primary),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Bắt buộc';
    return null;
  }

  void _submit() {
    if (_saving || _formKey.currentState?.validate() != true) return;
    final options = _options.map((item) => item.text.trim()).toList();
    final normalized = options.map((item) => item.toLowerCase()).toSet();
    if (normalized.length != options.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Các option không được trùng nhau.')),
      );
      return;
    }
    setState(() => _saving = true);
    Navigator.pop(
      context,
      Question(
        id: widget.question?.id ?? '',
        lessonId: _lessonId ?? '',
        question: _question.text.trim(),
        options: options,
        correctOption: _correctOption,
        explanation: _explanation.text.trim(),
        difficulty: _difficulty,
        chapterId: _chapterId ?? '',
        orderIndex: int.tryParse(_order.text) ?? 1,
      ),
    );
  }
}

class _QuestionDetailDialog extends StatelessWidget {
  const _QuestionDetailDialog({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chi tiết câu hỏi'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _MetaLine(label: 'Chapter', value: question.chapterTitleOrId),
              _MetaLine(label: 'Lesson', value: question.lessonTitleOrId),
              _MetaLine(
                label: 'Độ khó',
                child: _DifficultyChip(difficulty: question.difficulty),
              ),
              _MetaLine(label: 'Order index', value: '${question.orderIndex}'),
              const SizedBox(height: 12),
              Text(
                question.question,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < question.options.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: i == question.correctOption
                        ? const Color(0xFFEAFBF1)
                        : AdminDesign.tableHeader,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: i == question.correctOption
                          ? const Color(0xFFBCEBD0)
                          : AdminDesign.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${_letter(i)}. ',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Expanded(child: Text(question.options[i])),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const Text(
                'Explanation',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(question.explanation),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _QuestionReorderDialog extends StatefulWidget {
  const _QuestionReorderDialog({required this.questions});

  final List<Question> questions;

  @override
  State<_QuestionReorderDialog> createState() => _QuestionReorderDialogState();
}

class _QuestionReorderDialogState extends State<_QuestionReorderDialog> {
  late final List<Question> _items;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _items = [...widget.questions];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sắp xếp câu hỏi'),
      content: SizedBox(
        width: 620,
        height: 440,
        child: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: _items.length,
          onReorder: _saving
              ? (_, _) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _items.removeAt(oldIndex);
                    _items.insert(newIndex, item);
                  });
                },
          itemBuilder: (context, index) {
            final question = _items[index];
            return ListTile(
              key: ValueKey(question.id),
              leading: CircleAvatar(
                backgroundColor: AdminDesign.tableHeader,
                child: Text('${index + 1}'),
              ),
              title: Text(
                question.question,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(question.lessonTitleOrId),
              trailing: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving
              ? null
              : () {
                  setState(() => _saving = true);
                  Navigator.pop(
                    context,
                    _items.map((question) => question.id).toList(),
                  );
                },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

class _DeleteQuestionDialog extends StatelessWidget {
  const _DeleteQuestionDialog({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xóa câu hỏi?'),
      content: Text(
        'Bạn sắp xóa "${question.questionShort}". Thao tác này không thể hoàn tác.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AdminDesign.danger),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.width,
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final double width;
  final IconData icon;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        key: ValueKey('$hint-${value ?? 'all'}-${items.length}'),
        initialValue: value,
        isExpanded: true,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminDesign.pillRadius),
            borderSide: const BorderSide(color: AdminDesign.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminDesign.pillRadius),
            borderSide: const BorderSide(color: AdminDesign.border),
          ),
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AdminDesign.cardRadius),
        border: Border.all(color: AdminDesign.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CorrectAnswerText extends StatelessWidget {
  const _CorrectAnswerText({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final index = question.correctOption ?? 0;
    final text = index >= 0 && index < question.options.length
        ? question.options[index]
        : '';
    return SizedBox(
      width: 170,
      child: Text(
        '${_letter(index)}. $text',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AdminDesign.success,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final data = switch (difficulty) {
      'EASY' => ('Dễ', const Color(0xFFE9FBEF), const Color(0xFF169B49)),
      'HARD' => ('Khó', const Color(0xFFFFECEF), const Color(0xFFDC2626)),
      _ => ('Trung bình', const Color(0xFFFFF6DB), const Color(0xFFD97706)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.$2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: data.$3.withValues(alpha: .22)),
      ),
      child: Text(
        data.$1,
        style: TextStyle(
          color: data.$3,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: onPressed == null ? color.withValues(alpha: .35) : color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AdminDesign.mutedText),
            ),
          ),
          Expanded(child: child ?? Text(value ?? '-')),
        ],
      ),
    );
  }
}

String _letter(int index) {
  const letters = ['A', 'B', 'C', 'D'];
  return index >= 0 && index < letters.length ? letters[index] : '?';
}

List<T> _uniqueById<T>(Iterable<T> items, String Function(T item) idOf) {
  final seen = <String>{};
  final result = <T>[];
  for (final item in items) {
    final id = idOf(item);
    if (id.isNotEmpty && seen.add(id)) {
      result.add(item);
    }
  }
  return result;
}

String? _validDropdownValue(String? value, Iterable<String> itemValues) {
  final normalized = _blankToNull(value);
  if (normalized == null) return null;
  return itemValues.contains(normalized) ? normalized : null;
}

String? _blankToNull(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

String _friendlyError(String message) {
  if (message.contains('401')) return 'Phiên đăng nhập đã hết hạn.';
  if (message.contains('403')) {
    return 'Bạn không có quyền thực hiện thao tác này.';
  }
  if (message.toLowerCase().contains('network')) {
    return 'Không kết nối được backend.';
  }
  return message.replaceFirst('Exception: ', '');
}

extension on Question {
  String get lessonTitleOrId => lessonTitle.isNotEmpty ? lessonTitle : lessonId;
  String get chapterTitleOrId =>
      chapterTitle.isNotEmpty ? chapterTitle : chapterId;
  String get questionShort =>
      question.length <= 72 ? question : '${question.substring(0, 72)}...';
}
