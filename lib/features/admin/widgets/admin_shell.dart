import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../progress/application/app_state.dart';
import 'admin_design.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    super.key,
    required this.activeRoute,
    required this.title,
    required this.subtitle,
    required this.child,
    this.searchController,
    this.onSearchChanged,
  });

  final String activeRoute;
  final String title;
  final String subtitle;
  final Widget child;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useSidebar = width >= 760;
    final content = ColoredBox(
      color: AdminDesign.pageBackground,
      child: Row(
        children: [
          if (useSidebar) _AdminSidebar(activeRoute: activeRoute),
          Expanded(
            child: Column(
              children: [
                _AdminHeader(
                  title: title,
                  subtitle: subtitle,
                  searchController: searchController,
                  onSearchChanged: onSearchChanged,
                  showMenu: !useSidebar,
                  activeRoute: activeRoute,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AdminDesign.pageBackground,
      drawer: useSidebar
          ? null
          : Drawer(child: _AdminSidebar(activeRoute: activeRoute)),
      body: SafeArea(child: content),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.onSearchChanged,
    required this.showMenu,
    required this.activeRoute,
  });

  final String title;
  final String subtitle;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final bool showMenu;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AdminDesign.pagePadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AdminDesign.border)),
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
              ),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AdminDesign.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AdminDesign.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (MediaQuery.sizeOf(context).width >= 900)
            SizedBox(
              width: 260,
              height: 44,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: AdminDesign.pageBackground,
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
          const SizedBox(width: 12),
          _RoundHeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 20,
            backgroundColor: AdminDesign.primary,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.activeRoute});

  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      width: 230,
      color: AdminDesign.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AdminDesign.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'X-Physics',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: AdminDesign.navyMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 42),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 12),
                child: Text(
                  'QUẢN LÝ NỘI DUNG',
                  style: TextStyle(
                    color: AdminDesign.navyMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              _AdminNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                route: '/admin',
                activeRoute: activeRoute,
              ),
              _AdminNavItem(
                icon: Icons.menu_book_rounded,
                label: 'Quản lý nội dung',
                route: '/admin/chapters',
                activeRoute: activeRoute,
                isActive:
                    activeRoute.startsWith('/admin/chapters') ||
                    activeRoute.startsWith('/admin/lessons') ||
                    activeRoute.startsWith('/admin/questions'),
              ),
              _AdminNavItem(
                icon: Icons.group_outlined,
                label: 'Học sinh',
                route: '/admin/students',
                activeRoute: activeRoute,
              ),
              const Spacer(),
              const Divider(color: Color(0xFF1E2C43)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFC928),
                  child: Icon(
                    Icons.lock_rounded,
                    color: AdminDesign.navy,
                    size: 18,
                  ),
                ),
                title: Text(
                  state.user?.name ?? 'Admin User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  state.user?.email ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminDesign.navyMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => state.logout(),
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AdminDesign.navyMuted,
                ),
                label: const Text(
                  'Thoát Admin',
                  style: TextStyle(color: AdminDesign.navyMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  const _AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.activeRoute,
    this.isActive,
  });

  final IconData icon;
  final String label;
  final String route;
  final String activeRoute;
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    final active = isActive ?? (route == activeRoute);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: active ? AdminDesign.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.go(route),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: active ? Colors.white : AdminDesign.navyMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? Colors.white : AdminDesign.navyMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (active)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundHeaderIcon extends StatelessWidget {
  const _RoundHeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AdminDesign.pageBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AdminDesign.border),
        ),
        child: Icon(icon, size: 20, color: AdminDesign.text),
      ),
    );
  }
}
