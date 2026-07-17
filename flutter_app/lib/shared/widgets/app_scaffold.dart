import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isAdmin = location.startsWith('/admin');

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Admin' : 'X-Physics'),
        actions: [
          IconButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await navigator.pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: child,
    );
  }
}
