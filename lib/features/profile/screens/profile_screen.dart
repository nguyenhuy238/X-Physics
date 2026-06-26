import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../progress/application/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return XScaffold(
      title: 'Hồ sơ',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(18),
              leading: const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person_rounded),
              ),
              title: Text(
                state.user?.name ?? 'Học sinh',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: Text('${state.user?.email ?? ''} • ${state.coins} xu'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Huy hiệu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          if (state.badges.isEmpty)
            const EmptyView(message: 'Chưa có huy hiệu nào.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final badge in state.badges)
                  Chip(
                    avatar: const Icon(Icons.workspace_premium_rounded),
                    label: Text(badge),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Bài offline: ${state.downloadedLessons.length}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.read<AppState>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
