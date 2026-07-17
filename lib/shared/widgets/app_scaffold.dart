import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/progress/application/app_state.dart';

class XScaffold extends StatelessWidget {
  const XScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final path = GoRouterState.of(context).uri.path;
    final bottomNavIndex = _bottomNavIndex(path);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (bottomNavIndex == null) ...[
            IconButton(
              tooltip: 'Bài học offline',
              onPressed: () => context.go('/offline'),
              icon: const Icon(Icons.download_done_rounded),
            ),
            IconButton(
              tooltip: 'Hồ sơ',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person_rounded),
            ),
          ],
          Tooltip(
            message: state.effectiveOffline
                ? 'Đang ở chế độ offline'
                : 'Giả lập offline',
            child: Switch(
              value: state.simulateOffline,
              onChanged: state.setOfflineMode,
            ),
          ),
          ...?actions,
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: bottomNavIndex == null
          ? null
          : _XBottomNavigationBar(currentIndex: bottomNavIndex),
    );
  }

  int? _bottomNavIndex(String path) => switch (path) {
    '/' => 0,
    '/progress' => 1,
    '/offline' => 2,
    '/profile' => 3,
    _ => null,
  };
}

class _XBottomNavigationBar extends StatelessWidget {
  const _XBottomNavigationBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 72,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colorScheme.primary.withValues(alpha: .10),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final route = switch (index) {
          0 => '/',
          1 => '/progress',
          2 => '/offline',
          3 => '/profile',
          _ => '/',
        };
        if (GoRouterState.of(context).uri.path != route) {
          context.go(route);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up_rounded),
          label: 'Tiến độ',
        ),
        NavigationDestination(
          icon: Icon(Icons.download_outlined),
          selectedIcon: Icon(Icons.download_done_rounded),
          label: 'Offline',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Hồ sơ',
        ),
      ],
    );
  }
}
