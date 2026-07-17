import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'features/progress/application/app_state.dart';

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
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: const XPhysicsApp(),
    ),
  );
}
