import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/x_models.dart';

class AppState extends ChangeNotifier {
  AppState() : _tokenStorage = TokenStorage() {
    _apiClient = ApiClient(
      ApiEndpoints.baseUrl,
      tokenStorage: _tokenStorage,
      onUnauthorized: _handleUnauthorized,
    );
  }

  late final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  GoRouter? router;
  XUser? user;
  bool loading = true;
  bool isBusy = false;
  String? errorMessage;
  int coins = 0;
  bool simulateOffline = false;

  final chapters = <Chapter>[];
  final lessonsByChapter = <String, List<Lesson>>{};
  final lessonsById = <String, Lesson>{};
  final questionsByLesson = <String, List<Question>>{};
  final completedLessons = <String>{};
  final downloadedLessons = <String>{};
  final badges = <String>{};
  final adminUsers = <XUser>[];
  final adminLessons = <Lesson>[];
  final adminQuestions = <Question>[];
  Map<String, dynamic>? adminStatistics;
  QuizAttempt? lastAttempt;

  Future<void> bootstrap() async {
    router = buildRouter(this);
    downloadedLessons
      ..clear()
      ..addAll(Hive.box<Map>('offline_lessons').keys.cast<String>());

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      await refreshCurrentUser();
      await loadHomeData();
    } catch (error) {
      await _tokenStorage.clear();
      user = null;
      errorMessage = _readableError(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    return _authenticate(() async {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return response.data?['data'] as Map<String, dynamic>;
    });
  }

  Future<bool> register(String name, String email, String password) async {
    return _authenticate(() async {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );
      return response.data?['data'] as Map<String, dynamic>;
    });
  }

  Future<void> logout() async {
    try {
      await _apiClient.dio.post<Map<String, dynamic>>(ApiEndpoints.logout);
    } catch (_) {
      // Local logout must still clear credentials if the backend is unreachable.
    }
    await _tokenStorage.clear();
    _handleUnauthorized();
  }

  void setOfflineMode(bool value) {
    simulateOffline = value;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final data = await _getData<Map<String, dynamic>>(ApiEndpoints.me);
    user = XUser.fromJson(data);
    coins = user?.coins ?? 0;
    notifyListeners();
  }

  Future<void> loadHomeData() async {
    await Future.wait([
      loadChapters(),
      loadProgress(),
      loadBadges(),
    ]);
  }

