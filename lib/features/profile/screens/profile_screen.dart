import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/empty_view.dart';
import '../../progress/application/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isAdmin = state.canAccessAdmin;

    final roleLabel = state.user?.role == 'TEACHER' ? 'Giáo viên' : 'Quản trị viên';
    final roleIcon = state.user?.role == 'TEACHER' ? Icons.school_rounded : Icons.shield_rounded;
    final roleColor = state.user?.role == 'TEACHER' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(isAdmin ? '/admin' : '/'),
        ),
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header blue gradient background
            Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Main profile container overlapping the header
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Profile Info Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isAdmin
                                      ? [const Color(0xFF1E293B), const Color(0xFF475569)]
                                      : [const Color(0xFF6366F1), const Color(0xFF3B82F6)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.user?.name ?? (isAdmin ? 'Quản trị viên' : 'Học sinh'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: roleColor.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    roleIcon,
                                    color: roleColor,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    roleLabel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: roleColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    color: Color(0xFFD97706),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${state.coins} xu',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB45309),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Badges section (Only for students)
                    if (!isAdmin) ...[
                      _buildSectionHeader('Huy hiệu đạt được', Icons.workspace_premium_rounded),
                      const SizedBox(height: 12),
                      if (state.badges.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFFBEB),
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa có huy hiệu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Hãy hoàn thành bài học và trả lời câu hỏi để nhận huy hiệu nhé!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final badge in state.badges)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE0E7FF),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Color(0xFF4F46E5),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      badge,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3730A3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Settings & Utilities section
                    _buildSectionHeader(
                      isAdmin ? 'Quản trị hệ thống' : 'Cài đặt & Tiện ích',
                      isAdmin ? Icons.admin_panel_settings_rounded : Icons.settings_rounded,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          if (isAdmin) ...[
                            // Admin Dashboard CMS shortcut
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEFF6FF),
                                ),
                                child: const Icon(
                                  Icons.dashboard_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Bảng điều khiển Admin',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: const Text(
                                'Tổng quan CMS & Quản lý danh sách',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => context.go('/admin'),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            // Admin Chapters link
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFDF2F8),
                                ),
                                child: const Icon(
                                  Icons.folder_special_rounded,
                                  color: Color(0xFFEC4899),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Quản lý Chương học',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: const Text(
                                'Thêm, sửa, xóa các chương học',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => context.go('/admin/chapters'),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            // Admin Lessons link
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFF0FDF4),
                                ),
                                child: const Icon(
                                  Icons.menu_book_rounded,
                                  color: Color(0xFF16A34A),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Quản lý Bài học',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: const Text(
                                'Quản lý bài lý thuyết & mô phỏng',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => context.go('/admin/lessons'),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            // Admin Questions link
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFFBEB),
                                ),
                                child: const Icon(
                                  Icons.quiz_rounded,
                                  color: Color(0xFFD97706),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Quản lý Câu hỏi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: const Text(
                                'Ngân hàng câu hỏi trắc nghiệm',
                                style: TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => context.go('/admin/questions'),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ] else ...[
                            // Simulate offline toggle
                            SwitchListTile(
                              secondary: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEFF6FF),
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Chế độ ngoại tuyến',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: const Text(
                                'Giả lập học tập không có mạng internet',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: state.simulateOffline,
                              onChanged: state.setOfflineMode,
                              activeColor: const Color(0xFF2563EB),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            // Offline downloads page link
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFECFDF5),
                                ),
                                child: const Icon(
                                  Icons.download_done_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Bài học tải xuống',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              subtitle: Text(
                                '${state.downloadedLessons.length} bài học sẵn sàng đọc offline',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                              onTap: () => context.go('/offline'),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ],
                          // Logout button
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFEF2F2),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            title: const Text(
                              'Đăng xuất tài khoản',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                            onTap: () => context.read<AppState>().logout(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF475569)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
