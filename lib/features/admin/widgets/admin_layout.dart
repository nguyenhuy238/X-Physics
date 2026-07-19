import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/application/app_state.dart';
import '../../notifications/widgets/notification_icon.dart';


class AdminLayout extends StatelessWidget {
  const AdminLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.activeRoute,
    required this.child,
    this.floatingActionButton,
    this.actions,
    this.searchController,
    this.onSearchChanged,
    this.onBackRequested,
    this.backFallbackRoute = '/admin',
    this.breadcrumbs = const [],
  });

  final String title;
  final String subtitle;
  final String activeRoute;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final Future<bool> Function()? onBackRequested;
  final String backFallbackRoute;
  final List<AdminBreadcrumbItem> breadcrumbs;

  Widget _buildSidebar(BuildContext context) {
    final state = context.watch<AppState>();
    final user = state.user;

    final contentActive =
        activeRoute.startsWith('/admin/chapters') ||
        activeRoute.startsWith('/admin/lessons') ||
        activeRoute.startsWith('/admin/questions');

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
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
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
            child: ListView(
              children: [
                _SidebarLink(
                  label: 'Dashboard',
                  icon: Icons.grid_view_rounded,
                  route: '/admin',
                  isActive: activeRoute == '/admin',
                  onBackRequested: onBackRequested,
                ),
                const SizedBox(height: 8),
                _ContentNavGroup(
                  activeRoute: activeRoute,
                  contentActive: contentActive,
                  onBackRequested: onBackRequested,
                ),
                const SizedBox(height: 8),
                _SidebarLink(
                  label: 'Học sinh',
                  icon: Icons.people_alt_rounded,
                  route: '/admin/students',
                  isActive: activeRoute == '/admin/students',
                  onBackRequested: onBackRequested,
                ),
                const SizedBox(height: 8),
                _SidebarLink(
                  label: 'Thông báo',
                  icon: Icons.notifications_none_rounded,
                  route: '/notifications',
                  isActive: activeRoute == '/notifications',
                  onBackRequested: onBackRequested,
                ),
              ],
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
                  SizedBox(width: 8),
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
              builder: (drawerContext) =>
                  Drawer(child: _buildSidebar(drawerContext)),
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
                    Expanded(child: child),
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
              tooltip: 'Mở menu',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 12),
          ],
          if (activeRoute != '/admin') ...[
            IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () async {
                if (onBackRequested != null) {
                  final canLeave = await onBackRequested!();
                  if (!context.mounted || !canLeave) {
                    return;
                  }
                }
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(backFallbackRoute);
                }
              },
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (breadcrumbs.isNotEmpty) ...[
                  _AdminBreadcrumbs(items: breadcrumbs),
                  const SizedBox(height: 4),
                ],
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          if (MediaQuery.of(context).size.width > 600) ...[
            SizedBox(
              width: 240,
              height: 40,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
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
          const NotificationIcon(color: Color(0xFF64748B)),
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

class AdminBreadcrumbItem {
  const AdminBreadcrumbItem({required this.label, this.route});

  final String label;
  final String? route;
}

class _AdminBreadcrumbs extends StatelessWidget {
  const _AdminBreadcrumbs({required this.items});

  final List<AdminBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
              ),
            _BreadcrumbLink(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _BreadcrumbLink extends StatelessWidget {
  const _BreadcrumbLink({required this.item});

  final AdminBreadcrumbItem item;

  @override
  Widget build(BuildContext context) {
    final clickable = item.route != null;
    final text = Text(
      item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: clickable ? const Color(0xFF2563EB) : const Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
    if (!clickable) return text;
    return InkWell(
      onTap: () => context.go(item.route!),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: text,
      ),
    );
  }
}

class _ContentNavGroup extends StatelessWidget {
  const _ContentNavGroup({
    required this.activeRoute,
    required this.contentActive,
    required this.onBackRequested,
  });

  final String activeRoute;
  final bool contentActive;
  final Future<bool> Function()? onBackRequested;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey('content-$contentActive'),
        initiallyExpanded: contentActive,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 14, top: 4),
        collapsedIconColor: const Color(0xFF94A3B8),
        iconColor: Colors.white,
        leading: Icon(
          Icons.auto_stories_rounded,
          color: contentActive ? Colors.white : const Color(0xFF94A3B8),
          size: 20,
        ),
        title: Text(
          'Quản lý nội dung',
          style: TextStyle(
            color: contentActive ? Colors.white : const Color(0xFFE2E8F0),
            fontWeight: contentActive ? FontWeight.w700 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        collapsedBackgroundColor: Colors.transparent,
        backgroundColor: contentActive
            ? const Color(0xFF2563EB).withValues(alpha: .18)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        children: [
          _SidebarLink(
            label: 'Chương học',
            icon: Icons.bookmarks_rounded,
            route: '/admin/chapters',
            isActive: activeRoute.startsWith('/admin/chapters'),
            dense: true,
            onBackRequested: onBackRequested,
          ),
          const SizedBox(height: 6),
          _SidebarLink(
            label: 'Bài học',
            icon: Icons.menu_book_rounded,
            route: '/admin/lessons',
            isActive: activeRoute.startsWith('/admin/lessons'),
            dense: true,
            onBackRequested: onBackRequested,
          ),
          const SizedBox(height: 6),
          _SidebarLink(
            label: 'Câu hỏi Quiz',
            icon: Icons.quiz_rounded,
            route: '/admin/questions',
            isActive: activeRoute.startsWith('/admin/questions'),
            dense: true,
            onBackRequested: onBackRequested,
          ),
        ],
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  const _SidebarLink({
    required this.label,
    required this.icon,
    required this.route,
    required this.isActive,
    required this.onBackRequested,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final bool isActive;
  final Future<bool> Function()? onBackRequested;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (onBackRequested != null) {
          final canLeave = await onBackRequested!();
          if (!context.mounted || !canLeave) {
            return;
          }
        }
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.isDrawerOpen) {
          Navigator.pop(context);
        }
        context.go(route);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              size: dense ? 18 : 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFFE2E8F0),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  fontSize: dense ? 13 : 14,
                ),
              ),
            ),
            if (isActive)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
