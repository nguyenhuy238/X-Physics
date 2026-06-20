import '../../../shared/models/x_models.dart';

abstract class ChapterRepository {
  Future<List<Chapter>> getChapters();

  Future<Chapter> getChapter(String id);
}
