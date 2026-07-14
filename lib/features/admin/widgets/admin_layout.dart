import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/application/app_state.dart';

class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeRoute,
    required this.child,
    this.floatingActionButton,
    this.actions,
    this.onSearchChanged,
  });

  final String title;
  final String subtitle;
  final String activeRoute;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final ValueChanged<String>? onSearchChanged;

  Widget _buildSidebar(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    final menuItems = [
      _SidebarItem(
        label: 'Dashboard',
        icon: Icons.grid_view_rounded,
        route: '/admin',
        isActive: activeRoute == '/admin',
      ),
      _SidebarItem(
        label: 'Chương học',
        icon: Icons.auto_stories_rounded,
        route: '/admin/chapters',
        isActive: activeRoute == '/admin/chapters',
      ),
      _SidebarItem(
        label: 'Bài học',
        icon: Icons.menu_book_rounded,
        route: '/admin/lessons',
        isActive: activeRoute == '/admin/lessons',
      ),
      _SidebarItem(
        label: 'Câu hỏi',
        icon: Icons.help_outline_rounded,
        route: '/admin/questions',
        isActive: activeRoute == '/admin/questions',
      ),
      _SidebarItem(
        label: 'Học sinh',
        icon: Icons.people_alt_rounded,
        route: '/admin',
        isActive: activeRoute == '/admin/students',
      ),
      _SidebarItem(
        label: 'Thống kê',
        icon: Icons.bar_chart_rounded,
        route: '/admin',
        isActive: activeRoute == '/admin/statistics',
      ),
    ];

    return Container(
      width: 260,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: Color(0xFF3B82F6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'X-Physics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'QUẢN LÝ NỘI DUNG',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: menuItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final item = menuItems[index];
                return InkWell(
                  onTap: () {
                    try {
                      final scaffold = Scaffold.maybeOf(context);
                      if (scaffold != null && scaffold.isDrawerOpen) {
                        Navigator.pop(context);
                      }
                    } catch (_) {}
                    context.go(item.route);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: item.isActive
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color:
                              item.isActive ? Colors.white : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: item.isActive
                                  ? Colors.white
                                  : const Color(0xFFE2E8F0),
                              fontWeight: item.isActive
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (item.isActive)
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 32),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF59E0B),
                child: Text(
                  (user != null && user.name.isNotEmpty)
                      ? user.name[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
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
                      user?.name ?? 'Admin User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? 'admin@xphysics.edu.vn',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Provider.of<AppState>(context, listen: false).logout();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFF87171),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thoát Admin',
                    style: TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1000;

    return Scaffold(
      drawer: isDesktop
          ? null
          : Builder(
              builder: (drawerContext) => Drawer(
                child: _buildSidebar(drawerContext),
              ),
            ),
      floatingActionButton: floatingActionButton,
      body: Builder(
        builder: (bodyContext) => Row(
          children: [
            if (isDesktop) _buildSidebar(bodyContext),
            Expanded(
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: Column(
                  children: [
                    _buildTopbar(bodyContext, !isDesktop),
                    Expanded(
                      child: child,
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

  Widget _buildTopbar(BuildContext context, bool showMenu) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          if (showMenu) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600) ...[
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  fillColor: const Color(0xFFF1F5F9),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF64748B),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.route,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool isActive;
}
