import 'package:hive/hive.dart';

class LocalStorageService {
  const LocalStorageService();

  Box<Map> offlineLessonsBox() => Hive.box<Map>('offline_lessons');

  Box<Map> pendingProgressBox() => Hive.box<Map>('pending_progress');
}
