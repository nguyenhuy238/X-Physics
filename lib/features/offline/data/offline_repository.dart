import '../../../shared/models/x_models.dart';

/// Local data source for the offline lesson cache. Reads are synchronous on
/// purpose: they are backed by a regular (non-lazy) Hive box, which is
/// itself synchronous — matching `LocalStorageService`'s existing sync
/// `Box<Map>` getters instead of wrapping a sync call in an unnecessary
/// `Future`. Only `saveLesson` is async, matching Hive's real `Box.put`
/// signature.
abstract class OfflineRepository {
  Future<void> saveLesson(Lesson lesson);

  Lesson? getLesson(String lessonId);

  List<String> getDownloadedLessonIds();
}
