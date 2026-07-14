import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/router/app_router.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../offline/data/offline_repository.dart';
import '../../offline/services/connectivity_service.dart';
import '../../offline/services/offline_service.dart';
import '../../offline/services/progress_sync_service.dart';
import '../../profile/data/profile_repository.dart';
import '../../../shared/models/x_models.dart';
import '../data/progress_repository.dart';

class AppState extends ChangeNotifier {
  AppState() : _tokenStorage = TokenStorage() {
    _apiClient = ApiClient(
      ApiEndpoints.baseUrl,
      tokenStorage: _tokenStorage,
      onUnauthorized: _handleUnauthorized,
    );
    _progressRepository = ProgressRepository(_apiClient);
    _profileRepository = ProfileRepository(_apiClient);
    _progressSyncService = ProgressSyncService(post: _syncPost);
    _listenConnectivity();
  }

  late final ApiClient _apiClient;
  late final ProgressRepository _progressRepository;
  late final ProfileRepository _profileRepository;
  late final ProgressSyncService _progressSyncService;
  final TokenStorage _tokenStorage;
  final ConnectivityService _connectivityService = ConnectivityService();
  final LocalStorageService _localStorage = const LocalStorageService();
  // `OfflineService()` is safe to construct eagerly: it resolves the Hive
  // box lazily (see offline_service.dart) instead of touching `Hive.box`
  // in its constructor, so it never throws in widget tests that construct
  // `AppState`/`FakeAppState` without opening any Hive box.
  final OfflineRepository _offlineRepository = OfflineService();
  StreamSubscription<bool>? _connectivitySub;
  bool _disposed = false;

  GoRouter? router;
  XUser? user;
  bool loading = true;
  bool isBusy = false;
  bool isProgressDashboardLoading = false;
  bool isProfileLoading = false;
  String? errorMessage;
  String? quizLoadError;
  String? quizSubmitError;
  String? progressDashboardError;
  String? profileError;
  int coins = 0;
  bool simulateOffline = false;

  /// Real network status detected via `connectivity_plus`. `simulateOffline`
  /// stays available for the demo "airplane mode" switch (see
  /// `shared/widgets/app_scaffold.dart`); both are OR-ed together in
  /// [effectiveOffline] so a real network drop is handled the same way as
  /// the manual demo toggle. See docs/OFFLINE_FLOW.md.
  bool isOffline = false;

  bool get effectiveOffline => simulateOffline || isOffline;

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
  ProgressDashboard? progressDashboard;
  ProfileSummary? profileSummary;
  final quizResultsByLesson = <String, QuizAttempt>{};

  Future<void> bootstrap() async {
    router = buildRouter(this);
    downloadedLessons
      ..clear()
      ..addAll(_offlineRepository.getDownloadedLessonIds());

    isOffline = !(await _connectivityService.isOnline());

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      loading = false;
      notifyListeners();
      return;
    }

