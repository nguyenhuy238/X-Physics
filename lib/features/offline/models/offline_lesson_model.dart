class OfflineLessonModel {
  const OfflineLessonModel({
    required this.lessonId,
    required this.title,
    required this.downloadedAt,
  });

  final String lessonId;
  final String title;
  final DateTime downloadedAt;
}
