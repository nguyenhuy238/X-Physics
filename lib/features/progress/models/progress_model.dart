class ProgressModel {
  const ProgressModel({
    required this.lessonId,
    required this.status,
    required this.progressPercent,
  });

  final String lessonId;
  final String status;
  final int progressPercent;
}
