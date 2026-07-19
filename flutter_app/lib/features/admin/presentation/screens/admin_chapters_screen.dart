import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../../../shared/widgets/status_widgets.dart';
import '../../providers/admin_provider.dart';

class AdminChaptersScreen extends StatefulWidget {
  const AdminChaptersScreen({super.key});

  @override
  State<AdminChaptersScreen> createState() => _AdminChaptersScreenState();
}

class _AdminChaptersScreenState extends State<AdminChaptersScreen> {
  bool _published = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Chương - Bài học - Quiz')),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.lastChapters.isEmpty) {
            return const LoadingWidget();
          }
          if (provider.error != null && provider.lastChapters.isEmpty) {
            return ErrorView(
              message: provider.error!,
              onRetry: () => provider.fetchChapters(),
            );
          }

          final chapters = provider.lastChapters;

          if (chapters.isEmpty) {
            return EmptyView(
              message: 'Chưa có chương nào',
              action: ElevatedButton.icon(
                onPressed: () => _showChapterForm(context),
                icon: const Icon(Icons.add),
                label: const Text('Tạo chương mới'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index] as Map<String, dynamic>;
              return _ChapterCard(
                key: ValueKey(chapter['id']),
                chapter: chapter,
                onEdit: () => _showChapterForm(context, chapter),
                onDelete: () =>
                    _deleteChapter(context, chapter['id'] as String),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showChapterForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm chương'),
      ),
    );
  }

  Future<void> _deleteChapter(BuildContext context, String id) async {
    final provider = context.read<AdminProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa chương?'),
        content: const Text(
          'Hành động này sẽ ẩn chương cùng các bài học bên trong.',
        ),
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
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/chapters/$id');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa chương')));
      await provider.fetchChapters();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showChapterForm(
    BuildContext context, [
    Map<String, dynamic>? chapter,
  ]) async {
    final isEdit = chapter != null;
    final titleController = TextEditingController(
      text: chapter?['title'] ?? '',
    );
    final descriptionController = TextEditingController(
      text: chapter?['description'] ?? '',
    );
    final orderController = TextEditingController(
      text: chapter?['orderIndex']?.toString() ?? '',
    );
    bool published = chapter?['isPublished'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Sửa chương' : 'Tạo chương mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề chương',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thứ tự'),
                ),
                SwitchListTile(
                  title: const Text('Hiển thị'),
                  value: published,
                  onChanged: (value) => setState(() => published = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !context.mounted) return;

    final provider = context.read<AdminProvider>();
    final payload = <String, dynamic>{
      'id':
          chapter?['id'] ?? 'chapter_${DateTime.now().millisecondsSinceEpoch}',
      'title': titleController.text,
      'description': descriptionController.text,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
      'isPublished': published,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/chapters/${payload['id']}', payload);
      } else {
        await api.post('admin/chapters', payload);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Đã cập nhật' : 'Đã tạo chương')),
      );
      await provider.fetchChapters();
    } on Exception catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _ChapterCard extends StatefulWidget {
  final Map<String, dynamic> chapter;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChapterCard({
    super.key,
    required this.chapter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard> {
  bool _expanded = false;
  List<Map<String, dynamic>> _lessons = [];
  bool _loadingLessons = false;
  String? _error;

  Future<void> _loadLessons() async {
    if (_lessons.isNotEmpty) return;
    setState(() {
      _loadingLessons = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final data = await api.getList(
        'admin/lessons',
        queryParameters: {'chapterId': widget.chapter['id']},
      );
      if (mounted) {
        setState(() {
          _lessons = data.cast<Map<String, dynamic>>();
          _loadingLessons = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingLessons = false;
        });
      }
    }
  }

  void _toggleExpand() {
    if (!_expanded) {
      _loadLessons();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = widget.chapter['isPublished'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              _expanded ? Icons.folder_open : Icons.folder,
              color: isPublished ? theme.colorScheme.primary : Colors.grey,
            ),
            title: Text(
              widget.chapter['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPublished ? null : Colors.grey,
              ),
            ),
            subtitle: Text(
              'Thứ tự: ${widget.chapter['orderIndex'] ?? 0}',
              style: TextStyle(color: isPublished ? null : Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Thêm bài học',
                  onPressed: () => _showLessonForm(context),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: _toggleExpand,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            _buildActions(theme),
            if (_loadingLessons)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Lỗi: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Chưa có bài học nào'),
              )
            else
              ..._lessons.map(
                (lesson) => _LessonTile(
                  key: ValueKey(lesson['id']),
                  lesson: lesson,
                  onEdit: () => _showLessonForm(context, lesson),
                  onDelete: () => _deleteLesson(lesson['id'] as String),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Sửa'),
          ),
          TextButton.icon(
            onPressed: widget.onDelete,
            icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
            label: Text(
              'Xóa',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLesson(String id) async {
    final provider = context.read<AdminProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bài học?'),
        content: const Text(
          'Hành động này sẽ ẩn bài học cùng các câu hỏi quiz.',
        ),
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
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/lessons/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa bài học')));
      await _loadLessons();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showLessonForm(
    BuildContext context, [
    Map<String, dynamic>? lesson,
  ]) async {
    final isEdit = lesson != null;
    final titleController = TextEditingController(text: lesson?['title'] ?? '');
    final contentController = TextEditingController(
      text: lesson?['contentMarkdown'] ?? '',
    );
    final minutesController = TextEditingController(
      text: (lesson?['estimatedMinutes'] ?? 10).toString(),
    );
    final orderController = TextEditingController(
      text: (lesson?['orderIndex'] ?? 0).toString(),
    );
    final formulaController = TextEditingController(
      text: lesson?['formulaLatex'] ?? '',
    );
    bool published = lesson?['isPublished'] ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Sửa bài học' : 'Tạo bài học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề bài học',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung (Markdown)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: formulaController,
                  decoration: const InputDecoration(
                    labelText: 'Công thức LaTeX',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian ước tính (phút)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thứ tự'),
                ),
                SwitchListTile(
                  title: const Text('Hiển thị'),
                  value: published,
                  onChanged: (value) => setState(() => published = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    final payload = <String, dynamic>{
      'id': lesson?['id'] ?? 'lesson_${DateTime.now().millisecondsSinceEpoch}',
      'chapterId': widget.chapter['id'],
      'title': titleController.text,
      'contentMarkdown': contentController.text,
      'estimatedMinutes': int.tryParse(minutesController.text) ?? 10,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
      'isPublished': published,
      'formulaLatex': formulaController.text,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/lessons/${payload['id']}', payload);
      } else {
        await api.post('admin/lessons', payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Đã cập nhật' : 'Đã tạo bài học')),
      );
      await _loadLessons();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _LessonTile extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LessonTile({
    super.key,
    required this.lesson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile> {
  bool _expanded = false;
  List<Map<String, dynamic>> _questions = [];
  bool _loadingQuestions = false;
  String? _error;

  Future<void> _loadQuestions() async {
    if (_questions.isNotEmpty) return;
    setState(() {
      _loadingQuestions = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final data = await api.getList(
        'admin/questions',
        queryParameters: {'lessonId': widget.lesson['id']},
      );
      if (mounted) {
        setState(() {
          _questions = data.cast<Map<String, dynamic>>();
          _loadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingQuestions = false;
        });
      }
    }
  }

  void _toggleExpand() {
    if (!_expanded) {
      _loadQuestions();
    }
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPublished = widget.lesson['isPublished'] ?? false;
    final minutes = widget.lesson['estimatedMinutes'] ?? 0;
    final questionCount = _questions.length;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(left: 32, right: 8),
          leading: Icon(
            _expanded ? Icons.article : Icons.article_outlined,
            color: isPublished ? theme.colorScheme.secondary : Colors.grey,
            size: 20,
          ),
          title: Text(
            widget.lesson['title'] ?? '',
            style: TextStyle(
              color: isPublished ? null : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 12,
                color: isPublished ? null : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '$minutes phút',
                style: TextStyle(
                  color: isPublished ? null : Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.quiz_outlined,
                size: 12,
                color: isPublished ? null : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '$questionCount câu hỏi',
                style: TextStyle(
                  color: isPublished ? theme.colorScheme.primary : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (questionCount > 0)
                FilledButton.tonalIcon(
                  onPressed: _toggleExpand,
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(_expanded ? 'Đóng' : 'Mở rộng'),
                )
              else
                TextButton.icon(
                  onPressed: () => _showQuestionForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm câu hỏi'),
                ),
            ],
          ),
        ),
        if (_expanded) ...[
          const Divider(height: 1, indent: 32),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Danh sách câu hỏi ($questionCount)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Sửa bài học'),
                    ),
                    TextButton.icon(
                      onPressed: widget.onDelete,
                      icon: Icon(
                        Icons.delete,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      label: Text(
                        'Xóa',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildContentPreview(),
              ],
            ),
          ),
          if (_loadingQuestions)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lỗi: $_error',
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadQuestions,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_questions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Chưa có câu hỏi quiz nào',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _showQuestionForm(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo câu hỏi đầu tiên'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return _QuestionCard(
                  question: q,
                  index: index + 1,
                  totalQuestions: _questions.length,
                  onEdit: () => _showQuestionForm(context, q),
                  onDelete: () => _deleteQuestion(q['id'] as String),
                );
              },
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildContentPreview() {
    final content = widget.lesson['contentMarkdown'] ?? '';
    final formula = widget.lesson['formulaLatex'] ?? '';

    if (content.isEmpty && formula.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
        child: Text(
          'Chưa có nội dung',
          style: TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.isNotEmpty)
            Text(
              content.length > 100
                  ? '${content.substring(0, 100)}...'
                  : content,
              style: const TextStyle(fontSize: 12),
            ),
          if (formula.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Formula: $formula',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    final provider = context.read<AdminProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: const Text('Hành động này sẽ xóa câu hỏi khỏi hệ thống.'),
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
    );

    if (confirm != true) return;

    try {
      final api = ApiClient();
      await api.delete('admin/questions/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa câu hỏi')));
      await _loadQuestions();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showQuestionForm(
    BuildContext context, [
    Map<String, dynamic>? question,
  ]) async {
    final isEdit = question != null;
    final questionTextController = TextEditingController(
      text: question?['question'] ?? '',
    );
    final explanationController = TextEditingController(
      text: question?['explanation'] ?? '',
    );
    final orderController = TextEditingController(
      text: (question?['orderIndex'] ?? 0).toString(),
    );
    List<String> options = List<String>.from(
      question?['options'] ?? List.filled(4, ''),
    );
    int selectedCorrect = question?['correctOption'] ?? 0;
    String selectedDifficulty = question?['difficulty'] ?? 'MEDIUM';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Sửa câu hỏi' : 'Tạo câu hỏi mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionTextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung câu hỏi',
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      controller: TextEditingController(text: options[i]),
                      decoration: InputDecoration(
                        labelText: 'Lựa chọn ${i + 1}',
                        suffixIcon: selectedCorrect == i
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                            : null,
                      ),
                      onChanged: (value) => options[i] = value,
                    ),
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: selectedCorrect,
                  decoration: const InputDecoration(labelText: 'Đáp án đúng'),
                  items: List.generate(
                    4,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Lựa chọn ${i + 1}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedCorrect = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDifficulty,
                  decoration: const InputDecoration(labelText: 'Do kho'),
                  items: const [
                    DropdownMenuItem(value: 'EASY', child: Text('Dễ')),
                    DropdownMenuItem(
                      value: 'MEDIUM',
                      child: Text('Trung bình'),
                    ),
                    DropdownMenuItem(value: 'HARD', child: Text('Khó')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedDifficulty = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: explanationController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Giải thích'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Thứ tự'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isEdit ? 'Lưu' : 'Tạo'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    final payload = <String, dynamic>{
      'id':
          question?['id'] ??
          'question_${DateTime.now().millisecondsSinceEpoch}',
      'lessonId': widget.lesson['id'],
      'question': questionTextController.text,
      'options': options,
      'correctOption': selectedCorrect,
      'difficulty': selectedDifficulty,
      'explanation': explanationController.text,
      'orderIndex': int.tryParse(orderController.text) ?? 0,
    };

    try {
      final api = ApiClient();
      if (isEdit) {
        await api.put('admin/questions/${payload['id']}', payload);
      } else {
        await api.post('admin/questions', payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Đã cập nhật' : 'Đã tạo câu hỏi')),
      );
      await _loadQuestions();
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _reorderQuestions(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final question = _questions.removeAt(oldIndex);
    _questions.insert(newIndex, question);
    setState(() {});

    try {
      final api = ApiClient();
      final updates = <Map<String, dynamic>>[];
      for (var i = 0; i < _questions.length; i++) {
        updates.add({'id': _questions[i]['id'], 'orderIndex': i});
      }
      await api.put('admin/questions/reorder', {'questions': updates});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã sắp xếp câu hỏi'),
          duration: Duration(seconds: 1),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi sắp xếp: $e')));
    }
  }
}

class _QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final int index;
  final int totalQuestions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.totalQuestions,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = question['difficulty'] ?? 'MEDIUM';
    final correctOption = question['correctOption'] ?? 0;
    final options = List<String>.from(question['options'] ?? []);
    final difficultyColor = switch (difficulty) {
      'EASY' => Colors.green,
      'HARD' => Colors.red,
      _ => Colors.orange,
    };
    final difficultyLabel = switch (difficulty) {
      'EASY' => 'Dễ',
      'HARD' => 'Khó',
      _ => 'Trung bình',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question['question'] ?? '',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              difficultyLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: difficultyColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đáp án: ${String.fromCharCode(65 + correctOption)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: List.generate(options.length, (i) {
                  final isCorrect = i == correctOption;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade50 : null,
                      border: Border(
                        bottom: i < options.length - 1
                            ? BorderSide(color: Colors.grey.shade200)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + i),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCorrect
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            options[i].isEmpty ? '(Trống)' : options[i],
                            style: TextStyle(
                              fontSize: 14,
                              color: options[i].isEmpty ? Colors.grey : null,
                              fontStyle: options[i].isEmpty
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Icon(
                            Icons.check,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            if ((question['explanation'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        question['explanation'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Sửa'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmation(context),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Xóa',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa câu hỏi?'),
        content: Text('Bạn có chắc chắn muốn xóa câu hỏi "$index"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm == true) onDelete();
  }
}
