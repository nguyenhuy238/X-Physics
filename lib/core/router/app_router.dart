import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/chapters/screens/chapter_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/lessons/screens/lesson_screen.dart';
import '../../features/offline/screens/offline_downloads_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/progress/application/app_state.dart';
import '../../features/quiz/screens/quiz_result_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';

GoRouter buildRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: appState,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/chapters/:id',
        builder: (_, state) =>
            ChapterDetailScreen(chapterId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quiz/:id',
        builder: (_, state) =>
            QuizScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/quiz/:id/result',
        builder: (_, state) =>
            QuizResultScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/offline',
        builder: (_, _) => const OfflineDownloadsScreen(),
      ),
    ],
  );
}
