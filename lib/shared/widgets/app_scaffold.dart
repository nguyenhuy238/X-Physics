import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Offline downloads',
            onPressed: () => context.go('/offline'),
            icon: const Icon(Icons.download_done_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_rounded),
          ),
          Switch(value: state.simulateOffline, onChanged: state.setOfflineMode),
          ...?actions,
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
