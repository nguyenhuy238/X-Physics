import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

// ─────────────────────────────────────────────────────────
//  AdminStudentsScreen
// ─────────────────────────────────────────────────────────
class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  String _searchQuery = '';
  Map<String, dynamic>? _selectedStudent; // non-null → đang xem chi tiết
  Map<String, dynamic>? _selectedChapter; // non-null → đang xem bài học chương

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdminDashboard();
    });
  }

  void _openStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedStudent = student;
      _selectedChapter = null;
    });
    context.read<AppState>().loadAdminUserProgress(student['id'] as String);
  }

  void _openChapter(Map<String, dynamic> chapter) {
    setState(() => _selectedChapter = chapter);
  }

  void _back() {
    if (_selectedChapter != null) {
      setState(() => _selectedChapter = null);
    } else if (_selectedStudent != null) {
      setState(() => _selectedStudent = null);
      context.read<AppState>().loadAdminDashboard();
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '–';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Dynamic title
    String title = 'Quản lý Học sinh';
    String subtitle = 'Danh sách và tiến độ học tập';

    if (_selectedChapter != null && _selectedStudent != null) {
      title = _selectedChapter!['title'] as String? ?? 'Chi tiết chương';
      subtitle = 'Học sinh: ${_selectedStudent!['name']}';
    } else if (_selectedStudent != null) {
      title = _selectedStudent!['name'] as String? ?? 'Tiến độ học tập';
      subtitle = _selectedStudent!['email'] as String? ?? '';
    }

    return AdminLayout(
      title: title,
      subtitle: subtitle,
      activeRoute: '/admin/students',
      onSearchChanged: _selectedStudent == null
          ? (q) => setState(() => _searchQuery = q)
          : null,
      child: _selectedChapter != null
          ? _LessonsView(
              chapter: _selectedChapter!,
              student: _selectedStudent!,
              onBack: _back,
              formatDate: _formatDate,
              onDeleteAttempt: (id) => _deleteAttempt(id, state),
            )
          : _selectedStudent != null
          ? _ProgressView(
              student: _selectedStudent!,
              state: state,
              onBack: _back,
              onChapterTap: _openChapter,
            )
          : _StudentsView(
              state: state,
              searchQuery: _searchQuery,
              onStudentTap: _openStudent,
            ),
    );
  }

  Future<void> _deleteAttempt(String attemptId, AppState state) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc muốn xóa lượt làm bài Quiz này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await state.deleteAdminQuizAttempt(attemptId);
    if (!mounted) return;
    if (ok) {
      await state.loadAdminUserProgress(_selectedStudent!['id'] as String);
      if (mounted) {
        setState(() {
          // refresh _selectedChapter reference
          final updated = state.adminUserProgressData;
          final found = updated.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id'] == _selectedChapter?['id'],
            orElse: () => null,
          );
          _selectedChapter = found;
        });
      }
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }
}

// ─────────────────────────────────────────────────────────
//  Students list view
// ─────────────────────────────────────────────────────────
class _StudentsView extends StatelessWidget {
  const _StudentsView({
    required this.state,
    required this.searchQuery,
    required this.onStudentTap,
  });

