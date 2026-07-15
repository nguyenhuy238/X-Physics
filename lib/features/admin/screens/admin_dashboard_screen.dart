import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadAdminDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.canAccessAdmin) {
      return const XScaffold(
        title: 'Admin',
        child: ErrorView(message: 'Bạn không có quyền truy cập Admin.'),
      );
    }
    final stats = state.adminStatistics;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Hồ sơ',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await context.read<AppState>().logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: state.isBusy && stats == null
          ? const LoadingView(message: 'Đang tải thống kê...')
          : state.errorMessage != null && stats == null
              ? ErrorView(
                  message: state.errorMessage!,
                  onRetry: () => context.read<AppState>().loadAdminDashboard(),
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<AppState>().loadAdminDashboard(),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HỆ THỐNG QUẢN TRỊ X-PHYSICS',
                              style: TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Chào Admin! 👋',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Quản lý dữ liệu bài học, học sinh và theo dõi các chỉ số học tập.',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Core Stats Cards Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chỉ số tổng quan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                children: [
                                  _MetricCard(
                                    title: 'Học viên hoạt động',
                                    value: '${stats?['activeUsers7Days'] ?? 0}',
                                    icon: Icons.people_alt_rounded,
                                    color: const Color(0xFF3B82F6),
                                    growth: stats?['newUsersGrowth'] != null
                                        ? (stats?['newUsersGrowth'] as num).toDouble()
                                        : null,
                                    subtitle: '30 ngày qua: ${stats?['activeUsers30Days'] ?? 0} học viên',
                                  ),
                                  const SizedBox(width: 12),
                                  _MetricCard(
                                    title: 'Lượt làm quiz',
                                    value: '${stats?['totalAttempts'] ?? 0}',
                                    icon: Icons.quiz_rounded,
                                    color: const Color(0xFF8B5CF6),
                                    growth: stats?['attemptsGrowth'] != null
                                        ? (stats?['attemptsGrowth'] as num).toDouble()
                                        : null,
                                    subtitle: 'Tuần này: +${stats?['attemptsThisWeek'] ?? 0} lượt',
                                  ),
                                  const SizedBox(width: 12),
                                  _MetricCard(
                                    title: 'Tỉ lệ hoàn thành',
                                    value:
                                        '${(((stats?['completionRate'] as num?) ?? 0) * 100).toStringAsFixed(1)}%',
                                    icon: Icons.insights_rounded,
                                    color: const Color(0xFF10B981),
                                    growth: stats?['completionsGrowth'] != null
                                        ? (stats?['completionsGrowth'] as num).toDouble()
                                        : null,
                                    subtitle: 'Completions tuần này: +${stats?['completionsThisWeek'] ?? 0}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Tabbed navigation buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _TabButton(
                              label: 'Học viên',
                              icon: Icons.face_rounded,
                              isActive: _currentTab == 0,
                              onTap: () => setState(() => _currentTab = 0),
                            ),
                            const SizedBox(width: 8),
                            _TabButton(
                              label: 'Nội dung',
                              icon: Icons.import_contacts_rounded,
                              isActive: _currentTab == 1,
                              onTap: () => setState(() => _currentTab = 1),
                            ),
                            const SizedBox(width: 8),
                            _TabButton(
                              label: 'Đánh giá',
                              icon: Icons.assessment_rounded,
                              isActive: _currentTab == 2,
                              onTap: () => setState(() => _currentTab = 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab Content switcher
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildTabContent(state, stats),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTabContent(AppState state, Map<String, dynamic>? stats) {
    switch (_currentTab) {
      case 0:
        return _buildStudentsTab(state, stats);
      case 1:
        return _buildContentTab(state, stats);
      case 2:
        return _buildAssessmentTab(state, stats);
      default:
        return const SizedBox();
    }
  }

  // --- TAB 1: STUDENTS ---
  Widget _buildStudentsTab(AppState state, Map<String, dynamic>? stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.cached_rounded, color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tỉ lệ quay lại',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${((stats?['retentionRate'] as num?) ?? 0.0).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Học viên học >1 buổi/tuần',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.hourglass_empty_rounded, color: Color(0xFF3B82F6), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Thời gian học',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${((stats?['averageStudyTime'] as num?) ?? 0.0).toStringAsFixed(1)} phút',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lý thuyết hoàn thành/bài',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách người dùng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                '${state.adminUsers.length} thành viên',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final user in state.adminUsers)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: user.role == 'ADMIN'
                      ? const Color(0xFFFEE2E2)
                      : user.role == 'TEACHER'
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFD1FAE5),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: user.role == 'ADMIN'
                          ? const Color(0xFFEF4444)
                          : user.role == 'TEACHER'
                              ? const Color(0xFF0284C7)
                              : const Color(0xFF10B981),
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: user.role == 'ADMIN'
                            ? const Color(0xFFFEF2F2)
                            : user.role == 'TEACHER'
                                ? const Color(0xFFF0F9FF)
                                : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: user.role == 'ADMIN'
                              ? const Color(0xFFFEE2E2)
                              : user.role == 'TEACHER'
                                  ? const Color(0xFFE0F2FE)
                                  : const Color(0xFFD1FAE5),
                        ),
                      ),
                      child: Text(
                        user.role,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: user.role == 'ADMIN'
                              ? const Color(0xFFEF4444)
                              : user.role == 'TEACHER'
                                  ? const Color(0xFF0284C7)
                                  : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.circle_notifications_rounded,
                        color: Color(0xFFD97706),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${user.coins} xu',
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- TAB 2: CONTENT ---
  Widget _buildContentTab(AppState state, Map<String, dynamic>? stats) {
    final chaptersCompletions = stats?['completionByChapter'] as List<dynamic>? ?? [];
    final lessonsWithoutQuiz = stats?['lessonsWithoutQuiz'] as List<dynamic>? ?? [];
    final mostViewed = stats?['mostViewedLessons'] as List<dynamic>? ?? [];
    final leastViewed = stats?['leastViewedLessons'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CMS Shortcuts Panel
          const Text(
            'Quản lý nội dung (CMS)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _CMSCard(
                title: 'Chương học',
                subtitle: 'Quản lý các chương học chính',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF2563EB),
                onTap: () => context.go('/admin/chapters'),
              ),
              _CMSCard(
                title: 'Bài học',
                subtitle: 'Chỉnh sửa lý thuyết & mô phỏng',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF0EA5E9),
                onTap: () => context.go('/admin/lessons'),
              ),
              _CMSCard(
                title: 'Câu hỏi',
                subtitle: 'Ngân hàng câu hỏi trắc nghiệm',
                icon: Icons.quiz_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => context.go('/admin/questions'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content Warnings checklist
          _WarningCard(lessonsWithoutQuiz: lessonsWithoutQuiz),
          const SizedBox(height: 24),

          // Chapter completions
          const Text(
            'Tỷ lệ hoàn thành theo chương học',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (chaptersCompletions.isEmpty)
            const Text(
              'Chưa có dữ liệu chương học.',
              style: TextStyle(color: Color(0xFF64748B)),
            )
          else
            ...chaptersCompletions.map((chapter) {
              return _ChapterProgressCard(
                title: chapter['title'] as String? ?? 'Chương học',
                completedCount: (chapter['completedCount'] as num?)?.toInt() ?? 0,
                totalLessons: (chapter['totalLessons'] as num?)?.toInt() ?? 0,
                completionRate: (chapter['completionRate'] as num?)?.toDouble() ?? 0.0,
              );
            }).toList(),
          const SizedBox(height: 24),

          // Most/Least Viewed Lessons lists
          _LessonRankingList(
            title: '🔥 Bài học được học nhiều nhất',
            lessons: mostViewed,
            isMostViewed: true,
          ),
          const SizedBox(height: 16),
          _LessonRankingList(
            title: '💤 Bài học được học ít nhất',
            lessons: leastViewed,
            isMostViewed: false,
          ),
        ],
      ),
    );
  }

  // --- TAB 3: ASSESSMENT ---
  Widget _buildAssessmentTab(AppState state, Map<String, dynamic>? stats) {
    final averageScore = (stats?['averageScore'] as num?)?.toDouble() ?? 0.0;
    final trendData = stats?['quizAttemptsTrend'] as List<dynamic>? ?? [];
    final difficultQuestions = stats?['difficultQuestions'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // General Assess Metrics Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Điểm trung bình',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$averageScore / 10',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tính trên toàn bộ lượt nộp',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFF8B5CF6), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Danh hiệu đã cấp',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${stats?['totalBadgesAwarded'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Học sinh xuất sắc',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily quiz trend custom line chart
          _AttemptsTrendChart(trendData: trendData),
          const SizedBox(height: 24),

          // Difficult questions checklist
          _DifficultQuestionCard(questions: difficultQuestions),
        ],
      ),
    );
  }
}

