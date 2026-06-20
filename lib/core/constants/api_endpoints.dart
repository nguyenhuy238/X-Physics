class ApiEndpoints {
  const ApiEndpoints._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';
  static const logout = '/api/auth/logout';
  static const me = '/api/users/me';
  static const dashboard = '/api/dashboard/me';
  static const chapters = '/api/chapters';
  static const quizSubmit = '/api/quiz/submit';
  static const progressMe = '/api/progress/me';
  static const badgesMe = '/api/badges/me';
  static const syncProgress = '/api/sync/progress';

  static String chapter(String id) => '/api/chapters/$id';
  static String chapterLessons(String id) => '/api/chapters/$id/lessons';
  static String lesson(String id) => '/api/lessons/$id';
  static String lessonSimulations(String id) => '/api/lessons/$id/simulations';
  static String lessonQuestions(String id) => '/api/lessons/$id/questions';
}