  final AppState state;
  final String searchQuery;
  final ValueChanged<Map<String, dynamic>> onStudentTap;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy && state.adminUsers.isEmpty) {
      return const LoadingView(message: 'Đang tải danh sách học sinh...');
    }

    final students = state.adminUsers.where((u) {
      if (u.role != 'STUDENT') return false;
      final q = searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    if (state.errorMessage != null && students.isEmpty) {
      return ErrorView(
        message: state.errorMessage!,
        onRetry: () => state.loadAdminDashboard(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 720;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Stats bar
            Row(
              children: [
                _StatChip(
                  icon: Icons.people_rounded,
                  label: '${students.length} học sinh',
                  color: const Color(0xFF2563EB),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (students.isEmpty)
              _emptyState('Không tìm thấy học sinh nào.')
            else if (isDesktop)
              _DesktopTable(students: students, onTap: onStudentTap)
            else
              _MobileCards(students: students, onTap: onStudentTap),
          ],
        );
      },
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.people_outline_rounded, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );
}

// Desktop table
class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.students, required this.onTap});
  final List<dynamic> students;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: const Color(0xFFF8FAFC),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: _Header('HỌC SINH')),
                  Expanded(flex: 3, child: _Header('EMAIL')),
                  Expanded(flex: 1, child: _Header('XU', center: true)),
                  SizedBox(
                    width: 120,
                    child: _Header('THAO TÁC', center: true),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            // Rows
            ...students.map((s) => _DesktopRow(student: s, onTap: onTap)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.center = false});
  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 1.1,
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({required this.student, required this.onTap});
  final dynamic student;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap({
        'id': student.id,
        'name': student.name,
        'email': student.email,
        'coins': student.coins,
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _Avatar(name: student.name, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                student.email,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${student.coins}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => onTap({
                    'id': student.id,
                    'name': student.name,
                    'email': student.email,
                    'coins': student.coins,
                  }),
                  icon: const Icon(Icons.trending_up_rounded, size: 14),
                  label: const Text('Tiến độ', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mobile cards
class _MobileCards extends StatelessWidget {
  const _MobileCards({required this.students, required this.onTap});
  final List<dynamic> students;
  final ValueChanged<Map<String, dynamic>> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = students[i];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap({
            'id': s.id,
            'name': s.name,
            'email': s.email,
            'coins': s.coins,
          }),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: .03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _Avatar(
                  name: s.name,
                  color: const Color(0xFF2563EB),
                  radius: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${s.coins}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Text(
                          'Tiến độ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF2563EB),
                          size: 16,
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
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Progress view (chapters list for a student)
// ─────────────────────────────────────────────────────────
class _ProgressView extends StatelessWidget {
  const _ProgressView({
    required this.student,
    required this.state,
    required this.onBack,
    required this.onChapterTap,
  });

  final Map<String, dynamic> student;
  final AppState state;
  final VoidCallback onBack;
  final ValueChanged<Map<String, dynamic>> onChapterTap;

  @override
  Widget build(BuildContext context) {
    if (state.isBusy && state.adminUserProgressData.isEmpty) {
      return const LoadingView(message: 'Đang tải tiến độ...');
    }

    final chapters = state.adminUserProgressData;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Back + student info banner
        _StudentBanner(student: student, onBack: onBack),
        const SizedBox(height: 20),

        if (state.errorMessage != null && chapters.isEmpty)
          ErrorView(
            message: state.errorMessage!,
            onRetry: () => state.loadAdminUserProgress(student['id'] as String),
          )
        else if (chapters.isEmpty)
          _emptyState('Học sinh chưa có tiến độ học tập nào.')
        else ...[
          Text(
            '${chapters.length} chương học',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          ...chapters.map(
            (chapter) => _ChapterCard(
              chapter: chapter,
              onTap: () => onChapterTap(chapter),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Icon(
            Icons.assignment_late_outlined,
            size: 52,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );
}

class _StudentBanner extends StatelessWidget {
  const _StudentBanner({required this.student, required this.onBack});
  final Map<String, dynamic> student;
  final VoidCallback onBack;

  void _showSendNotificationDialog(BuildContext context, String studentId, String studentName) {
    final titleController = TextEditingController(text: 'Thông báo từ Ban quản trị');
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Gửi thông báo tới $studentName',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung thông báo',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Vui lòng nhập nội dung thông báo' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  // Show loading
                  showDialog<void>(
                    context: dialogContext,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );

                  final success = await context.read<AppState>().sendAdminNotification(
                    userId: studentId,
                    title: titleController.text.trim(),
                    message: messageController.text.trim(),
                  );

                  // Pop loading
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext); // pop progress indicator
                    Navigator.pop(dialogContext); // pop dialog
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Đã gửi thông báo thành công!'
                              : 'Gửi thông báo thất bại: ${context.read<AppState>().errorMessage ?? 'Lỗi không xác định'}',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(6),
            ),
          ),
          const SizedBox(width: 12),
          _Avatar(
            name: student['name'] as String? ?? 'S',
            color: Colors.white,
            textColor: const Color(0xFF2563EB),
            radius: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  student['email'] as String? ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          if (student['coins'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${student['coins']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Gửi thông báo',
            icon: const Icon(Icons.campaign_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () => _showSendNotificationDialog(
              context,
              student['id'] as String,
              student['name'] as String? ?? 'học sinh',
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.onTap});
  final Map<String, dynamic> chapter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = chapter['completedLessons'] as num? ?? 0;
    final total = chapter['totalLessons'] as num? ?? 0;
    final rate = (chapter['completionRate'] as num? ?? 0.0).toDouble();
    final pct = (rate * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: .03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter['title'] as String? ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed/$total bài đã hoàn thành',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rate,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rate >= 1.0
                                    ? const Color(0xFF10B981)
                                    : rate > 0
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFFCBD5E1),
                              ),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: rate >= 1.0
                                ? const Color(0xFF10B981)
                                : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Lessons view (lessons inside a chapter for a student)
// ─────────────────────────────────────────────────────────
class _LessonsView extends StatelessWidget {
  const _LessonsView({
    required this.chapter,
    required this.student,
    required this.onBack,
    required this.formatDate,
    required this.onDeleteAttempt,
  });

  final Map<String, dynamic> chapter;
  final Map<String, dynamic> student;
  final VoidCallback onBack;
  final String Function(String?) formatDate;
  final Future<void> Function(String) onDeleteAttempt;

  @override
  Widget build(BuildContext context) {
    final lessons = chapter['lessons'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Back banner
        _ChapterBanner(chapter: chapter, student: student, onBack: onBack),
        const SizedBox(height: 20),

        if (lessons.isEmpty)
          _emptyState('Chương này không có bài học nào.')
        else
          ...lessons.map(
            (lesson) => _LessonCard(
              lesson: lesson,
              formatDate: formatDate,
              onDeleteAttempt: onDeleteAttempt,
            ),
          ),
      ],
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.library_books_outlined, size: 52, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );
}

class _ChapterBanner extends StatelessWidget {
  const _ChapterBanner({
    required this.chapter,
    required this.student,
    required this.onBack,
  });
  final Map<String, dynamic> chapter;
  final Map<String, dynamic> student;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              padding: const EdgeInsets.all(6),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter['title'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Học sinh: ${student['name']}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.formatDate,
    required this.onDeleteAttempt,
  });

  final dynamic lesson;
  final String Function(String?) formatDate;
  final Future<void> Function(String) onDeleteAttempt;

  @override
  Widget build(BuildContext context) {
    final status = lesson['status'] as String? ?? 'NOT_STARTED';
    final progress = lesson['progressPercent'] as int? ?? 0;
    final attempts = lesson['attempts'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: .03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFD97706),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson['title'] as String? ?? 'N/A',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  _StatusBadge(status: status),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.read_more_rounded,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Đọc bài: ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  Text(
                    '$progress%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quiz attempts
            if (attempts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.quiz_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Lịch sử làm Quiz',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: attempts
                      .map(
                        (a) => _AttemptTile(
                          attempt: a,
                          formatDate: formatDate,
                          onDelete: () => onDeleteAttempt(a['id'] as String),
                        ),
                      )
                      .toList(),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  'Chưa làm Quiz.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({
    required this.attempt,
    required this.formatDate,
    required this.onDelete,
  });

  final dynamic attempt;
  final String Function(String?) formatDate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final score = (attempt['score'] as num? ?? 0.0).toDouble();
    final correct = attempt['correctCount'] as int? ?? 0;
    final total = attempt['totalQuestions'] as int? ?? 0;
    final duration = attempt['durationSeconds'] as int? ?? 0;
    final date = attempt['createdAt'] as String?;

    final Color scoreColor = score >= 8
        ? const Color(0xFF10B981)
        : score >= 5
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);
    final Color scoreBg = score >= 8
        ? const Color(0xFFD1FAE5)
        : score >= 5
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEE2E2);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: scoreBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$correct/$total câu đúng',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  '${duration}s • ${formatDate(date)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            tooltip: 'Xóa lượt làm',
            onPressed: onDelete,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(4),
              minimumSize: const Size(28, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.color,
    this.textColor,
    this.radius = 18,
  });

  final String name;
  final Color color;
  final Color? textColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: textColor != null ? 1 : 0.12),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: textColor ?? color,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      'COMPLETED' => (
        const Color(0xFFD1FAE5),
        const Color(0xFF065F46),
        'Hoàn thành',
      ),
      'IN_PROGRESS' => (
        const Color(0xFFEFF6FF),
        const Color(0xFF1D4ED8),
        'Đang học',
      ),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B), 'Chưa học'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
