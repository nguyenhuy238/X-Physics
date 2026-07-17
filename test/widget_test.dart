import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:x_physics/core/network/api_client.dart';
import 'package:x_physics/core/router/app_router.dart';
import 'package:x_physics/core/storage/token_storage.dart';
import 'package:x_physics/features/admin/screens/admin_questions_screen.dart';
import 'package:x_physics/features/auth/screens/login_screen.dart';
import 'package:x_physics/features/progress/application/app_state.dart';
import 'package:x_physics/features/progress/screens/progress_screen.dart';
import 'package:x_physics/features/profile/screens/profile_screen.dart';
import 'package:x_physics/features/quiz/screens/quiz_result_screen.dart';
import 'package:x_physics/features/quiz/screens/quiz_screen.dart';
import 'package:x_physics/shared/models/x_models.dart';

const _questions = [
  Question(
    id: 'q1',
    lessonId: 'lesson-1',
    question: 'Question 1',
    options: ['A1', 'B1', 'C1', 'D1'],
    explanation: '',
  ),
  Question(
    id: 'q2',
    lessonId: 'lesson-1',
    question: 'Question 2',
    options: ['A2', 'B2', 'C2', 'D2'],
    explanation: '',
  ),
];

class FakeTokenStorage extends TokenStorage {
  String? accessToken = 'expired';
  String? refreshToken = 'refresh';
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }
}

