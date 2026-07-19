import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/unsaved_changes_dialog.dart';
import '../../formula_simulation/utils/formula_calculator.dart';
import '../../formula_simulation/widgets/formula_simulation_widget.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';
import '../widgets/simulation_templates.dart';

class AdminLessonEditorScreen extends StatefulWidget {
  const AdminLessonEditorScreen({super.key, this.lessonId, this.chapterId});

  final String? lessonId;
  final String? chapterId;

  bool get isEdit => lessonId != null && lessonId!.isNotEmpty;

  @override
  State<AdminLessonEditorScreen> createState() =>
      _AdminLessonEditorScreenState();
}

class _AdminLessonEditorScreenState extends State<AdminLessonEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _formulaCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController(text: '10');
  final _orderCtrl = TextEditingController(text: '0');
  final _simTitleCtrl = TextEditingController();
  final _simFormulaCtrl = TextEditingController();
  final _resultSymbolCtrl = TextEditingController();
  final _resultLabelCtrl = TextEditingController();
  final _resultUnitCtrl = TextEditingController();
  final _resultExpressionCtrl = TextEditingController();
  final _decimalPlacesCtrl = TextEditingController(text: '2');

  final _variables = <_SimulationVariableDraft>[];
  final _simulationErrors = <String, String>{};

  String _chapterId = '';
  String _selectedTemplateId = 'custom';
  bool _isPublished = true;
  bool _simulationEnabled = false;
  bool _initialized = false;
  bool _saving = false;
  bool _saveAttempted = false;
  String _initialFingerprint = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final state = context.read<AppState>();
    if (state.adminLessons.isEmpty || state.chapters.isEmpty) {
      await state.loadAdminLessons();
    }
    if (!mounted) return;
    _initializeFromState(state);
  }

  void _initializeFromState(AppState state) {
    if (_initialized) return;
    final lesson = _currentLesson(state);
    if (widget.isEdit && lesson == null) {
      return;
    }

    _chapterId =
        lesson?.chapterId ??
        widget.chapterId ??
        (state.chapters.isEmpty ? '' : state.chapters.first.id);
    _idCtrl.text = lesson?.id ?? '';
    _titleCtrl.text = lesson?.title ?? '';
    _contentCtrl.text = lesson?.content ?? '';
    _formulaCtrl.text = lesson?.formulaLatex ?? '';
    _minutesCtrl.text = '${lesson?.estimatedMinutes ?? 10}';
    _orderCtrl.text = '${lesson?.orderIndex ?? _nextOrderIndex(state)}';
    _isPublished = lesson?.isPublished ?? true;
    _applySimulationConfig(
      lesson?.simulation ?? FormulaSimulationConfig.empty(),
      notify: false,
    );
    _simulationEnabled = lesson?.simulation.title.isNotEmpty ?? false;
    _initialized = true;
    _initialFingerprint = _fingerprint();
    setState(() {});
  }

  Lesson? _currentLesson(AppState state) {
    final id = widget.lessonId;
    if (id == null || id.isEmpty) return null;
    return state.adminLessons.cast<Lesson?>().firstWhere(
      (lesson) => lesson?.id == id,
      orElse: () => null,
    );
  }

  int _nextOrderIndex(AppState state) {
    final chapterId = _chapterId.isNotEmpty ? _chapterId : widget.chapterId;
    final items = state.adminLessons
        .where((lesson) => lesson.chapterId == chapterId)
        .toList();
    if (items.isEmpty) return 1;
    return items
            .map((lesson) => lesson.orderIndex)
            .reduce((max, value) => value > max ? value : max) +
        1;
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _formulaCtrl.dispose();
    _minutesCtrl.dispose();
    _orderCtrl.dispose();
    _simTitleCtrl.dispose();
    _simFormulaCtrl.dispose();
    _resultSymbolCtrl.dispose();
    _resultLabelCtrl.dispose();
    _resultUnitCtrl.dispose();
    _resultExpressionCtrl.dispose();
    _decimalPlacesCtrl.dispose();
    for (final variable in _variables) {
      variable.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    _initializeFromState(state);
    final lesson = _currentLesson(state);

    if (!_initialized) {
      return AdminLayout(
        title: widget.isEdit ? 'Chỉnh sửa bài học' : 'Tạo bài học',
        subtitle: '',
        activeRoute: '/admin/lessons',
        backFallbackRoute: _backRoute(lesson),
        child: const LoadingView(message: 'Đang tải dữ liệu bài học...'),
      );
    }
    if (widget.isEdit && lesson == null) {
      return AdminLayout(
        title: 'Không tìm thấy bài học',
        subtitle: '',
        activeRoute: '/admin/lessons',
        backFallbackRoute: _backRoute(),
        child: ErrorView(
          message: 'Không tìm thấy bài học "${widget.lessonId}".',
          onRetry: () => context.read<AppState>().loadAdminLessons(),
        ),
      );
    }

    final content = AdminLayout(
      title: widget.isEdit ? 'Chỉnh sửa bài học' : 'Tạo bài học',
      subtitle: widget.isEdit
          ? 'Cập nhật nội dung và mô phỏng tương tác'
          : 'Soạn bài học mới với cấu hình mô phỏng tùy chọn',
      activeRoute: '/admin/lessons',
      backFallbackRoute: _backRoute(lesson),
      breadcrumbs: [
        const AdminBreadcrumbItem(label: 'Quản lý nội dung'),
        AdminBreadcrumbItem(
          label: 'Bài học',
          route: Uri(
            path: '/admin/lessons',
            queryParameters: {
              if (_chapterId.isNotEmpty) 'chapterId': _chapterId,
            },
          ).toString(),
        ),
        AdminBreadcrumbItem(label: widget.isEdit ? 'Chỉnh sửa' : 'Tạo mới'),
      ],
      onBackRequested: _requestLeaveIfNeeded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1080;
                  final horizontalPadding = constraints.maxWidth < 600
                      ? 16.0
                      : 24.0;
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      horizontalPadding,
                      horizontalPadding,
                      120,
                    ),
                    children: [
                      _buildBasicSection(state, lesson, isWide),
                      const SizedBox(height: 16),
                      _buildFormulaSection(),
                      const SizedBox(height: 16),
                      _buildContentSection(),
                      const SizedBox(height: 16),
                      _buildSimulationSection(isWide),
                    ],
                  );
                },
              ),
            ),
            _buildActionFooter(lesson),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: !_saving && !_hasChanges(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _requestLeaveIfNeeded() && context.mounted) {
          context.pop();
        }
      },
      child: content,
    );
  }

  Widget _buildBasicSection(AppState state, Lesson? lesson, bool isWide) {
    final chapterItems = state.chapters
        .map(
          (chapter) => DropdownMenuItem(
            value: chapter.id,
            child: Text(chapter.title, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();

    return _EditorSection(
      title: 'Thông tin cơ bản',
      icon: Icons.info_rounded,
      child: Column(
        children: [
          ..._responsiveRow(
            isWide: isWide,
            children: [
              TextFormField(
                controller: _idCtrl,
                enabled: !widget.isEdit,
                decoration: _inputDecoration(
                  'Mã bài học',
                  hint: 'vd: motion-1',
                  helper: 'Chỉ dùng chữ thường, số và dấu gạch ngang.',
                ),
                validator: _validateLessonId,
                onChanged: (_) => setState(() {}),
              ),
              DropdownButtonFormField<String>(
                initialValue: _chapterId.isEmpty ? null : _chapterId,
                decoration: _inputDecoration('Chương học'),
                items: chapterItems,
                onChanged: widget.chapterId != null && widget.isEdit
                    ? null
                    : (value) => setState(() {
                        _chapterId = value ?? _chapterId;
                        if (!widget.isEdit) {
                          _orderCtrl.text = '${_nextOrderIndex(state)}';
                        }
                      }),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Chọn chương học' : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _titleCtrl,
            decoration: _inputDecoration('Tên bài học'),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Tên bài học là bắt buộc';
              if (trimmed.length < 3 || trimmed.length > 100) {
                return 'Tên bài học phải từ 3 đến 100 ký tự';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ..._responsiveRow(
            isWide: isWide,
            children: [
              TextFormField(
                controller: _minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Thời lượng ước tính'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Nhập số phút';
                  if (parsed < 1 || parsed > 180) return 'Giá trị từ 1 đến 180';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: _orderCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Thứ tự'),
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null) return 'Nhập số thứ tự';
                  if (parsed < 0) return 'Thứ tự phải >= 0';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              _SwitchField(
                label: 'Trạng thái xuất bản',
                value: _isPublished,
                onChanged: (value) => setState(() => _isPublished = value),
                valueLabel: _isPublished ? 'Đã xuất bản' : 'Bản nháp',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaSection() {
    return _EditorSection(
      title: 'Công thức chính',
      icon: Icons.functions_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _formulaCtrl,
            decoration: _inputDecoration(
              'Công thức LaTeX',
              hint: r'vd: v = \frac{s}{t}',
              helper: 'Công thức này chỉ để hiển thị trong bài học.',
            ),
            validator: (value) {
              if ((value ?? '').trim().length > 500) {
                return 'Công thức tối đa 500 ký tự';
              }
              return null;
            },
            onChanged: (_) => setState(() {}),
          ),
          if (_formulaCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: _softBoxDecoration(),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    _formulaCtrl.text.trim(),
                    textStyle: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF2563EB),
                    ),
                    onErrorFallback: (_) => Text(_formulaCtrl.text.trim()),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return _EditorSection(
      title: 'Nội dung bài học',
      icon: Icons.article_rounded,
      child: TextFormField(
        controller: _contentCtrl,
        maxLines: 16,
        decoration: _inputDecoration(
          'Nội dung Markdown',
          helper:
              'Có thể nhập tiêu đề, đoạn văn, danh sách và công thức trong nội dung bài học.',
        ),
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return 'Nội dung là bắt buộc';
          if (trimmed.length < 10 || trimmed.length > 10000) {
            return 'Nội dung bài học phải từ 10 đến 10000 ký tự';
          }
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSimulationSection(bool isWide) {
    final preview = _buildPreviewData();
    final editor = _EditorSection(
      title: 'Mô phỏng tương tác',
      icon: Icons.science_rounded,
      trailing: Switch(
        value: _simulationEnabled,
        activeThumbColor: const Color(0xFF2563EB),
        onChanged: _setSimulationEnabled,
      ),
      child: !_simulationEnabled
          ? const Text(
              'Mô phỏng đang tắt. Khi lưu, frontend sẽ gửi simulation = null '
              'và học sinh sẽ không thấy mô phỏng.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedTemplateId,
                  decoration: _inputDecoration(
                    'Mẫu cấu hình',
                    helper:
                        'Chọn mẫu để tự điền nhanh công thức, kết quả và các '
                        'biến. Có thể chỉnh sửa sau khi áp dụng.',
                  ),
                  items: simulationTemplates
                      .map(
                        (template) => DropdownMenuItem(
                          value: template.id,
                          child: Text(template.name),
                        ),
                      )
                      .toList(),
                  onChanged: _selectTemplate,
                ),
                const SizedBox(height: 10),
                const _InlineHelp(
                  message:
                      'Cách cấu hình: chọn một mẫu có sẵn hoặc nhập thủ công; '
                      'điền kết quả cần tính; thêm các biến đầu vào; kiểm tra '
                      'khung preview trước khi lưu.',
                ),
                const SizedBox(height: 14),
                ..._responsiveRow(
                  isWide: isWide,
                  children: [
                    TextFormField(
                      controller: _simTitleCtrl,
                      decoration: _inputDecoration(
                        'Tiêu đề mô phỏng',
                        hint: 'vd: Công thức tính vận tốc',
                        helper:
                            'Tên này sẽ hiển thị ở khung mô phỏng cho học sinh.',
                      ),
                      validator: (_) => _simFieldError('title'),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextFormField(
                      controller: _simFormulaCtrl,
                      decoration: _inputDecoration(
                        'Công thức hiển thị',
                        hint: r'vd: v = \frac{s}{t}',
                        helper:
                            'Dùng LaTeX hoặc ký hiệu dễ đọc. Trường này chỉ '
                            'để hiển thị, không dùng để tính.',
                      ),
                      validator: (_) => _simFieldError('formula'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildResultEditor(isWide),
                const SizedBox(height: 16),
                _buildVariableEditor(isWide),
              ],
            ),
    );

    final previewWidget = _SimulationPreviewPanel(data: preview);
    if (!isWide || !_simulationEnabled) {
      return Column(
        children: [
          editor,
          if (_simulationEnabled) ...[
            const SizedBox(height: 16),
            previewWidget,
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: editor),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: previewWidget),
      ],
    );
  }

  Widget _buildResultEditor(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _softBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Subheading(label: 'Cấu hình kết quả'),
          const SizedBox(height: 4),
          const Text(
            'Khai báo đại lượng cần tính. Công thức hiển thị có thể là LaTeX, '
            'còn biểu thức tính phải dùng đúng ký hiệu biến đã khai báo.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 12),
          ..._responsiveRow(
            isWide: isWide,
            children: [
              TextFormField(
                controller: _resultSymbolCtrl,
                decoration: _inputDecoration(
                  'Ký hiệu kết quả',
                  hint: 'vd: v',
                  helper:
                      'Ký hiệu ngắn của kết quả. Không được trùng với ký hiệu biến đầu vào.',
                ),
                validator: (_) => _simFieldError('result.symbol'),
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: _resultLabelCtrl,
                decoration: _inputDecoration(
                  'Tên kết quả',
                  hint: 'vd: Vận tốc',
                  helper: 'Tên đầy đủ của kết quả hiển thị trong preview.',
                ),
                validator: (_) => _simFieldError('result.label'),
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: _resultUnitCtrl,
                decoration: _inputDecoration(
                  'Đơn vị kết quả',
                  hint: 'vd: m/s',
                  helper: 'Có thể để trống nếu kết quả không có đơn vị.',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._responsiveRow(
            isWide: isWide,
            flexes: const [3, 1],
            children: [
              TextFormField(
                controller: _resultExpressionCtrl,
                decoration: _inputDecoration(
                  'Biểu thức tính',
                  hint: 'vd: s / t',
                  helper:
                      'Dùng đúng ký hiệu biến đã khai báo, ví dụ s / t hoặc '
                      'U / R. ${FormulaCalculator.supportedSyntax}',
                ),
                validator: (_) => _simFieldError('result.expression'),
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: _decimalPlacesCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  'Số chữ số thập phân',
                  hint: 'vd: 2',
                  helper:
                      'Số chữ số sau dấu phẩy khi hiển thị kết quả, từ 0 đến 6.',
                ),
                validator: (_) => _simFieldError('result.decimalPlaces'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariableEditor(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _Subheading(label: 'Biến đầu vào')),
            TextButton.icon(
              onPressed: _addVariable,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm biến'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Mỗi biến là một giá trị học sinh có thể kéo bằng thanh trượt. '
          'Ký hiệu biến phải khớp với ký hiệu dùng trong biểu thức tính.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        if (_simulationErrors['variables'] != null)
          _FieldErrorText(_simulationErrors['variables']!),
        if (_variables.isEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: _softBoxDecoration(),
            child: const Text(
              'Chưa có biến đầu vào.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        for (var index = 0; index < _variables.length; index++) ...[
          const SizedBox(height: 10),
          _buildVariableCard(index, _variables[index], isWide),
        ],
      ],
    );
  }

  Widget _buildVariableCard(
    int index,
    _SimulationVariableDraft variable,
    bool isWide,
  ) {
    final label = variable.label.text.trim();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Biến ${index + 1}${label.isEmpty ? '' : ' - $label'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Tooltip(
                message: 'Xóa biến',
                child: IconButton(
                  onPressed: () => _removeVariable(index),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._responsiveRow(
            isWide: isWide,
            children: [
              TextFormField(
                controller: variable.symbol,
                focusNode: variable.symbolFocus,
                decoration: _inputDecoration(
                  'Ký hiệu biến',
                  hint: 'vd: s',
                  helper:
                      'Dùng trong biểu thức tính. Chỉ dùng chữ, số và gạch dưới.',
                ),
                validator: (_) => _simFieldError('variables.$index.symbol'),
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: variable.label,
                decoration: _inputDecoration(
                  'Tên biến',
                  hint: 'vd: Quãng đường',
                  helper: 'Tên đầy đủ hiển thị cạnh thanh trượt.',
                ),
                validator: (_) => _simFieldError('variables.$index.label'),
                onChanged: (_) => setState(() {}),
              ),
              TextFormField(
                controller: variable.unit,
                decoration: _inputDecoration(
                  'Đơn vị biến',
                  hint: 'vd: m',
                  helper: 'Đơn vị hiển thị cạnh giá trị của biến.',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._responsiveRow(
            isWide: isWide,
            children: [
              _numberField(
                variable.min,
                'Giá trị nhỏ nhất',
                'variables.$index.min',
                helper: 'Điểm bắt đầu của thanh trượt.',
              ),
              _numberField(
                variable.max,
                'Giá trị lớn nhất',
                'variables.$index.max',
                helper: 'Điểm kết thúc của thanh trượt.',
              ),
              _numberField(
                variable.step,
                'Bước nhảy',
                'variables.$index.step',
                helper:
                    'Mỗi lần kéo thanh trượt sẽ tăng/giảm theo giá trị này.',
              ),
              _numberField(
                variable.defaultValue,
                'Giá trị mặc định',
                'variables.$index.default',
                helper: 'Giá trị ban đầu khi mở preview.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String key, {
    String? helper,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label, helper: helper),
      validator: (_) => _simFieldError(key),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildActionFooter(Lesson? lesson) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width < 600 ? 16 : 24,
        12,
        MediaQuery.of(context).size.width < 600 ? 16 : 24,
        16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final statusText = Text(
              _saving
                  ? 'Đang lưu dữ liệu...'
                  : _hasChanges()
                  ? 'Có thay đổi chưa lưu'
                  : 'Không có thay đổi mới',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            );
            final cancelButton = OutlinedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!await _requestLeaveIfNeeded()) {
                        return;
                      }
                      if (context.mounted) {
                        context.go(_backRoute(lesson));
                      }
                    },
              child: const Text('Hủy'),
            );
            final saveButton = FilledButton.icon(
              onPressed: _saving ? null : () => _save(lesson),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Lưu bài học'),
            );

            if (constraints.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  statusText,
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: cancelButton),
                      const SizedBox(width: 10),
                      Expanded(child: saveButton),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: statusText),
                cancelButton,
                const SizedBox(width: 10),
                saveButton,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _setSimulationEnabled(bool value) async {
    if (!value && _simulationEnabled && _originalHadSimulation()) {
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Tắt mô phỏng?'),
              content: const Text(
                'Mô phỏng sẽ không còn hiển thị cho học sinh.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Giữ mô phỏng'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Tắt mô phỏng'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    if (!mounted) return;
    setState(() => _simulationEnabled = value);
  }

  bool _originalHadSimulation() {
    final state = context.read<AppState>();
    final lesson = _currentLesson(state);
    return lesson?.simulation.title.isNotEmpty ?? false;
  }

  Future<void> _selectTemplate(String? id) async {
    if (id == null || id == _selectedTemplateId) return;
    final template = simulationTemplates.firstWhere(
      (item) => item.id == id,
      orElse: () => simulationTemplates.first,
    );
    if (template.isCustom) {
      setState(() => _selectedTemplateId = template.id);
      return;
    }
    if (_hasSimulationDraft()) {
      final overwrite =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Áp dụng mẫu?'),
              content: const Text(
                'Dữ liệu mô phỏng hiện tại sẽ được ghi đè trong form.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
          ) ??
          false;
      if (!overwrite) return;
    }
    _applySimulationConfig(template.config!, templateId: template.id);
  }

  void _applySimulationConfig(
    FormulaSimulationConfig config, {
    String templateId = 'custom',
    bool notify = true,
  }) {
    _selectedTemplateId = templateId;
    _simTitleCtrl.text = config.title;
    _simFormulaCtrl.text = config.formula;
    _resultSymbolCtrl.text = config.result.symbol;
    _resultLabelCtrl.text = config.result.label;
    _resultUnitCtrl.text = config.result.unit;
    _resultExpressionCtrl.text = config.result.expression;
    _decimalPlacesCtrl.text = '${config.result.decimalPlaces}';
    for (final variable in _variables) {
      variable.dispose();
    }
    _variables
      ..clear()
      ..addAll(config.variables.map(_SimulationVariableDraft.fromVariable));
    if (notify) setState(() {});
  }

  void _addVariable() {
    final variable = _SimulationVariableDraft.empty();
    setState(() => _variables.add(variable));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) variable.symbolFocus.requestFocus();
    });
  }

  Future<void> _removeVariable(int index) async {
    final variable = _variables[index];
    final symbol = variable.symbol.text.trim();
    final used =
        symbol.isNotEmpty &&
        FormulaCalculator.referencedSymbols(
          _resultExpressionCtrl.text,
        ).contains(symbol);
    if (used) {
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Xóa biến đang dùng?'),
              content: Text(
                'Biểu thức đang dùng biến "$symbol". Xóa biến này có thể làm preview không hợp lệ.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Xóa biến'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }
    if (!mounted) return;
    setState(() {
      _variables.removeAt(index).dispose();
    });
  }

  String? _validateLessonId(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Mã bài học là bắt buộc';
    if (trimmed.length < 3 || trimmed.length > 50) {
      return 'Mã bài học phải từ 3 đến 50 ký tự';
    }
    if (!RegExp(r'^[a-z0-9\-]+$').hasMatch(trimmed)) {
      return 'Chỉ dùng chữ thường, số và dấu gạch ngang';
    }
    if (!widget.isEdit &&
        context.read<AppState>().adminLessons.any(
          (lesson) => lesson.id == trimmed,
        )) {
      return 'Mã bài học đã tồn tại';
    }
    return null;
  }

  bool _validateSimulationFields() {
    _simulationErrors.clear();
    if (!_simulationEnabled) return true;

    final title = _simTitleCtrl.text.trim();
    final formula = _simFormulaCtrl.text.trim();
    final resultSymbol = _resultSymbolCtrl.text.trim();
    final resultLabel = _resultLabelCtrl.text.trim();
    final expression = FormulaCalculator.normalizeExpression(
      _resultExpressionCtrl.text,
    );
    final decimalPlaces = int.tryParse(_decimalPlacesCtrl.text.trim());
    if (title.isEmpty) _simulationErrors['title'] = 'Tiêu đề là bắt buộc';
    if (formula.isEmpty) _simulationErrors['formula'] = 'Công thức là bắt buộc';
    if (resultSymbol.isEmpty) {
      _simulationErrors['result.symbol'] = 'Ký hiệu kết quả là bắt buộc';
    } else if (!_isValidSymbol(resultSymbol)) {
      _simulationErrors['result.symbol'] =
          'Ký hiệu chỉ được dùng chữ, số và gạch dưới, không bắt đầu bằng số';
    }
    if (resultLabel.isEmpty) {
      _simulationErrors['result.label'] = 'Tên kết quả là bắt buộc';
    }
    if (expression.isEmpty) {
      _simulationErrors['result.expression'] = 'Biểu thức tính là bắt buộc';
    } else if (!FormulaCalculator.isSupported(expression)) {
      _simulationErrors['result.expression'] =
          'Biểu thức tính không đúng cú pháp';
    }
    if (decimalPlaces == null) {
      _simulationErrors['result.decimalPlaces'] = 'Nhập số nguyên';
    } else if (decimalPlaces < 0 || decimalPlaces > 6) {
      _simulationErrors['result.decimalPlaces'] = 'Giá trị từ 0 đến 6';
    }
    if (_variables.isEmpty) {
      _simulationErrors['variables'] = 'Cần ít nhất một biến đầu vào';
    }

    final seen = <String, int>{};
    final values = <String, double>{};
    for (var index = 0; index < _variables.length; index++) {
      final variable = _variables[index];
      final symbol = variable.symbol.text.trim();
      final label = variable.label.text.trim();
      final min = double.tryParse(variable.min.text.trim());
      final max = double.tryParse(variable.max.text.trim());
      final step = double.tryParse(variable.step.text.trim());
      final defaultValue = double.tryParse(variable.defaultValue.text.trim());

      if (symbol.isEmpty) {
        _simulationErrors['variables.$index.symbol'] =
            'Ký hiệu biến là bắt buộc';
      } else if (!_isValidSymbol(symbol)) {
        _simulationErrors['variables.$index.symbol'] =
            'Ký hiệu chỉ được dùng chữ, số và gạch dưới, không bắt đầu bằng số';
      } else if (seen.containsKey(symbol)) {
        _simulationErrors['variables.$index.symbol'] = 'Ký hiệu bị trùng';
        _simulationErrors['variables.${seen[symbol]}.symbol'] =
            'Ký hiệu bị trùng';
      } else {
        seen[symbol] = index;
      }
      if (label.isEmpty) {
        _simulationErrors['variables.$index.label'] = 'Tên biến là bắt buộc';
      }
      if (min == null) _simulationErrors['variables.$index.min'] = 'Nhập số';
      if (max == null) _simulationErrors['variables.$index.max'] = 'Nhập số';
      if (step == null) _simulationErrors['variables.$index.step'] = 'Nhập số';
      if (defaultValue == null) {
        _simulationErrors['variables.$index.default'] = 'Nhập số';
      }
      if (min != null && max != null && min >= max) {
        _simulationErrors['variables.$index.max'] =
            'Giá trị lớn nhất phải lớn hơn giá trị nhỏ nhất';
      }
      if (step != null && step <= 0) {
        _simulationErrors['variables.$index.step'] = 'Bước nhảy phải lớn hơn 0';
      }
      if (min != null &&
          max != null &&
          defaultValue != null &&
          (defaultValue < min || defaultValue > max)) {
        _simulationErrors['variables.$index.default'] =
            'Giá trị mặc định phải nằm trong khoảng nhỏ nhất đến lớn nhất';
      }
      if (symbol.isNotEmpty && defaultValue != null) {
        values[symbol] = defaultValue;
      }
    }
    if (seen.containsKey(resultSymbol)) {
      _simulationErrors['result.symbol'] =
          'Ký hiệu kết quả không được trùng với ký hiệu biến đầu vào';
    }
    if (expression.isNotEmpty && FormulaCalculator.isSupported(expression)) {
      final refs = FormulaCalculator.referencedSymbols(expression);
      final unknown = refs
          .where((symbol) => !seen.containsKey(symbol))
          .toList();
      if (unknown.isNotEmpty) {
        _simulationErrors['result.expression'] =
            'Biểu thức đang dùng biến "${unknown.first}" nhưng biến này chưa được khai báo.';
      } else if (values.length == seen.length) {
        final result = FormulaCalculator.tryCalculate(expression, values);
        if (!result.isValid) {
          _simulationErrors['result.expression'] = _readableCalculationError(
            result.error,
          );
        }
      }
    }
    return _simulationErrors.isEmpty;
  }

  _SimulationPreviewData _buildPreviewData() {
    if (!_simulationEnabled) {
      return const _SimulationPreviewData.disabled();
    }
    final incomplete =
        _simTitleCtrl.text.trim().isEmpty ||
        _simFormulaCtrl.text.trim().isEmpty ||
        _resultExpressionCtrl.text.trim().isEmpty ||
        _variables.isEmpty ||
        _variables.any((variable) => variable.symbol.text.trim().isEmpty);
    final config = _buildSimulationConfigOrNull();
    final errorsBefore = Map<String, String>.from(_simulationErrors);
    final valid = _validateSimulationFields();
    final errors = Map<String, String>.from(_simulationErrors);
    _simulationErrors
      ..clear()
      ..addAll(errorsBefore);
    if (incomplete) {
      return const _SimulationPreviewData.incomplete(
        'Hãy nhập đủ biến và biểu thức để xem trước mô phỏng.',
      );
    }
    if (!valid || config == null) {
      return _SimulationPreviewData.invalid(errors.values.toList());
    }
    return _SimulationPreviewData.valid(config);
  }

  FormulaSimulationConfig? _buildSimulationConfigOrNull() {
    if (!_simulationEnabled) return FormulaSimulationConfig.empty();
    final variables = <FormulaVariable>[];
    for (final variable in _variables) {
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
      title: _simTitleCtrl.text.trim(),
      formula: _simFormulaCtrl.text.trim(),
      variables: variables,
      result: FormulaResult(
        symbol: _resultSymbolCtrl.text.trim(),
        label: _resultLabelCtrl.text.trim(),
        unit: _resultUnitCtrl.text.trim(),
        expression: FormulaCalculator.normalizeExpression(
          _resultExpressionCtrl.text,
        ),
        decimalPlaces: int.tryParse(_decimalPlacesCtrl.text.trim()) ?? 2,
      ),
    );
  }

  Future<void> _save(Lesson? original) async {
    setState(() {
      _saveAttempted = true;
      _validateSimulationFields();
    });
    if (_formKey.currentState?.validate() != true ||
        !_validateSimulationFields()) {
      setState(() {});
      return;
    }
    final simulationConfig = _simulationEnabled
        ? _buildSimulationConfigOrNull()
        : null;
    if (_simulationEnabled && simulationConfig == null) {
      return;
    }

    setState(() => _saving = true);
    final lesson = Lesson(
      id: _idCtrl.text.trim(),
      chapterId: _chapterId,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      formulaLatex: _formulaCtrl.text.trim(),
      estimatedMinutes: int.tryParse(_minutesCtrl.text.trim()) ?? 10,
      simulation: simulationConfig ?? FormulaSimulationConfig.empty(),
      questions: original?.questions ?? const [],
      orderIndex: int.tryParse(_orderCtrl.text.trim()) ?? 0,
      isPublished: _isPublished,
      createdAt: original?.createdAt,
      updatedAt: original?.updatedAt,
    );
    final ok = await context.read<AppState>().saveAdminLesson(
      lesson,
      isUpdate: widget.isEdit,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<AppState>().errorMessage ?? 'Không thể lưu bài học.',
          ),
        ),
      );
      return;
    }
    _initialFingerprint = _fingerprint();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu bài học thành công.')));
    context.go(_backRoute(lesson));
  }

  String? _simFieldError(String key) =>
      _saveAttempted ? _simulationErrors[key] : null;

  bool _isValidSymbol(String value) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(value);

  String _readableCalculationError(String? error) {
    if (error == null || error.isEmpty) {
      return 'Biểu thức tính không tính được';
    }
    if (error.contains('Division by zero')) {
      return 'Không được chia cho 0 tại giá trị mặc định của biến.';
    }
    if (error.contains('Missing closing parenthesis')) {
      return 'Biểu thức đang thiếu dấu ngoặc đóng.';
    }
    if (error.contains('Unexpected end')) {
      return 'Biểu thức chưa hoàn chỉnh.';
    }
    return 'Biểu thức tính không hợp lệ: $error';
  }

  bool _hasSimulationDraft() =>
      _simTitleCtrl.text.trim().isNotEmpty ||
      _simFormulaCtrl.text.trim().isNotEmpty ||
      _resultSymbolCtrl.text.trim().isNotEmpty ||
      _resultLabelCtrl.text.trim().isNotEmpty ||
      _resultExpressionCtrl.text.trim().isNotEmpty ||
      _variables.isNotEmpty;

  String _fingerprint() => [
    _idCtrl.text.trim(),
    _chapterId,
    _titleCtrl.text.trim(),
    _contentCtrl.text.trim(),
    _formulaCtrl.text.trim(),
    _minutesCtrl.text.trim(),
    _orderCtrl.text.trim(),
    '$_isPublished',
    '$_simulationEnabled',
    _simTitleCtrl.text.trim(),
    _simFormulaCtrl.text.trim(),
    _resultSymbolCtrl.text.trim(),
    _resultLabelCtrl.text.trim(),
    _resultUnitCtrl.text.trim(),
    _resultExpressionCtrl.text.trim(),
    _decimalPlacesCtrl.text.trim(),
    _variables
        .map(
          (variable) => [
            variable.symbol.text.trim(),
            variable.label.text.trim(),
            variable.unit.text.trim(),
            variable.min.text.trim(),
            variable.max.text.trim(),
            variable.step.text.trim(),
            variable.defaultValue.text.trim(),
          ].join('|'),
        )
        .join('||'),
  ].join('\n');

  bool _hasChanges() => _fingerprint() != _initialFingerprint;

  Future<bool> _requestLeaveIfNeeded() {
    if (_saving) return Future.value(false);
    return confirmDiscardChanges(
      context: context,
      hasChanges: _hasChanges(),
      title: widget.isEdit ? 'Hủy sửa bài học?' : 'Hủy tạo bài học?',
      message: 'Thông tin bài học đã nhập chưa được lưu.',
    );
  }

  String _backRoute([Lesson? lesson]) {
    final chapterId = widget.chapterId ?? lesson?.chapterId ?? _chapterId;
    if (widget.isEdit && lesson != null) {
      return Uri(
        path: '/admin/lessons/${lesson.id}',
        queryParameters: {if (chapterId.isNotEmpty) 'chapterId': chapterId},
      ).toString();
    }
    return Uri(
      path: '/admin/lessons',
      queryParameters: {if (chapterId.isNotEmpty) 'chapterId': chapterId},
    ).toString();
  }

  List<Widget> _responsiveRow({
    required bool isWide,
    required List<Widget> children,
    List<int>? flexes,
  }) {
    if (!isWide) {
      return [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const SizedBox(height: 12),
        ],
      ];
    }
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            Expanded(flex: flexes?[index] ?? 1, child: children[index]),
            if (index < children.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    ];
  }

  InputDecoration _inputDecoration(
    String label, {
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  BoxDecoration _softBoxDecoration() {
    return BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isNarrow ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow && trailing != null) ...[
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: trailing!),
          ] else
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SwitchField extends StatelessWidget {
  const _SwitchField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.valueLabel,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  valueLabel,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FieldErrorText extends StatelessWidget {
  const _FieldErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InlineHelp extends StatelessWidget {
  const _InlineHelp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimulationPreviewPanel extends StatelessWidget {
  const _SimulationPreviewPanel({required this.data});

  final _SimulationPreviewData data;

  @override
  Widget build(BuildContext context) {
    return _EditorSection(
      title: 'Preview tương tác',
      icon: Icons.visibility_rounded,
      child: switch (data.state) {
        _PreviewState.disabled => const Text(
          'Mô phỏng đang tắt.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        _PreviewState.incomplete => _PreviewMessage(
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF2563EB),
          message: data.message,
        ),
        _PreviewState.invalid => _PreviewMessage(
          icon: Icons.error_outline_rounded,
          color: const Color(0xFFEF4444),
          message: data.errors.isEmpty
              ? 'Cấu hình mô phỏng chưa hợp lệ.'
              : data.errors.first,
        ),
        _PreviewState.valid => FormulaSimulationWidget(config: data.config!),
      },
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}

enum _PreviewState { disabled, incomplete, invalid, valid }

class _SimulationPreviewData {
  const _SimulationPreviewData._({
    required this.state,
    this.message = '',
    this.errors = const [],
    this.config,
  });

  const _SimulationPreviewData.disabled()
    : this._(state: _PreviewState.disabled);

  const _SimulationPreviewData.incomplete(String message)
    : this._(state: _PreviewState.incomplete, message: message);

  const _SimulationPreviewData.invalid(List<String> errors)
    : this._(state: _PreviewState.invalid, errors: errors);

  const _SimulationPreviewData.valid(FormulaSimulationConfig config)
    : this._(state: _PreviewState.valid, config: config);

  final _PreviewState state;
  final String message;
  final List<String> errors;
  final FormulaSimulationConfig? config;
}

class _SimulationVariableDraft {
  _SimulationVariableDraft({
    required this.symbol,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.defaultValue,
    FocusNode? symbolFocus,
  }) : symbolFocus = symbolFocus ?? FocusNode();

  factory _SimulationVariableDraft.empty() => _SimulationVariableDraft(
    symbol: TextEditingController(),
    label: TextEditingController(),
    unit: TextEditingController(),
    min: TextEditingController(text: '0'),
    max: TextEditingController(text: '100'),
    step: TextEditingController(text: '1'),
    defaultValue: TextEditingController(text: '0'),
  );

  factory _SimulationVariableDraft.fromVariable(FormulaVariable variable) =>
      _SimulationVariableDraft(
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
  final FocusNode symbolFocus;

  void dispose() {
    symbol.dispose();
    label.dispose();
    unit.dispose();
    min.dispose();
    max.dispose();
    step.dispose();
    defaultValue.dispose();
    symbolFocus.dispose();
  }
}
