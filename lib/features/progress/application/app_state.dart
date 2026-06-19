import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/models/x_models.dart';
import '../../lessons/data/mock_repository.dart';

class AppState extends ChangeNotifier {
  final MockRepository repository = MockRepository();
  GoRouter? router;
  XUser? user;
  bool loading = true;
  int coins = 0;
  bool simulateOffline = false;
  final completedLessons = <String>{};
  final downloadedLessons = <String>{};
  final badges = <String>{};
  QuizAttempt? lastAttempt;

  Future<void> bootstrap() async {
    router = buildRouter(this);
    downloadedLessons.addAll(
      Hive.box<Map>('offline_lessons').keys.cast<String>(),
    );
    loading = false;
    notifyListeners();
  }

  bool login(String email, String password) {
    final found = repository.users
        .where((u) => u.email == email)
        .cast<XUser?>()
        .firstOrNull;
    if (found == null || password != '123456') {
      return false;
    }
    user = found;
    notifyListeners();
    return true;
  }

  void register(String name, String email) {
    user = XUser(name: name, email: email, role: 'STUDENT');
    notifyListeners();
  }

  void logout() {
    user = null;
    notifyListeners();
  }

  void setOfflineMode(bool value) {
    simulateOffline = value;
    notifyListeners();
  }

  Lesson? loadLesson(String id) {
    if (!simulateOffline) {
      return repository.lessonById(id);
    }
    final data = Hive.box<Map>('offline_lessons').get(id);
    return data == null ? null : Lesson.fromJson(data);
  }

  Future<void> downloadLesson(Lesson lesson) async {
    await Hive.box<Map>('offline_lessons').put(lesson.id, lesson.toJson());
    downloadedLessons.add(lesson.id);
    notifyListeners();
  }

  Future<void> submitPendingIfOffline(QuizAttempt attempt) async {
    if (simulateOffline) {
      await Hive.box<Map>('pending_progress').put(attempt.lessonId, {
        'score': attempt.score,
        'coins': attempt.coins,
        'answers': attempt.answers,
      });
    }
  }

  QuizAttempt submitQuiz(String lessonId, Map<String, int> answers) {
    final lesson = repository.lessonById(lessonId);
    final correct = lesson.questions
        .where((q) => answers[q.id] == q.correctOption)
        .length;
    final score = correct / lesson.questions.length * 10;
    final earned = score == 10
        ? 30
        : score >= 8
        ? 20
        : score >= 6
        ? 15
        : 0;
    final newBadges = <String>[];
    completedLessons.add(lessonId);
    coins += earned + 10;
    if (completedLessons.length == 1 && badges.add('Khởi đầu Vật Lý')) {
      newBadges.add('Khởi đầu Vật Lý');
    }
    if (score == 10 && badges.add('Điểm tuyệt đối')) {
      newBadges.add('Điểm tuyệt đối');
    }
    _awardChapterBadges(newBadges);
    if (completedLessons.length == repository.lessons.length &&
        badges.add('Nhà bác học')) {
      newBadges.add('Nhà bác học');
    }
    lastAttempt = QuizAttempt(
      lessonId: lessonId,
      answers: answers,
      score: score,
      coins: earned + 10,
      newBadges: newBadges,
    );
    submitPendingIfOffline(lastAttempt!);
    notifyListeners();
    return lastAttempt!;
  }

  void _awardChapterBadges(List<String> newBadges) {
    for (final chapter in repository.chapters) {
      final lessons = repository.lessonsByChapter(chapter.id);
      if (lessons.every((lesson) => completedLessons.contains(lesson.id))) {
        final chapterCoinsKey = 'chapter-coins-${chapter.id}';
        if (badges.add(chapterCoinsKey)) {
          coins += 50;
        }
        final badge = switch (chapter.id) {
          'motion' => 'Bậc thầy chuyển động',
          'electric' => 'Điện thần',
          _ => null,
        };
        if (badge != null && badges.add(badge)) {
          newBadges.add(badge);
        }
      }
    }
  }

  double chapterProgress(String chapterId) {
    final lessons = repository.lessonsByChapter(chapterId);
    if (lessons.isEmpty) {
      return 0;
    }
    return lessons.where((l) => completedLessons.contains(l.id)).length /
        lessons.length;
  }
}
