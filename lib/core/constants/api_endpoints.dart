class ApiEndpoints {
  const ApiEndpoints._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const register = '/api/auth/register';
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';
  static const refreshToken = '/api/auth/refresh-token';
  static const logout = '/api/auth/logout';
  static const me = '/api/users/me';
  static const changePassword = '/api/users/me/change-password';
  static const dashboard = '/api/dashboard/me';
  static const progressDashboard = '/api/progress/dashboard/me';
  static const profileMe = '/api/profile/me';
  static const profileAchievements = '/api/profile/achievements';
  static const chapters = '/api/chapters';
  static const quizSubmit = '/api/quiz/submit';
  static const progressMe = '/api/progress/me';
  static const badgesMe = '/api/badges/me';
  static const syncProgress = '/api/sync/progress';
  static const syncDownloads = '/api/sync/downloads';
  static const adminUsers = '/api/admin/users';
  static const adminStatistics = '/api/admin/statistics';
  static const adminChapters = '/api/admin/chapters';
  static const adminLessons = '/api/admin/lessons';
  static const adminQuestions = '/api/admin/questions';
  static const adminQuestionsReorder = '/api/admin/questions/reorder';

  static String chapter(String id) => '/api/chapters/$id';
  static String chapterLessons(String id) => '/api/chapters/$id/lessons';
  static String lesson(String id) => '/api/lessons/$id';
  static String lessonSimulations(String id) => '/api/lessons/$id/simulations';
  static String lessonQuestions(String id) => '/api/lessons/$id/questions';
  static String adminChapter(String id) => '/api/admin/chapters/$id';
  static String adminLesson(String id) => '/api/admin/lessons/$id';
  static String adminQuestion(String id) => '/api/admin/questions/$id';
}
