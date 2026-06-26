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
    return XScaffold(
      title: 'Admin Dashboard',
      child: state.isBusy && stats == null
          ? const LoadingView(message: 'Đang tải thống kê...')
          : state.errorMessage != null && stats == null
          ? ErrorView(
              message: state.errorMessage!,
              onRetry: () => context.read<AppState>().loadAdminDashboard(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Người dùng',
                      value: '${stats?['totalUsers'] ?? 0}',
                    ),
                    _StatCard(
                      label: 'Lượt quiz',
                      value: '${stats?['totalAttempts'] ?? 0}',
                    ),
                    _StatCard(
                      label: 'Tỉ lệ hoàn thành',
                      value:
                          '${(((stats?['completionRate'] as num?) ?? 0) * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/chapters'),
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Chapters'),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/lessons'),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Lessons'),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/admin/questions'),
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text('Questions'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Users',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                for (final user in state.adminUsers)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.person_rounded),
                      title: Text(user.name),
                      subtitle: Text('${user.email} • ${user.role}'),
                      trailing: Text('${user.coins} xu'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