    try {
      await refreshCurrentUser();
      await loadHomeData();
      if (!isOffline) {
        await _progressSyncService.syncPending();
      }
    } catch (error) {
      await _tokenStorage.clear();
      user = null;
      errorMessage = _readableError(error);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Starts listening for real connectivity transitions and flushes the
  /// pending-progress queue whenever the device comes back online. Wrapped
  /// defensively: `connectivity_plus` has no platform channel in
  /// `flutter_test`, and `AppState`'s constructor runs in dozens of
  /// existing widget tests via `FakeAppState`, so any failure here must
  /// never throw.
  void _listenConnectivity() {
    try {
      _connectivitySub = _connectivityService.onStatusChange.listen((online) {
        if (_disposed) {
          return;
        }
        final backOnline = isOffline && online;
        isOffline = !online;
        notifyListeners();
        if (backOnline) {
          unawaited(_progressSyncService.syncPending().then((_) {}));
        }
      }, onError: (Object error, StackTrace stackTrace) {});
    } catch (_) {
      // No connectivity platform channel available — keep isOffline at its
      // default value and skip live updates.
    }
  }

  /// Records how much of a lesson the student has read. When offline this
  /// is queued locally and flushed by [ProgressSyncService] the next time
  /// the app reconnects; when online it is sent immediately but still
  /// falls back to the local queue if the request fails (e.g. the
  /// connection drops mid-request). See docs/OFFLINE_FLOW.md.
  Future<void> updateReadingProgress(
    String lessonId,
    int progressPercent,
  ) async {
    if (lessonId.trim().isEmpty) {
      return;
    }
    final clamped = progressPercent < 0
        ? 0
        : (progressPercent > 100 ? 100 : progressPercent);
    final item = <String, dynamic>{
      'lessonId': lessonId,
      'progressPercent': clamped,
      'clientUpdatedAt': DateTime.now().toUtc().toIso8601String(),
    };

    if (effectiveOffline) {
      await _localStorage.queuePendingProgress(item);
      return;
    }

    try {
      await _syncPost(ApiEndpoints.syncProgress, {
        'items': [item],
      });
    } catch (_) {
      await _localStorage.queuePendingProgress(item);
    }
  }

  Future<Map<String, dynamic>> _syncPost(
    String path,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      path,
      data: data,
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'Sync API error');
    }
    return body;
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    super.dispose();
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
    } catch (error) {
      errorMessage = _readableError(error);
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
    await Future.wait([loadChapters(), loadProgress(), loadBadges()]);
  }

  Future<void> loadProgressDashboard() async {
    isProgressDashboardLoading = true;
    progressDashboardError = null;
    notifyListeners();
    try {
      progressDashboard = await _progressRepository.dashboard();
    } catch (error) {
      progressDashboardError = _readableError(error);
    } finally {
      isProgressDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProgressDashboard() => loadProgressDashboard();

  Future<void> loadProfile() async {
    isProfileLoading = true;
    profileError = null;
    notifyListeners();
    try {
      profileSummary = await _profileRepository.me();
      coins = profileSummary?.totalCoins ?? coins;
      final profileUser = profileSummary?.user;
      if (profileUser != null && profileUser.id.isNotEmpty) {
        user = XUser(
          id: profileUser.id,
          name: profileUser.name,
          email: profileUser.email,
          role: user?.role ?? 'STUDENT',
          coins: profileSummary?.totalCoins ?? coins,
        );
      }
    } catch (error) {
      profileError = _readableError(error);
    } finally {
      isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() => loadProfile();

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
    if (effectiveOffline) {
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
        ..['questions'] = questions
            .map((question) => question.toJson())
            .toList();
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

  Lesson? loadOfflineLesson(String id) => _offlineRepository.getLesson(id);

  Future<void> downloadLesson(String lessonId) async {
    final lesson = lessonsById[lessonId] ?? await loadLessonDetail(lessonId);
    if (lesson == null) {
      throw StateError('Không thể tải bài học.');
    }
    await _offlineRepository.saveLesson(lesson);
    downloadedLessons.add(lesson.id);
    notifyListeners();
    // Best-effort: record the download server-side for Admin statistics.
    // Never blocks or fails the (already-successful) local download.
    unawaited(_recordDownloadEvent(lesson.id));
  }

  Future<void> _recordDownloadEvent(String lessonId) async {
    try {
      await _syncPost(ApiEndpoints.syncDownloads, {'lessonId': lessonId});
    } catch (_) {
      // Ignored on purpose — see docs/OFFLINE_FLOW.md.
    }
  }

  /// Downloads every lesson in a chapter for offline reading, loading the
  /// chapter's lesson list first if it isn't already cached.
  Future<void> downloadChapter(String chapterId) async {
    if ((lessonsByChapter[chapterId] ?? const <Lesson>[]).isEmpty) {
      await loadChapterDetail(chapterId);
    }
    for (final lesson in lessonsByChapter[chapterId] ?? const <Lesson>[]) {
      await downloadLesson(lesson.id);
    }
  }

  /// Rough size (in bytes) of a downloaded lesson's cached JSON, for
  /// display in the Offline Downloads screen. Approximate on purpose — Hive
  /// does not expose per-entry disk size directly.
  int? estimatedOfflineSizeBytes(String lessonId) {
    final lesson = loadOfflineLesson(lessonId);
    if (lesson == null) {
      return null;
    }
    return utf8.encode(jsonEncode(lesson.toJson())).length;
  }

  /// Number of reading-progress updates queued locally, waiting to be sent
  /// to `POST /api/sync/progress`. Drives the sync-status banner in the
  /// Offline Downloads screen.
  int get pendingSyncCount => _localStorage.pendingProgressItems().length;

  /// Manually flushes the pending-progress queue (the "Đồng bộ ngay"
  /// button). No-ops while offline.
  Future<void> syncNow() async {
    if (effectiveOffline) {
      return;
    }
    final synced = await _progressSyncService.syncPending();
    if (synced > 0 && !_disposed) {
      notifyListeners();
    }
  }

  Future<List<Question>> loadQuestions(
    String lessonId, {
    bool notify = true,
  }) async {
    if (effectiveOffline) {
      final lesson = loadOfflineLesson(lessonId);
      final questions = lesson?.questions ?? const <Question>[];
      questionsByLesson[lessonId] = questions;
      quizLoadError = questions.isEmpty && lesson == null
          ? 'Khong tim thay bai hoc offline.'
          : null;
      return questions;
    }

    if (notify) {
      isBusy = true;
      quizLoadError = null;
      notifyListeners();
    }
    try {
      final data = await _getData<List<dynamic>>(
        ApiEndpoints.lessonQuestions(lessonId),
      );
      final questions = data
          .map((item) => Question.fromJson(item as Map))
          .toList();
      questionsByLesson[lessonId] = questions;
      quizLoadError = null;
      return questions;
    } catch (error) {
      quizLoadError = _readableError(error);
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
    Map<String, int> answers, {
    int durationSeconds = 0,
  }) async {
    isBusy = true;
    quizSubmitError = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiEndpoints.quizSubmit,
        data: {
          'lessonId': lessonId,
          'durationSeconds': durationSeconds,
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
      quizSubmitError = null;
      lastAttempt = attempt;
      quizResultsByLesson[lessonId] = attempt;
      completedLessons.add(lessonId);
      await refreshCurrentUser();
      await loadProgress();
      await loadBadges();
      await loadProgressDashboard();
      await loadProfile();
      return attempt;
    } catch (error) {
      quizSubmitError = _readableError(error);
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
    return lessons
            .where((lesson) => completedLessons.contains(lesson.id))
            .length /
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
      final data = await _getData<dynamic>(ApiEndpoints.adminQuestions);
      final items = data is Map
          ? List<dynamic>.from(data['items'] as List? ?? const [])
          : List<dynamic>.from(data as List);
      adminQuestions
        ..clear()
        ..addAll(items.map((item) => Question.fromJson(item as Map)));
    } catch (error) {
      errorMessage = _readableError(error);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<AdminQuestionPage> fetchAdminQuestions({
    String? lessonId,
    String? chapterId,
    String? search,
    String? difficulty,
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (lessonId != null && lessonId.isNotEmpty) 'lessonId': lessonId,
      if (chapterId != null && chapterId.isNotEmpty) 'chapterId': chapterId,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
    };
    final response = await _apiClient.dio.get<Map<String, dynamic>>(
      ApiEndpoints.adminQuestions,
      queryParameters: query,
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return AdminQuestionPage.fromJson(body['data'] as Map);
  }

  Future<Question> fetchAdminQuestionDetail(String id) async {
    final data = await _getData<Map<String, dynamic>>(
      ApiEndpoints.adminQuestion(id),
    );
    return Question.fromJson(data);
  }

  Future<Question> writeAdminQuestion(
    Question question, {
    required bool isUpdate,
  }) async {
    final payload = _adminQuestionPayload(question);
    final response = isUpdate
        ? await _apiClient.dio.put<Map<String, dynamic>>(
            ApiEndpoints.adminQuestion(question.id),
            data: payload,
          )
        : await _apiClient.dio.post<Map<String, dynamic>>(
            ApiEndpoints.adminQuestions,
            data: payload,
          );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    return Question.fromJson(body['data'] as Map);
  }

  Future<void> removeAdminQuestion(String id) async {
    final response = await _apiClient.dio.delete<Map<String, dynamic>>(
      ApiEndpoints.adminQuestion(id),
    );
    if (response.data?['success'] != true) {
      throw StateError(response.data?['message'] as String? ?? 'API error');
    }
  }

  Future<List<Map<String, dynamic>>> reorderAdminQuestions({
    required String lessonId,
    required List<String> questionIds,
  }) async {
    final response = await _apiClient.dio.put<Map<String, dynamic>>(
      ApiEndpoints.adminQuestionsReorder,
      data: {'lessonId': lessonId, 'questionIds': questionIds},
    );
    final body = response.data;
    if (body == null || body['success'] != true) {
      throw StateError(body?['message'] as String? ?? 'API error');
    }
    final data = body['data'] as Map;
    return List<Map<String, dynamic>>.from(data['items'] as List? ?? const []);
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
    return _adminWrite(
      () => isUpdate
          ? _apiClient.dio.put<Map<String, dynamic>>(
              ApiEndpoints.adminQuestion(question.id),
              data: _adminQuestionPayload(question),
            )
          : _apiClient.dio.post<Map<String, dynamic>>(
              ApiEndpoints.adminQuestions,
              data: _adminQuestionPayload(question),
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

  String readableError(Object error) => _readableError(error);

  Map<String, dynamic> _adminQuestionPayload(Question question) => {
    'lessonId': question.lessonId,
    'questionText': question.question,
    'options': question.options,
    'correctOption': question.correctOption ?? 0,
    'explanation': question.explanation,
    'difficulty': question.difficulty,
    'orderIndex': question.orderIndex,
  };

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
    quizLoadError = null;
    quizSubmitError = null;
    progressDashboard = null;
    progressDashboardError = null;
    profileSummary = null;
    profileError = null;
    quizResultsByLesson.clear();
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