  Future<void> loadChapters() async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await _getData<List<dynamic>>(ApiEndpoints.chapters);
      chapters
        ..clear()
        ..addAll(data.map((item) => Chapter.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadChapterDetail(String chapterId) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final chapterData = await _getData<Map<String, dynamic>>(
        ApiEndpoints.chapter(chapterId),
      );
      final lessonData = await _getData<List<dynamic>>(
        ApiEndpoints.chapterLessons(chapterId),
      );
      final chapter = Chapter.fromJson(chapterData);
      final index = chapters.indexWhere((item) => item.id == chapter.id);
      if (index == -1) {
        chapters.add(chapter);
      } else {
        chapters[index] = chapter;
      }
      final lessons = lessonData
          .map((item) => Lesson.fromJson(item as Map))
          .toList();
      lessonsByChapter[chapterId] = lessons;
      for (final lesson in lessons) {
        lessonsById[lesson.id] = lesson;
      }
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<Lesson?> loadLessonDetail(String lessonId) async {
    if (simulateOffline) {
      return loadOfflineLesson(lessonId);
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final lessonData = await _getData<Map<String, dynamic>>(
        ApiEndpoints.lesson(lessonId),
      );
      final simulationsData = await _getData<List<dynamic>>(
        ApiEndpoints.lessonSimulations(lessonId),
      );
      final questions = await loadQuestions(lessonId, notify: false);
      final simulation = simulationsData.isEmpty
          ? null
          : simulationsData.first as Map<dynamic, dynamic>;
      final lessonJson = Map<String, dynamic>.from(lessonData)
        ..['simulation'] = simulation
        ..['questions'] = questions.map((question) => question.toJson()).toList();
      final lesson = Lesson.fromJson(lessonJson);
      lessonsById[lessonId] = lesson;
      questionsByLesson[lessonId] = questions;
      return lesson;
    } catch (error) {
      errorMessage = _readableError(error);
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Lesson? loadOfflineLesson(String id) {
    final data = Hive.box<Map>('offline_lessons').get(id);
    return data == null ? null : Lesson.fromJson(data);
  }

  Future<void> downloadLesson(String lessonId) async {
    final lesson = lessonsById[lessonId] ?? await loadLessonDetail(lessonId);
    if (lesson == null) {
      throw StateError('Không thể tải bài học.');
    }
    await Hive.box<Map>('offline_lessons').put(lesson.id, lesson.toJson());
    downloadedLessons.add(lesson.id);
    notifyListeners();
  }

  Future<List<Question>> loadQuestions(
    String lessonId, {
    bool notify = true,
  }) async {
    if (simulateOffline) {
      final lesson = loadOfflineLesson(lessonId);
      final questions = lesson?.questions ?? const <Question>[];
      questionsByLesson[lessonId] = questions;
      return questions;
    }

    if (notify) {
      isBusy = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final data = await _getData<List<dynamic>>(
        ApiEndpoints.lessonQuestions(lessonId),
      );
      final questions = data.map((item) => Question.fromJson(item as Map)).toList();
      questionsByLesson[lessonId] = questions;
      return questions;
    } catch (error) {
      errorMessage = _readableError(error);
      return const [];
    } finally {
      if (notify) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  Future<QuizAttempt?> submitQuiz(
    String lessonId,
    Map<String, int> answers,
  ) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.quizSubmit,
        data: {
          'lessonId': lessonId,
          'answers': answers.entries
              .map(
                (entry) => {
                  'questionId': entry.key,
                  'selectedOption': entry.value,
                },
              )
              .toList(),
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>;
      final attempt = QuizAttempt.fromSubmitJson(data, answers);
      lastAttempt = attempt;
      completedLessons.add(lessonId);
      await refreshCurrentUser();
      await loadProgress();
      await loadBadges();
      return attempt;
    } catch (error) {
      errorMessage = _readableError(error);
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadProgress() async {
    try {
      final data = await _getData<List<dynamic>>(ApiEndpoints.progressMe);
      completedLessons
        ..clear()
        ..addAll(
          data
              .where((item) => (item as Map)['status'] == 'COMPLETED')
              .map((item) => (item as Map)['lessonId'] as String),
        );
    } catch (error) {
      errorMessage = _readableError(error);
    }
  }

  Future<void> loadBadges() async {
    try {
      final data = await _getData<List<dynamic>>(ApiEndpoints.badgesMe);
      badges
        ..clear()
        ..addAll(data.map((item) => (item as Map)['name'] as String));
    } catch (error) {
      errorMessage = _readableError(error);
    }
  }

  double chapterProgress(String chapterId) {
    final lessons = lessonsByChapter[chapterId] ?? const <Lesson>[];
    if (lessons.isEmpty) {
      return 0;
    }
    return lessons.where((lesson) => completedLessons.contains(lesson.id)).length /
        lessons.length;
  }

  Chapter? chapterById(String id) {
    return chapters.where((chapter) => chapter.id == id).firstOrNull;
  }

  bool get canAccessAdmin {
    final role = user?.role;
    return role == 'ADMIN' || role == 'TEACHER';
  }

  Future<void> loadAdminDashboard() async {
    if (!canAccessAdmin) {
      errorMessage = 'Bạn không có quyền truy cập Admin.';
      notifyListeners();
      return;
    }
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final stats = await _getData<Map<String, dynamic>>(
        ApiEndpoints.adminStatistics,
      );
      final users = await _getData<List<dynamic>>(ApiEndpoints.adminUsers);
      adminStatistics = stats;
      adminUsers
        ..clear()
        ..addAll(users.map((item) => XUser.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminChapters() async {
    if (!canAccessAdmin) {
      errorMessage = 'Bạn không có quyền truy cập Admin.';
      notifyListeners();
      return;
    }
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await _getData<List<dynamic>>(ApiEndpoints.adminChapters);
      chapters
        ..clear()
        ..addAll(data.map((item) => Chapter.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminLessons() async {
    if (!canAccessAdmin) {
      errorMessage = 'Bạn không có quyền truy cập Admin.';
      notifyListeners();
      return;
    }
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await loadAdminChapters();
      final data = await _getData<List<dynamic>>(ApiEndpoints.adminLessons);
      adminLessons
        ..clear()
        ..addAll(data.map((item) => Lesson.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> loadAdminQuestions() async {
    if (!canAccessAdmin) {
      errorMessage = 'Bạn không có quyền truy cập Admin.';
      notifyListeners();
      return;
    }
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await loadAdminLessons();
      final data = await _getData<List<dynamic>>(ApiEndpoints.adminQuestions);
      adminQuestions
        ..clear()
        ..addAll(data.map((item) => Question.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> saveAdminChapter(Chapter chapter) async {
    final payload = {
      'id': chapter.id,
      'title': chapter.title,
      'description': chapter.description,
      'orderIndex': chapter.orderIndex,
      'isPublished': chapter.isPublished,
    };
    return _adminWrite(
      () => _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.adminChapters,
        data: payload,
      ),
      refresh: loadAdminChapters,
    );
  }

  Future<bool> updateAdminChapter(Chapter chapter) async {
    final payload = {
      'id': chapter.id,
      'title': chapter.title,
      'description': chapter.description,
      'orderIndex': chapter.orderIndex,
      'isPublished': chapter.isPublished,
    };
    return _adminWrite(
      () => _apiClient.dio.put<Map<String, dynamic>>(
        ApiEndpoints.adminChapter(chapter.id),
        data: payload,
      ),
      refresh: loadAdminChapters,
    );
  }

  Future<bool> deleteAdminChapter(String id) {
    return _adminWrite(
      () => _apiClient.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.adminChapter(id),
      ),
      refresh: loadAdminChapters,
    );
  }

  Future<bool> saveAdminLesson(Lesson lesson, {required bool isUpdate}) {
    final payload = {
      'id': lesson.id,
      'chapterId': lesson.chapterId,
      'title': lesson.title,
      'contentMarkdown': lesson.content,
      'formulaLatex': lesson.formulaLatex,
      'estimatedMinutes': lesson.estimatedMinutes,
      'orderIndex': lesson.orderIndex,
      'isPublished': lesson.isPublished,
    };
    return _adminWrite(
      () => isUpdate
          ? _apiClient.dio.put<Map<String, dynamic>>(
              ApiEndpoints.adminLesson(lesson.id),
              data: payload,
            )
          : _apiClient.dio.post<Map<String, dynamic>>(
              ApiEndpoints.adminLessons,
              data: payload,
            ),
      refresh: loadAdminLessons,
    );
  }

  Future<bool> deleteAdminLesson(String id) {
    return _adminWrite(
      () => _apiClient.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.adminLesson(id),
      ),
      refresh: loadAdminLessons,
    );
  }

  Future<bool> saveAdminQuestion(Question question, {required bool isUpdate}) {
    final payload = {
      'id': question.id,
      'lessonId': question.lessonId,
      'questionText': question.question,
      'options': question.options,
      'correctOption': question.correctOption ?? 0,
      'explanation': question.explanation,
      'orderIndex': question.orderIndex,
    };
    return _adminWrite(
      () => isUpdate
          ? _apiClient.dio.put<Map<String, dynamic>>(
              ApiEndpoints.adminQuestion(question.id),
              data: payload,
            )
          : _apiClient.dio.post<Map<String, dynamic>>(
              ApiEndpoints.adminQuestions,
              data: payload,
            ),
      refresh: loadAdminQuestions,
    );
  }

  Future<bool> deleteAdminQuestion(String id) {
    return _adminWrite(
      () => _apiClient.dio.delete<Map<String, dynamic>>(
        ApiEndpoints.adminQuestion(id),
      ),
      refresh: loadAdminQuestions,
    );
  }

  Future<bool> _authenticate(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final data = await request();
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      await _tokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      user = XUser.fromJson(data['user'] as Map);
      coins = user?.coins ?? 0;
      await loadHomeData();
      return true;
    } catch (error) {
      errorMessage = _readableError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<T> _getData<T>(String path) async {
    final response = await _apiClient.dio.get<Map<String, dynamic>>(path);
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return body['data'] as T;
  }

  Future<bool> _adminWrite(
    Future<Response<Map<String, dynamic>>> Function() request, {
    required Future<void> Function() refresh,
  }) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final response = await request();
      if (response.data?['success'] != true) {
        throw StateError(response.data?['message'] as String? ?? 'API error');
      }
      await refresh();
      return true;
    } catch (error) {
      errorMessage = _readableError(error);
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _handleUnauthorized() {
    user = null;
    coins = 0;
    badges.clear();
    completedLessons.clear();
    lastAttempt = null;
    router?.go('/login');
    notifyListeners();
  }

  String _readableError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Không kết nối được backend. Hãy kiểm tra server API.';
      }
      return error.message ?? 'Lỗi kết nối API.';
    }
    return error.toString();
  }
}
