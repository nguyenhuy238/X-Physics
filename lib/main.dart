import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/progress/application/app_state.dart';
import 'features/notifications/repositories/notification_repository.dart';
import 'features/notifications/providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    final appDir = await getApplicationSupportDirectory();
    Hive.init(appDir.path);
  }
  await Hive.openBox<Map>('offline_lessons');
  await Hive.openBox<Map>('pending_progress');
  await Hive.openBox<Map>('practice_questions');
  await Hive.openBox<Map>('pending_practice_sync');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState()..bootstrap(),
        ),
        ChangeNotifierProxyProvider<AppState, NotificationProvider>(
          create: (context) => NotificationProvider(
            repository: NotificationRepository(
              apiClient: context.read<AppState>().apiClient,
            ),
          ),
          update: (context, appState, previous) {
            final provider = previous ??
                NotificationProvider(
                  repository: NotificationRepository(
                    apiClient: appState.apiClient,
                  ),
                );
            if (appState.user != null) {
              provider.startPolling();
            } else {
              provider.stopPolling();
            }
            return provider;
          },
        ),
      ],
      child: const XPhysicsApp(),
    ),
  );
}
