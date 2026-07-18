import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/progress/application/app_state.dart';

class XPhysicsApp extends StatelessWidget {
  const XPhysicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppState>().router;
    return MaterialApp.router(
      title: 'X-Physics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: context.watch<AppState>().themeMode,
      routerConfig: router ?? buildRouter(context.read<AppState>()),
    );
  }
}
