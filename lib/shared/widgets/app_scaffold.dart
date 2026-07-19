import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../features/progress/application/app_state.dart';
import '../../features/notifications/widgets/notification_icon.dart';


class XScaffold extends StatelessWidget {
  const XScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBackButton,
    this.fallbackRoute,
    this.handleSystemBack = true,
    this.showThemeModeAction = true,
    this.showOfflineSimulationAction = true,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool? showBackButton;
  final String? fallbackRoute;
  final bool handleSystemBack;
  final bool showThemeModeAction;
  final bool showOfflineSimulationAction;

  static final Expando<PageStorageBucket> _pageStorageBuckets = Expando();
  static const double bottomNavigationHeight = 72;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final path = GoRouterState.of(context).uri.path;
    final bottomNavIndex = _bottomNavIndex(path);
    final shouldShowBack = showBackButton ?? _isDetailRoute(path);
    final scaffold = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: shouldShowBack
            ? IconButton(
                tooltip: 'Quay lại',
                onPressed: () => _goBack(context, path),
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(title),
        actions: [
          NotificationIcon(color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 8),
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
          if (kDebugMode && showOfflineSimulationAction)
            Semantics(
              label: state.effectiveOffline
                  ? 'Đang giả lập ngoại tuyến'
                  : 'Đang dùng kết nối mạng',
              button: true,
              child: Tooltip(
                message: state.simulateOffline
                    ? 'Tắt giả lập ngoại tuyến'
                    : 'Bật giả lập ngoại tuyến để kiểm tra và trình diễn',
                child: Switch(
                  value: state.simulateOffline,
                  onChanged: state.setOfflineMode,
                  thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Icon(Icons.cloud_off_rounded);
                    }
                    return const Icon(Icons.cloud_done_rounded);
                  }),
                ),
              ),
            ),
          if (showThemeModeAction)
            Semantics(
              label: 'Chế độ giao diện: ${_themeModeLabel(state.themeMode)}',
              button: true,
              child: IconButton(
                tooltip: 'Đổi giao diện: ${_themeModeLabel(state.themeMode)}',
                onPressed: () => state.cycleThemeMode(),
                icon: Icon(_themeModeIcon(state.themeMode)),
              ),
            ),
          ...?actions,
        ],
      ),
      body: SafeArea(
        child: PageStorage(
          bucket: _pageStorageBuckets[state] ??= PageStorageBucket(),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomNavIndex == null
          ? null
          : _XBottomNavigationBar(currentIndex: bottomNavIndex),
    );
    if (!handleSystemBack) {
      return scaffold;
    }
    return PopScope(
      canPop: _canPop(context, path, bottomNavIndex),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (bottomNavIndex != null && bottomNavIndex != 0) {
          context.go('/');
          return;
        }
        if (_isDetailRoute(path)) {
          context.go(fallbackRoute ?? _fallbackRoute(context, path));
        }
      },
      child: scaffold,
    );
  }

  int? _bottomNavIndex(String path) => switch (path) {
    '/' => 0,
    '/progress' => 1,
    '/offline' => 2,
    '/profile' => 3,
    _ => null,
  };

  bool _isDetailRoute(String path) {
    if (path == '/splash' ||
        path == '/login' ||
        path == '/register' ||
        path == '/' ||
        path == '/progress' ||
        path == '/offline' ||
        path == '/profile' ||
        path == '/admin') {
      return false;
    }
    return true;
  }

  bool _canPop(BuildContext context, String path, int? bottomNavIndex) {
    if (bottomNavIndex != null) {
      return bottomNavIndex == 0;
    }
    if (!_isDetailRoute(path)) {
      return true;
    }
    return context.canPop();
  }

  void _goBack(BuildContext context, String path) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute ?? _fallbackRoute(context, path));
  }

  String _fallbackRoute(BuildContext context, String path) {
    final state = context.read<AppState>();
    if (path.startsWith('/chapters/')) {
      return '/';
    }
    if (path.startsWith('/lessons/')) {
      final lessonId = path.split('/').last;
      final chapterId = state.lessonsById[lessonId]?.chapterId;
      return chapterId == null || chapterId.isEmpty
          ? '/'
          : '/chapters/$chapterId';
    }
    if (path.startsWith('/quiz/')) {
      final segments = path.split('/');
      return segments.length >= 3 ? '/lessons/${segments[2]}' : '/';
    }
    if (path.startsWith('/admin/')) {
      return '/admin';
    }
    return '/';
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Theo hệ thống',
    ThemeMode.light => 'Sáng',
    ThemeMode.dark => 'Tối',
  };

  IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => Icons.brightness_auto_rounded,
    ThemeMode.light => Icons.light_mode_rounded,
    ThemeMode.dark => Icons.dark_mode_rounded,
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
