import '../../../shared/models/x_models.dart';
import '../../lessons/data/mock_repository.dart';
import 'chapter_repository.dart';

class MockChapterRepository implements ChapterRepository {
  MockChapterRepository({MockRepository? repository})
    : _repository = repository ?? MockRepository();

  final MockRepository _repository;

  @override
  Future<Chapter> getChapter(String id) async => _repository.chapterById(id);

  @override
  Future<List<Chapter>> getChapters() async => _repository.chapters;
}
