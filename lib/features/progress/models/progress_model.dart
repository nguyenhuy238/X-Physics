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

class ChapterProgressModel {
  const ChapterProgressModel({
    required this.chapterId,
    required this.title,
    required this.completedLessons,
    required this.totalLessons,
    required this.progress,
  });

  final String chapterId;
  final String title;
  final int completedLessons;
  final int totalLessons;
  final double progress;

  factory ChapterProgressModel.fromJson(Map<dynamic, dynamic> json) =>
      ChapterProgressModel(
        chapterId:
            json['chapterId'] as String? ?? json['chapter_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        completedLessons:
            (json['completedLessons'] as num? ??
                    json['completed_lessons'] as num? ??
                    0)
                .toInt(),
        totalLessons:
            (json['totalLessons'] as num? ?? json['total_lessons'] as num? ?? 0)
                .toInt(),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
      );
}

class RecentAttemptModel {
  const RecentAttemptModel({
    required this.attemptId,
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.submittedAt,
  });

  final String attemptId;
  final String lessonId;
  final String lessonTitle;
  final double score;
  final int correctCount;
  final int totalQuestions;
  final DateTime? submittedAt;

  factory RecentAttemptModel.fromJson(
    Map<dynamic, dynamic> json,
  ) => RecentAttemptModel(
    attemptId: json['attemptId'] as String? ?? json['id'] as String? ?? '',
    lessonId: json['lessonId'] as String? ?? json['lesson_id'] as String? ?? '',
    lessonTitle:
        json['lessonTitle'] as String? ?? json['lesson_title'] as String? ?? '',
    score: (json['score'] as num?)?.toDouble() ?? 0,
    correctCount:
        (json['correctCount'] as num? ?? json['correct_count'] as num? ?? 0)
            .toInt(),
    totalQuestions:
        (json['totalQuestions'] as num? ?? json['total_questions'] as num? ?? 0)
            .toInt(),
    submittedAt: DateTime.tryParse(
      json['submittedAt'] as String? ?? json['submitted_at'] as String? ?? '',
    ),
  );
}

class ProgressDashboardModel {
  const ProgressDashboardModel({
    required this.overallProgress,
    required this.completedLessons,
    required this.totalLessons,
    required this.averageScore,
    required this.totalCoins,
    required this.chapterProgress,
    required this.recentAttempts,
  });

  final double overallProgress;
  final int completedLessons;
  final int totalLessons;
  final double averageScore;
  final int totalCoins;
  final List<ChapterProgressModel> chapterProgress;
  final List<RecentAttemptModel> recentAttempts;

  factory ProgressDashboardModel.fromJson(Map<dynamic, dynamic> json) =>
      ProgressDashboardModel(
        overallProgress:
            (json['overallProgress'] as num? ??
                    json['overall_progress'] as num? ??
                    0)
                .toDouble(),
        completedLessons:
            (json['completedLessons'] as num? ??
                    json['completed_lessons'] as num? ??
                    0)
                .toInt(),
        totalLessons:
            (json['totalLessons'] as num? ?? json['total_lessons'] as num? ?? 0)
                .toInt(),
        averageScore:
            (json['averageScore'] as num? ?? json['average_score'] as num? ?? 0)
                .toDouble(),
        totalCoins:
            (json['totalCoins'] as num? ?? json['total_coins'] as num? ?? 0)
                .toInt(),
        chapterProgress:
            (json['chapterProgress'] as List? ??
                    json['chapter_progress'] as List? ??
                    const [])
                .map((item) => ChapterProgressModel.fromJson(item as Map))
                .toList(),
        recentAttempts:
            (json['recentAttempts'] as List? ??
                    json['recent_attempts'] as List? ??
                    const [])
                .map((item) => RecentAttemptModel.fromJson(item as Map))
                .toList(),
      );
}