class FailingRefreshAdapter implements HttpClientAdapter {
  int protectedCalls = 0;
  int refreshCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/api/auth/refresh' ||
        options.path == '/api/auth/refresh-token') {
      refreshCalls++;
    } else {
      protectedCalls++;
    }
    return ResponseBody.fromString(
      jsonEncode({'success': false, 'message': 'Unauthorized'}),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeAppState extends AppState {
  final loadQueue = <Future<List<Question>> Function()>[];
  final dashboardQueue = <Future<ProgressDashboard?> Function()>[];
  final profileQueue = <Future<ProfileSummary?> Function()>[];
  int loadCount = 0;
  int dashboardLoadCount = 0;
  int profileLoadCount = 0;
  int profileNameUpdateCount = 0;
  int passwordChangeCount = 0;
  int passwordChangeSignOutCount = 0;
  int loginCount = 0;
  String? updatedProfileName;
  int submitCount = 0;
  int? lastDurationSeconds;
  Map<String, int>? lastAnswers;
  Completer<QuizAttempt?>? submitCompleter;
  Completer<AdminQuestionPage>? adminQuestionCompleter;
  int adminQuestionFetchCount = 0;
  int adminWriteCount = 0;
  int adminDeleteCount = 0;
  int adminReorderCount = 0;
  List<String>? lastReorderQuestionIds;
  String? lastAdminSearch;
  String? lastAdminChapterId;
  String? lastAdminLessonId;
  String? lastAdminDifficulty;
  Question? lastWrittenQuestion;
  var adminQuestionPage = AdminQuestionPage(
    page: 1,
    limit: 20,
    total: 2,
    totalPages: 1,
    items: [
      Question(
        id: 'aq1',
        lessonId: 'lesson-1',
        lessonTitle: 'Chuyển động đều',
        chapterId: 'chapter-1',
        chapterTitle: 'Chuyển động cơ học',
        question: 'Một vật chuyển động đều với v = 5 m/s trong 10s đi bao xa?',
        options: ['10 m', '50 m', '5 m', '2 m'],
        correctOption: 1,
        explanation: 's = v * t = 50 m',
        difficulty: 'EASY',
        orderIndex: 1,
      ),
      Question(
        id: 'aq2',
        lessonId: 'lesson-1',
        lessonTitle: 'Chuyển động đều',
        chapterId: 'chapter-1',
        chapterTitle: 'Chuyển động cơ học',
        question:
            'Vật đi 100 m trong 20 giây, vận tốc trung bình là bao nhiêu?',
        options: ['3 m/s', '4 m/s', '5 m/s', '6 m/s'],
        correctOption: 2,
        explanation: 'v = s / t = 5 m/s',
        difficulty: 'MEDIUM',
        orderIndex: 2,
      ),
    ],
  );
  bool failSubmit = false;
  bool staleSubmit = false;

  @override
  Future<List<Question>> loadQuestions(String lessonId, {bool notify = true}) {
    loadCount++;
    if (loadQueue.isNotEmpty) {
      return loadQueue.removeAt(0)().then((questions) {
        if (questions.isEmpty && errorMessage != null) {
          quizLoadError = errorMessage;
        }
        return questions;
      });
    }
    questionsByLesson[lessonId] = _questions;
    errorMessage = null;
    return Future.value(_questions);
  }

  @override
  Future<void> loadProgressDashboard() async {
    dashboardLoadCount++;
    isProgressDashboardLoading = true;
    progressDashboardError = null;
    notifyListeners();
    try {
      if (dashboardQueue.isNotEmpty) {
        progressDashboard = await dashboardQueue.removeAt(0)();
      }
    } catch (error) {
      progressDashboardError = error.toString();
    } finally {
      isProgressDashboardLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refreshProgressDashboard() => loadProgressDashboard();

  @override
  Future<void> loadProfile() async {
    profileLoadCount++;
    isProfileLoading = true;
    profileError = null;
    notifyListeners();
    try {
      if (profileQueue.isNotEmpty) {
        profileSummary = await profileQueue.removeAt(0)();
        if (profileSummary != null) {
          coins = profileSummary!.totalCoins;
        }
      }
    } catch (error) {
      profileError = error.toString();
    } finally {
      isProfileLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> refreshProfile() => loadProfile();

  @override
  Future<bool> updateProfileName(String name) async {
    profileNameUpdateCount++;
    isProfileLoading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    updatedProfileName = name.trim();
    isProfileLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    passwordChangeCount++;
    isProfileLoading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    isProfileLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<void> signOutAfterPasswordChange() async {
    passwordChangeSignOutCount++;
    await logout();
  }

  @override
  Future<bool> login(String email, String password) async {
    loginCount++;
    isBusy = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);
    user = XUser(id: 'user-1', name: 'Nam', email: email, role: 'STUDENT');
    isBusy = false;
    notifyListeners();
    return true;
  }

  @override
  Future<void> loadAdminChapters() async {
    chapters
      ..clear()
      ..addAll(const [
        Chapter(
          id: 'chapter-1',
          title: 'Chuyển động cơ học',
          description: 'Mô tả',
          orderIndex: 1,
        ),
        Chapter(
          id: 'chapter-2',
          title: 'Lực và áp suất',
          description: 'Mô tả',
          orderIndex: 2,
        ),
      ]);
    notifyListeners();
  }

  @override
  Future<void> loadAdminLessons() async {
    await loadAdminChapters();
    adminLessons
      ..clear()
      ..addAll([
        Lesson(
          id: 'lesson-1',
          chapterId: 'chapter-1',
          title: 'Chuyển động đều',
          content: 'content',
          formulaLatex: '',
          estimatedMinutes: 10,
          simulation: FormulaSimulationConfig.empty(),
          questions: const [],
          orderIndex: 1,
        ),
        Lesson(
          id: 'lesson-2',
          chapterId: 'chapter-1',
          title: 'Vận tốc trung bình',
          content: 'content',
          formulaLatex: '',
          estimatedMinutes: 10,
          simulation: FormulaSimulationConfig.empty(),
          questions: const [],
          orderIndex: 2,
        ),
      ]);
    notifyListeners();
  }

  @override
  Future<AdminQuestionPage> fetchAdminQuestions({
    String? lessonId,
    String? chapterId,
    String? search,
    String? difficulty,
    int page = 1,
    int limit = 20,
  }) async {
    adminQuestionFetchCount++;
    lastAdminSearch = search;
    lastAdminChapterId = chapterId;
    lastAdminLessonId = lessonId;
    lastAdminDifficulty = difficulty;
    if (adminQuestionCompleter != null) {
      return adminQuestionCompleter!.future;
    }
    var items = adminQuestionPage.items;
    if (lessonId != null && lessonId.isNotEmpty) {
      items = items.where((question) => question.lessonId == lessonId).toList();
    }
    if (chapterId != null && chapterId.isNotEmpty) {
      items = items
          .where((question) => question.chapterId == chapterId)
          .toList();
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      items = items
          .where((question) => question.difficulty == difficulty)
          .toList();
    }
    if (search != null && search.trim().isNotEmpty) {
      items = items
          .where(
            (question) =>
                question.question.toLowerCase().contains(search.toLowerCase()),
          )
          .toList();
    }
    return AdminQuestionPage(
      items: items,
      page: page,
      limit: limit,
      total: items.length,
      totalPages: items.isEmpty ? 0 : 1,
    );
  }

  @override
  Future<Question> fetchAdminQuestionDetail(String id) async {
    return adminQuestionPage.items.firstWhere((question) => question.id == id);
  }

  @override
  Future<Question> writeAdminQuestion(
    Question question, {
    required bool isUpdate,
  }) async {
    adminWriteCount++;
    lastWrittenQuestion = question;
    if (question.question == 'fail') throw Exception('Validation failed');
    return question;
  }

  @override
  Future<void> removeAdminQuestion(String id) async {
    adminDeleteCount++;
    adminQuestionPage = AdminQuestionPage(
      items: adminQuestionPage.items
          .where((question) => question.id != id)
          .toList(),
      page: 1,
      limit: 20,
      total: adminQuestionPage.total - 1,
      totalPages: 1,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> reorderAdminQuestions({
    required String lessonId,
    required List<String> questionIds,
  }) async {
    adminReorderCount++;
    lastReorderQuestionIds = questionIds;
    if (questionIds.contains('fail')) {
      throw Exception('Reorder failed');
    }
    adminQuestionPage = AdminQuestionPage(
      items: questionIds
          .map(
            (id) => adminQuestionPage.items.firstWhere(
              (question) => question.id == id,
            ),
          )
          .toList(),
      page: 1,
      limit: 20,
      total: adminQuestionPage.total,
      totalPages: adminQuestionPage.totalPages,
    );
    return [
      for (var i = 0; i < questionIds.length; i++)
        {'id': questionIds[i], 'orderIndex': i + 1},
    ];
  }

  @override
  Future<QuizAttempt?> submitQuiz(
    String lessonId,
    Map<String, int> answers, {
    int durationSeconds = 0,
  }) async {
    submitCount++;
    lastDurationSeconds = durationSeconds;
    lastAnswers = Map<String, int>.from(answers);
    if (submitCompleter != null) {
      return submitCompleter!.future;
    }
    if (staleSubmit) {
      quizSubmitError = 'Bộ câu hỏi đã được cập nhật. Vui lòng tải lại quiz.';
      return null;
    }
    if (failSubmit) {
      quizSubmitError = 'Submit failed';
      return null;
    }
    lastAttempt = QuizAttempt(
      attemptId: 'attempt-1',
      lessonId: lessonId,
      answers: answers,
      score: 10,
      earnedCoins: 0,
      newBadges: const [],
      correctCount: answers.length,
      totalQuestions: _questions.length,
      durationSeconds: durationSeconds,
    );
    quizResultsByLesson[lessonId] = lastAttempt!;
    await loadProgressDashboard();
    await loadProfile();
    return lastAttempt;
  }

  @override
  Future<void> logout() async {
    user = null;
    coins = 0;
    badges.clear();
    completedLessons.clear();
    lastAttempt = null;
    progressDashboard = null;
    profileSummary = null;
    quizResultsByLesson.clear();
    router?.go('/login');
    notifyListeners();
  }
}

GoRouter _buildTestRouter({
  required FakeAppState state,
  String initialLocation = '/quiz/lesson-1',
  QuizAttempt? initialResult,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home route')),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, routeState) =>
            Scaffold(body: Text('Lesson ${routeState.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (_, routeState) =>
            QuizScreen(lessonId: routeState.pathParameters['id'] ?? 'lesson-1'),
      ),
      GoRoute(
        path: '/quiz/:id/result',
        builder: (_, routeState) => QuizResultScreen(
          lessonId: routeState.pathParameters['id'] ?? 'lesson-1',
          initialAttempt: routeState.extra is QuizAttempt
              ? routeState.extra! as QuizAttempt
              : initialResult,
        ),
      ),
    ],
  );
}

Future<GoRouter> _pumpRouter(
  WidgetTester tester,
  FakeAppState state,
  GoRouter router,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return router;
}

Future<GoRouter> _pumpQuiz(WidgetTester tester, FakeAppState state) async {
  final router = _buildTestRouter(state: state);
  await _pumpRouter(tester, state, router);
  return router;
}

Future<GoRouter> _pumpProgress(WidgetTester tester, FakeAppState state) async {
  final router = GoRouter(
    initialLocation: '/progress',
    routes: [
      GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
      GoRoute(
        path: '/offline',
        builder: (_, _) => const Scaffold(body: Text('Offline route')),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('Profile route')),
      ),
    ],
  );
  await _pumpRouter(tester, state, router);
  return router;
}

Future<void> _pumpAdminQuestions(
  WidgetTester tester,
  FakeAppState state,
) async {
  await tester.binding.setSurfaceSize(const Size(1500, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  state.loading = false;
  state.user = const XUser(
    id: 'admin-1',
    name: 'Admin User',
    email: 'admin@example.com',
    role: 'ADMIN',
  );
  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const MaterialApp(home: AdminQuestionsScreen()),
    ),
  );
}

Future<GoRouter> _pumpProfile(
  WidgetTester tester,
  FakeAppState state, {
  Size? surfaceSize,
  bool useRealLogin = false,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
  }
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => useRealLogin
            ? const LoginScreen()
            : const Scaffold(body: Text('Login route')),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home route')),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/offline',
        builder: (_, _) => const Scaffold(body: Text('Offline route')),
      ),
    ],
  );
  state.router = router;
  await _pumpRouter(tester, state, router);
  return router;
}

Future<GoRouter> _pumpResult(
  WidgetTester tester,
  FakeAppState state,
  QuizAttempt? attempt, {
  String lessonId = 'lesson-1',
}) async {
  final router = GoRouter(
    initialLocation: '/quiz/$lessonId/result',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('Home route')),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, routeState) =>
            Scaffold(body: Text('Lesson ${routeState.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/quiz/:id/result',
        builder: (_, routeState) => QuizResultScreen(
          lessonId: routeState.pathParameters['id'] ?? lessonId,
          initialAttempt: attempt,
        ),
      ),
    ],
  );

  await _pumpRouter(tester, state, router);
  await tester.pumpAndSettle();
  return router;
}

Future<void> _loadQuiz(WidgetTester tester, FakeAppState state) async {
  await _pumpQuiz(tester, state);
  await tester.pump();
  await tester.pump();
}

Future<void> _selectOnlyQuestionAndOpenConfirm(WidgetTester tester) async {
  await tester.tap(find.text('A1'));
  await tester.pump();
  await tester.tap(find.text('Nộp bài'));
  await tester.pumpAndSettle();
}

void main() {
  test('api client clears tokens when refresh token fails', () async {
    final tokenStorage = FakeTokenStorage();
    final adapter = FailingRefreshAdapter();
    var unauthorized = false;
    final client = ApiClient(
      'http://localhost:3000',
      tokenStorage: tokenStorage,
      onUnauthorized: () => unauthorized = true,
    )..dio.httpClientAdapter = adapter;

    await expectLater(
      client.dio.get<Map<String, dynamic>>('/api/protected'),
      throwsA(isA<DioException>()),
    );

    expect(adapter.protectedCalls, 1);
    expect(adapter.refreshCalls, 1);
    expect(tokenStorage.cleared, isTrue);
    expect(unauthorized, isTrue);
  });

  QuizAttempt makeAttempt({
    int earnedCoins = 20,
    List<XBadge> badges = const [],
    List<QuizReviewItem> review = const [],
  }) {
    return QuizAttempt(
      attemptId: 'attempt-42',
      lessonId: 'lesson-1',
      answers: const {'q1': 0, 'q2': 1},
      score: 8,
      earnedCoins: earnedCoins,
      totalCoins: 150,
      newBadges: badges,
      correctCount: 1,
      totalQuestions: 2,
      durationSeconds: 123,
      review: review,
    );
  }

  ProgressDashboard makeDashboard({
    int completedLessons = 3,
    int totalLessons = 6,
    List<RecentQuizAttempt>? attempts,
  }) {
    return ProgressDashboard(
      overallProgress: totalLessons == 0
          ? 0
          : completedLessons / totalLessons * 100,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      averageScore: 8.24,
      totalCoins: 140,
      chapterProgress: const [
        ChapterProgressSummary(
          chapterId: 'motion',
          title: 'Chuyen dong co hoc',
          completedLessons: 2,
          totalLessons: 2,
          progressPercent: 100,
        ),
        ChapterProgressSummary(
          chapterId: 'electric',
          title: 'Dien hoc',
          completedLessons: 1,
          totalLessons: 4,
          progressPercent: 25,
        ),
      ],
      recentAttempts:
          attempts ??
          [
            for (var i = 0; i < 5; i++)
              RecentQuizAttempt(
                attemptId: 'attempt-$i',
                lessonId: 'lesson-$i',
                lessonTitle: 'Bai ${i + 1}',
                score: (6 + i).clamp(0, 10).toDouble(),
                submittedAt: DateTime(2026, 7, 13, i),
                durationSeconds: 120 + i,
              ),
          ],
    );
  }

  ProfileSummary makeProfile({
    int coins = 150,
    List<AchievementBadge> earned = const [],
    List<AchievementBadge> locked = const [],
    List<RecentQuizAttempt> attempts = const [],
  }) {
    return ProfileSummary(
      user: const ProfileUser(
        id: 'user-1',
        name: 'Nguyen Van Nam',
        email: 'nam@example.com',
      ),
      totalCoins: coins,
      completedLessons: 3,
      averageScore: 8.2,
      recentAttempts: attempts,
      earnedBadges: earned,
      lockedBadges: locked,
    );
  }

  const earnedBadge = AchievementBadge(
    id: 'starter',
    name: 'Khoi dau',
    description: 'Hoan thanh bai dau tien',
    iconUrl: '',
    ruleKey: 'complete_first_lesson',
    isEarned: true,
    achievedAt: null,
  );

  const lockedBadge = AchievementBadge(
    id: 'scientist',
    name: 'Nha bac hoc',
    description: 'Hoan thanh tat ca bai',
    iconUrl: '',
    ruleKey: 'complete_all_lessons',
    isEarned: false,
    progressCurrent: 1,
    progressTarget: 3,
  );

  testWidgets('shows loading while questions are loading', (tester) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Completer<List<Question>>().future);

    await _pumpQuiz(tester, state);
    await tester.pump();

    expect(find.text('Đang tải câu hỏi...'), findsOneWidget);
  });

  testWidgets('shows load error and retries', (tester) async {
    final state = FakeAppState();
    state.loadQueue
      ..add(() {
        state.errorMessage = 'Network down';
        return Future.value(const []);
      })
      ..add(() {
        state.errorMessage = null;
        return Future.value(_questions);
      });

    await _loadQuiz(tester, state);

    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Question 1'), findsOneWidget);
    expect(state.loadCount, 2);
  });

  testWidgets('keeps selected answer when moving next and previous', (
    tester,
  ) async {
    final state = FakeAppState();
    await _loadQuiz(tester, state);

    await tester.tap(find.text('A1'));
    await tester.pump();
    await tester.tap(find.text('Tiep tuc'));
    await tester.pump();
    expect(find.text('Question 2'), findsOneWidget);

    await tester.tap(find.text('Truoc'));
    await tester.pump();

    expect(find.text('Question 1'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
  });

  testWidgets('next is disabled until current question has an answer', (
    tester,
  ) async {
    final state = FakeAppState();
    await _loadQuiz(tester, state);

    final next = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tiep tuc'),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('double tapping submit confirmation sends one request', (
    tester,
  ) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Future.value([_questions.first]));
    state.submitCompleter = Completer<QuizAttempt?>();
    await _loadQuiz(tester, state);
    await _selectOnlyQuestionAndOpenConfirm(tester);

    final confirm = find.text('Nộp bài').last;
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await tester.pump();

    expect(state.submitCount, 1);
    state.submitCompleter!.complete(
      QuizAttempt(
        attemptId: 'attempt-1',
        lessonId: 'lesson-1',
        answers: const {'q1': 0},
        score: 10,
        earnedCoins: 0,
        newBadges: const [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('timer and button submit race sends one request', (tester) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Future.value([_questions.first]));
    state.submitCompleter = Completer<QuizAttempt?>();
    await _loadQuiz(tester, state);
    await tester.tap(find.text('A1'));
    await tester.pump();

    await tester.pump(const Duration(seconds: 299));
    await tester.tap(find.text('Nộp bài'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(state.submitCount, 1);
    expect(state.lastDurationSeconds, 300);
    state.submitCompleter!.complete(
      QuizAttempt(
        attemptId: 'attempt-1',
        lessonId: 'lesson-1',
        answers: const {'q1': 0},
        score: 10,
        earnedCoins: 0,
        newBadges: const [],
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('submit error keeps answers and allows retry', (tester) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Future.value([_questions.first]));
    state.failSubmit = true;
    await _loadQuiz(tester, state);
    await _selectOnlyQuestionAndOpenConfirm(tester);
    await tester.tap(find.text('Nộp bài').last);
    await tester.pumpAndSettle();

    expect(find.text('Submit failed'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);

    state.failSubmit = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Kết quả'), findsOneWidget);
  });

  testWidgets('disposing quiz cancels timer', (tester) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Future.value([_questions.first]));
    await _loadQuiz(tester, state);

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 301));

    expect(state.submitCount, 0);
  });

  test('parses quiz attempt score from int and double', () {
    final fromInt = QuizAttempt.fromSubmitJson({
      'attemptId': 'a1',
      'lessonId': 'lesson-1',
      'score': 8,
      'earnedCoins': 0,
      'newBadges': [],
    }, const {});
    final fromDouble = QuizAttempt.fromSubmitJson({
      'attemptId': 'a2',
      'lessonId': 'lesson-1',
      'score': 8.5,
      'earnedCoins': 0,
      'newBadges': [],
    }, const {});

    expect(fromInt.score, 8.0);
    expect(fromDouble.score, 8.5);
  });

  testWidgets('result handles empty badge list and zero earned coins', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpResult(tester, state, makeAttempt(earnedCoins: 0));

    expect(find.text('Không nhận thêm xu'), findsOneWidget);
    expect(find.text('Huy hiệu mới'), findsNothing);
  });

  testWidgets('result shows badge fallback icon when icon url is empty', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpResult(
      tester,
      state,
      makeAttempt(
        badges: const [
          XBadge(
            id: 'badge-1',
            name: 'Perfect',
            description: 'Score 10',
            iconUrl: '',
            ruleKey: 'PERFECT_SCORE',
          ),
        ],
      ),
    );

    expect(find.text('Perfect'), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
  });

  testWidgets(
    'result renders backend review correctness without recalculating',
    (tester) async {
      final state = FakeAppState();
      await _pumpResult(
        tester,
        state,
        makeAttempt(
          review: const [
            QuizReviewItem(
              questionId: 'q1',
              question: 'Correct review',
              options: ['A', 'B'],
              correctOption: 1,
              selectedOption: 0,
              isCorrect: true,
              explanation: 'Backend says correct',
            ),
            QuizReviewItem(
              questionId: 'q2',
              question: 'Wrong review',
              options: ['C', 'D'],
              correctOption: 1,
              selectedOption: null,
              isCorrect: false,
              explanation: 'No answer',
            ),
          ],
        ),
      );

      expect(find.text('Correct review'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Wrong review'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      expect(find.text('Bạn chưa chọn đáp án.'), findsOneWidget);
    },
  );

  testWidgets('result route without state shows safe missing state', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpResult(tester, state, null);

    expect(
      find.text('Không tìm thấy kết quả quiz cho lần làm này.'),
      findsOneWidget,
    );
  });

  testWidgets('home CTA navigates with go', (tester) async {
    final state = FakeAppState();
    await _pumpResult(tester, state, makeAttempt());

    await tester.tap(find.text('Về trang chủ').first);
    await tester.pumpAndSettle();

    expect(find.text('Home route'), findsOneWidget);
  });

  testWidgets('next lesson CTA uses the following lesson when available', (
    tester,
  ) async {
    final state = FakeAppState();
    final simulation = FormulaSimulationConfig.empty();
    state.lessonsByChapter['chapter-1'] = [
      Lesson(
        id: 'lesson-1',
        chapterId: 'chapter-1',
        title: 'One',
        content: '',
        formulaLatex: '',
        estimatedMinutes: 10,
        simulation: simulation,
        questions: const [],
      ),
      Lesson(
        id: 'lesson-2',
        chapterId: 'chapter-1',
        title: 'Two',
        content: '',
        formulaLatex: '',
        estimatedMinutes: 10,
        simulation: simulation,
        questions: const [],
      ),
    ];

    await _pumpResult(tester, state, makeAttempt());
    await tester.tap(find.text('Học bài tiếp theo'));
    await tester.pumpAndSettle();

    expect(find.text('Lesson lesson-2'), findsOneWidget);
  });

  testWidgets('submit result navigation replaces quiz route', (tester) async {
    final state = FakeAppState();
    state.loadQueue.add(() => Future.value([_questions.first]));
    final router = await _pumpQuiz(tester, state);
    await tester.pump();
    await tester.pump();

    await _selectOnlyQuestionAndOpenConfirm(tester);
    await tester.tap(find.text('Nộp bài').last);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/quiz/lesson-1/result',
    );
    expect(router.canPop(), isFalse);
  });

  testWidgets('result screen does not refresh state on build', (tester) async {
    final state = FakeAppState();
    await _pumpResult(tester, state, makeAttempt());

    expect(state.loadCount, 0);
    expect(state.submitCount, 0);
  });

  testWidgets('progress dashboard shows loading', (tester) async {
    final state = FakeAppState();
    state.dashboardQueue.add(() => Completer<ProgressDashboard?>().future);

    await _pumpProgress(tester, state);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('progress dashboard shows error and retries', (tester) async {
    final state = FakeAppState();
    state.dashboardQueue
      ..add(() => Future<ProgressDashboard?>.error('Network down'))
      ..add(() => Future.value(makeDashboard()));

    await _pumpProgress(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.text('Network down'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();

    expect(find.text('50.0%'), findsOneWidget);
    expect(state.dashboardLoadCount, 2);
  });

  testWidgets('progress dashboard shows empty state', (tester) async {
    final state = FakeAppState();
    state.dashboardQueue.add(
      () => Future.value(makeDashboard(completedLessons: 0, attempts: [])),
    );

    await _pumpProgress(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('Chưa có tiến độ học tập'), findsOneWidget);
  });

  testWidgets('progress dashboard shows data and chapter progress', (
    tester,
  ) async {
    final state = FakeAppState();
    state.dashboardQueue.add(() => Future.value(makeDashboard()));

    await _pumpProgress(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('3/6'), findsOneWidget);
    expect(find.text('8.24'), findsOneWidget);
    expect(find.text('140'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Chuyen dong co hoc'), findsOneWidget);
    expect(find.text('Dien hoc'), findsOneWidget);
  });

  testWidgets('progress chart handles 0, 1, and 5 attempts', (tester) async {
    final state = FakeAppState();
    state.dashboardQueue.add(
      () => Future.value(makeDashboard(completedLessons: 1, attempts: [])),
    );
    await _pumpProgress(tester, state);
    await tester.pump();
    await tester.pump();
    expect(find.text('Chưa có lần làm quiz nào.'), findsOneWidget);

    state.progressDashboard = makeDashboard(
      completedLessons: 1,
      attempts: [
        RecentQuizAttempt(
          attemptId: 'a1',
          lessonId: 'l1',
          lessonTitle: 'Mot',
          score: 7,
          submittedAt: DateTime(2026),
          durationSeconds: 1,
        ),
      ],
    );
    state.notifyListeners();
    await tester.pump();
    expect(find.text('Mot'), findsOneWidget);

    state.progressDashboard = makeDashboard();
    state.notifyListeners();
    await tester.pump();
    expect(find.text('Bai 1'), findsOneWidget);
    expect(find.text('Bai 5'), findsOneWidget);
  });

  testWidgets('progress refresh keeps stale data and shows snackbar on error', (
    tester,
  ) async {
    final state = FakeAppState();
    state.progressDashboard = makeDashboard();
    state.dashboardQueue.add(
      () => Future<ProgressDashboard?>.error('Refresh failed'),
    );

    await _pumpProgress(tester, state);
    await tester.pump();
    await tester.tap(find.byTooltip('Làm mới'));
    await tester.pump();
    await tester.pump();

    expect(find.text('50.0%'), findsOneWidget);
    expect(find.text('Refresh failed'), findsOneWidget);
  });

  testWidgets('quiz submit refreshes progress dashboard', (tester) async {
    final state = FakeAppState();
    await state.submitQuiz('lesson-1', const {'q1': 0});

    expect(state.dashboardLoadCount, 1);
  });

  testWidgets('quiz state resets between lessons', (tester) async {
    final state = FakeAppState();
    state.loadQueue
      ..add(
        () => Future.value([
          const Question(
            id: 'l1-q1',
            lessonId: 'lesson-1',
            question: 'Lesson 1 question',
            options: ['A', 'B'],
            explanation: '',
          ),
        ]),
      )
      ..add(
        () => Future.value([
          const Question(
            id: 'l2-q1',
            lessonId: 'lesson-2',
            question: 'Lesson 2 question',
            options: ['C', 'D'],
            explanation: '',
          ),
        ]),
      );
    final router = await _pumpQuiz(tester, state);
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('A'));
    await tester.pump();

    router.go('/quiz/lesson-2');
    await tester.pump();
    await tester.pump();

    expect(find.text('Lesson 2 question'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsNothing);
  });

  testWidgets('profile shows earned and locked badges', (tester) async {
    final state = FakeAppState();
    state.profileQueue.add(
      () => Future.value(
        makeProfile(earned: [earnedBadge], locked: [lockedBadge]),
      ),
    );

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.text('Nguyen Van Nam'), findsOneWidget);
    expect(find.text('nam@example.com'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Khoi dau'), findsOneWidget);
    expect(find.text('Nha bac hoc'), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
  });

  testWidgets('profile handles badge icon null and opens detail', (
    tester,
  ) async {
    final state = FakeAppState();
    state.profileQueue.add(
      () => Future.value(makeProfile(earned: [earnedBadge])),
    );

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Khoi dau'));
    await tester.pumpAndSettle();

    expect(find.text('Hoan thanh bai dau tien'), findsOneWidget);
    expect(find.text('Đã đạt'), findsOneWidget);
  });

  testWidgets('profile locked badge detail shows backend progress', (
    tester,
  ) async {
    final state = FakeAppState();
    state.profileQueue.add(
      () => Future.value(makeProfile(locked: [lockedBadge])),
    );

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nha bac hoc'));
    await tester.pumpAndSettle();

    expect(find.text('Tiến độ: 1/3'), findsOneWidget);
  });

  testWidgets('profile shows empty chart and empty badges safely', (
    tester,
  ) async {
    final state = FakeAppState();
    state.profileQueue.add(() => Future.value(makeProfile()));

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.text('Chưa có điểm quiz nào.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có huy hiệu nào.'), findsOneWidget);
  });

  testWidgets('profile error retries and refreshes coins', (tester) async {
    final state = FakeAppState();
    state.profileQueue
      ..add(() => Future<ProfileSummary?>.error('Profile down'))
      ..add(() => Future.value(makeProfile(coins: 200)));

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.pump();

    expect(find.text('Profile down'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    await tester.pump();

    expect(find.text('200'), findsOneWidget);
    expect(state.coins, 200);
  });

  testWidgets('profile refresh keeps stale data and shows snackbar on error', (
    tester,
  ) async {
    final state = FakeAppState();
    state.profileSummary = makeProfile(coins: 150);
    state.profileQueue.add(
      () => Future<ProfileSummary?>.error('Profile stale'),
    );

    await _pumpProfile(tester, state);
    await tester.pump();
    await tester.tap(find.byTooltip('Làm mới'));
    await tester.pump();
    await tester.pump();

    expect(find.text('150'), findsOneWidget);
    expect(find.text('Profile stale'), findsOneWidget);
  });

  testWidgets(
    'profile updates name without disposing dialog dependencies early',
    (tester) async {
      final state = FakeAppState()..profileSummary = makeProfile();

      await _pumpProfile(tester, state);
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cập nhật họ tên'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Nguyễn Văn An');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(state.profileNameUpdateCount, 1);
      expect(state.updatedProfileName, 'Nguyễn Văn An');
      expect(find.text('Đã cập nhật hồ sơ.'), findsOneWidget);
    },
  );

  testWidgets('password change closes dialog before navigating to login', (
    tester,
  ) async {
    final state = FakeAppState()
      ..user = const XUser(
        id: 'user-1',
        name: 'Nam',
        email: 'nam@example.com',
        role: 'STUDENT',
      )
      ..profileSummary = makeProfile();

    final router = await _pumpProfile(tester, state, useRealLogin: true);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '123456');
    await tester.enterText(fields.at(1), '654321');
    await tester.enterText(fields.at(2), '654321');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.passwordChangeCount, 1);
    expect(state.passwordChangeSignOutCount, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    expect(find.text('Đăng nhập X-Physics'), findsOneWidget);

    final loginFields = find.byType(TextField);
    await tester.enterText(loginFields.at(0), 'nam@example.com');
    await tester.enterText(loginFields.at(1), '654321');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(state.loginCount, 1);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    expect(find.text('Home route'), findsOneWidget);
  });

  testWidgets('logout clears sensitive state and goes to login', (
    tester,
  ) async {
    final state = FakeAppState();
    state.user = const XUser(
      id: 'user-1',
      name: 'Nam',
      email: 'nam@example.com',
      role: 'STUDENT',
      coins: 10,
    );
    state.profileSummary = makeProfile(earned: [earnedBadge]);
    state.progressDashboard = makeDashboard();

    final router = await _pumpProfile(tester, state);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.text('Login route'), findsOneWidget);
    expect(state.user, isNull);
    expect(state.profileSummary, isNull);
    expect(state.progressDashboard, isNull);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('protected routes redirect to login when unauthenticated', (
    tester,
  ) async {
    final state = FakeAppState();
    state.loading = false;
    state.user = null;
    final router = buildRouter(state);

    await _pumpRouter(tester, state, router);
    router.go('/profile');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets(
    'admin questions shows loading then list data with answer and chips',
    (tester) async {
      final state = FakeAppState();
      state.adminQuestionCompleter = Completer<AdminQuestionPage>();

      await _pumpAdminQuestions(tester, state);
      await tester.pump();
      expect(find.text('Đang tải câu hỏi...'), findsOneWidget);

      state.adminQuestionCompleter!.complete(state.adminQuestionPage);
      state.adminQuestionCompleter = null;
      await tester.pumpAndSettle();

      expect(find.text('Quản lý Câu hỏi'), findsOneWidget);
      expect(find.text('B. 50 m'), findsOneWidget);
      expect(find.text('C. 5 m/s'), findsOneWidget);
      expect(find.text('Dễ'), findsOneWidget);
      expect(find.text('Trung bình'), findsOneWidget);
    },
  );

  testWidgets(
    'admin questions filters call API and clear filters resets them',
    (tester) async {
      final state = FakeAppState();
      await _pumpAdminQuestions(tester, state);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'ohm');
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(state.lastAdminSearch, 'ohm');

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Khó').last);
      await tester.pumpAndSettle();
      expect(state.lastAdminDifficulty, 'HARD');

      await tester.tap(find.text('Xóa bộ lọc').first);
      await tester.pumpAndSettle();
      expect(state.lastAdminDifficulty, isNull);
    },
  );

  testWidgets('admin questions shows filtered empty state', (tester) async {
    final state = FakeAppState()
      ..adminQuestionPage = const AdminQuestionPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 0,
      );
    await _pumpAdminQuestions(tester, state);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'missing');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy câu hỏi phù hợp.'), findsOneWidget);
  });

  testWidgets(
    'admin questions validates create form and prevents double save',
    (tester) async {
      final state = FakeAppState();
      await _pumpAdminQuestions(tester, state);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm câu hỏi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu'));
      await tester.pump();
      expect(find.text('Bắt buộc'), findsWidgets);
      expect(state.adminWriteCount, 0);

      await tester.enterText(find.byType(TextFormField).at(0), 'New question');
      await tester.enterText(find.byType(TextFormField).at(1), 'A');
      await tester.enterText(find.byType(TextFormField).at(2), 'B');
      await tester.enterText(find.byType(TextFormField).at(3), 'C');
      await tester.enterText(find.byType(TextFormField).at(4), 'D');
      await tester.enterText(find.byType(TextFormField).at(5), 'Because');
      await tester.ensureVisible(find.text('Lưu').last);
      await tester.tap(find.text('Lưu').last);
      await tester.pumpAndSettle();

      expect(state.adminWriteCount, 1);
      expect(state.lastWrittenQuestion?.question, 'New question');
    },
  );

  testWidgets('admin questions detail and delete work through dialogs', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpAdminQuestions(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xem').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết câu hỏi'), findsOneWidget);
    expect(find.text('s = v * t = 50 m'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa').first);
    await tester.pumpAndSettle();
    expect(find.text('Xóa câu hỏi?'), findsOneWidget);
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();

    expect(state.adminDeleteCount, 1);
  });

  testWidgets('admin questions reorder is enabled only for a selected lesson', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpAdminQuestions(tester, state);
    await tester.pumpAndSettle();

    var reorder = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sắp xếp'),
    );
    expect(reorder.onPressed, isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển động đều').last);
    await tester.pumpAndSettle();

    reorder = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Sắp xếp'),
    );
    expect(reorder.onPressed, isNotNull);
  });

  testWidgets('admin questions reorder dialog cancel and save behavior', (
    tester,
  ) async {
    final state = FakeAppState();
    await _pumpAdminQuestions(tester, state);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chuyển động đều').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sắp xếp'));
    await tester.pumpAndSettle();
    expect(find.text('Sắp xếp câu hỏi'), findsOneWidget);
    expect(find.textContaining('Một vật chuyển động'), findsWidgets);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(state.adminReorderCount, 0);

    await tester.tap(find.text('Sắp xếp'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byIcon(Icons.drag_handle_rounded).first,
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu').last);
    await tester.pumpAndSettle();

    expect(state.adminReorderCount, 1);
    expect(state.lastReorderQuestionIds, isNotNull);
    expect(state.lastReorderQuestionIds!.toSet(), {'aq1', 'aq2'});
  });

  testWidgets('stale quiz 409 shows reload and reload resets answers', (
    tester,
  ) async {
    final state = FakeAppState();
    state.loadQueue
      ..add(() => Future.value([_questions.first]))
      ..add(
        () => Future.value([
          const Question(
            id: 'q3',
            lessonId: 'lesson-1',
            question: 'Reloaded question',
            options: ['A3', 'B3'],
            explanation: '',
          ),
        ]),
      );
    state.staleSubmit = true;
    await _loadQuiz(tester, state);

    await tester.tap(find.text('A1'));
    await tester.pump();
    await tester.tap(find.text('Nộp bài'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nộp bài').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('Bộ câu hỏi đã được cập nhật'), findsOneWidget);
    expect(find.text('Tải lại quiz'), findsOneWidget);

    await tester.tap(find.text('Tải lại quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Reloaded question'), findsOneWidget);
    final submitButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Nộp bài'),
    );
    expect(submitButton.onPressed, isNull);
  });

  testWidgets('student cannot access admin questions route', (tester) async {
    final state = FakeAppState()
      ..loading = false
      ..user = const XUser(
        id: 'student-1',
        name: 'Student',
        email: 'student@example.com',
        role: 'STUDENT',
      );
    final router = buildRouter(state);

    await _pumpRouter(tester, state, router);
    router.go('/admin/questions');
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('profile uses three badge columns on wide screens', (
    tester,
  ) async {
    final state = FakeAppState();
    state.profileQueue.add(
      () => Future.value(
        makeProfile(
          earned: const [earnedBadge],
          locked: const [lockedBadge, lockedBadge, lockedBadge],
        ),
      ),
    );

    await _pumpProfile(tester, state, surfaceSize: const Size(800, 900));
    await tester.pump();
    await tester.pump();

    final grids = find.byType(GridView);
    expect(grids, findsOneWidget);
    final grid = tester.widget<GridView>(grids);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    await tester.binding.setSurfaceSize(null);
  });
}