// --- PRIVATE COMPONENT WIDGETS ---

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.growth,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? growth;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (growth != null) _GrowthBadge(value: growth!),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class _GrowthBadge extends StatelessWidget {
  final double value;
  const _GrowthBadge({required this.value});

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bgColor = isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final icon = isPositive ? '↑' : '↓';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        '$icon ${value.abs().toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData icon;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF64748B),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CMSCard extends StatelessWidget {
  const _CMSCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            width: width > 160 ? width : 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChapterProgressCard extends StatelessWidget {
  final String title;
  final int completedCount;
  final int totalLessons;
  final double completionRate;

  const _ChapterProgressCard({
    required this.title,
    required this.completedCount,
    required this.totalLessons,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(completionRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Đã hoàn thành: $completedCount / $totalLessons bài học',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonRankingList extends StatelessWidget {
  final String title;
  final List<dynamic> lessons;
  final bool isMostViewed;

  const _LessonRankingList({
    required this.title,
    required this.lessons,
    required this.isMostViewed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          if (lessons.isEmpty)
            const Text(
              'Chưa có dữ liệu bài học.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            )
          else
            ...lessons.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final lessonTitle = item['title'] as String? ?? 'Chưa rõ';
              final chapterTitle = item['chapterTitle'] as String? ?? '';
              final count = (item['viewCount'] as num?)?.toInt() ?? 0;
              
              final badgeColor = isMostViewed ? const Color(0xFFE0F2FE) : const Color(0xFFFEF2F2);
              final textColor = isMostViewed ? const Color(0xFF0369A1) : const Color(0xFFB91C1C);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: idx < lessons.length - 1
                      ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
                      : null,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: isMostViewed ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isMostViewed ? const Color(0xFF047857) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lessonTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (chapterTitle.isNotEmpty)
                            Text(
                              chapterTitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$count học viên',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final List<dynamic> lessonsWithoutQuiz;

  const _WarningCard({required this.lessonsWithoutQuiz});

  @override
  Widget build(BuildContext context) {
    if (lessonsWithoutQuiz.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1FAE5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tất cả bài học đều đã có câu hỏi trắc nghiệm! 🎉',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cảnh báo thiếu nội dung (${lessonsWithoutQuiz.length} bài học chưa có quiz)',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Các bài học sau đây chưa được thêm câu hỏi trắc nghiệm. Hãy bổ sung để học viên làm kiểm tra:',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 8),
          ...lessonsWithoutQuiz.take(5).map((lesson) {
            final lessonTitle = lesson['title'] as String? ?? 'Bài học không tên';
            final chapterTitle = lesson['chapterTitle'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.arrow_right_rounded, color: Color(0xFFB45309), size: 18),
                  Expanded(
                    child: Text(
                      '$lessonTitle ($chapterTitle)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          if (lessonsWithoutQuiz.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 16),
              child: Text(
                '... và ${lessonsWithoutQuiz.length - 5} bài học khác',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFB45309),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttemptsTrendChart extends StatelessWidget {
  final List<dynamic>? trendData;

  const _AttemptsTrendChart({this.trendData});

  @override
  Widget build(BuildContext context) {
    if (trendData == null || trendData!.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'Chưa có dữ liệu xu hướng.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final maxCount = trendData!
        .map((e) => (e['count'] as num?)?.toInt() ?? 0)
        .fold(0, (max, count) => count > max ? count : max);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số lượt làm quiz theo ngày',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trendData!.map<Widget>((e) {
                final dateStr = e['date'] as String? ?? '';
                final count = (e['count'] as num?)?.toInt() ?? 0;
                
                String label = dateStr;
                if (dateStr.length >= 10) {
                  final parts = dateStr.split('-');
                  if (parts.length == 3) {
                    label = '${parts[2]}/${parts[1]}';
                  }
                }

                final double ratio = maxCount == 0 ? 0 : count / maxCount;
                final double barHeight = ratio * 100;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? const Color(0xFF6366F1) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 24,
                      height: barHeight < 6 ? 6 : barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: count > 0
                              ? [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                              : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultQuestionCard extends StatelessWidget {
  final List<dynamic> questions;

  const _DifficultQuestionCard({required this.questions});

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'Chưa có dữ liệu câu hỏi khó.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Câu hỏi có tỷ lệ sai cao nhất',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          ...questions.map((question) {
            final questionText = question['question'] as String? ?? '';
            final lessonTitle = question['lesson_title'] as String? ?? '';
            final wrongCount = (question['wrong_count'] as num?)?.toInt() ?? 0;
            final totalAttempts = (question['total_attempts'] as num?)?.toInt() ?? 0;
            final errorRate = (question['error_rate'] as num?)?.toDouble() ?? 0.0;

            return InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Chi tiết câu hỏi khó'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Bài học: $lessonTitle',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Nội dung câu hỏi:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(questionText, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Tổng số lượt làm: $totalAttempts'),
                              Text(
                                'Số lượt làm sai: $wrongCount',
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tỷ lệ sai: ${errorRate.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${errorRate.toStringAsFixed(1)}% sai',
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            questionText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bài: $lessonTitle | Số lượt làm: $wrongCount/$totalAttempts',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
