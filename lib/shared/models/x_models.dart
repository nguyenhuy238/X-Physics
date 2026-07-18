import 'dart:convert';

class XUser {
  const XUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.coins = 0,
  });
  final String id;
  final String name;
  final String email;
  final String role;
  final int coins;

  factory XUser.fromJson(Map<dynamic, dynamic> json) => XUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    coins: (json['coins'] as num?)?.toInt() ?? 0,
  );
}

int _jsonInt(Map<dynamic, dynamic> json, String camelKey, [String? snakeKey]) {
  final value = json[camelKey] ?? (snakeKey == null ? null : json[snakeKey]);
  return (value as num?)?.toInt() ?? 0;
}

double _jsonDouble(
  Map<dynamic, dynamic> json,
  String camelKey, [
  String? snakeKey,
]) {
  final value = json[camelKey] ?? (snakeKey == null ? null : json[snakeKey]);
  return (value as num?)?.toDouble() ?? 0;
}

String _jsonString(
  Map<dynamic, dynamic> json,
  String camelKey, [
  String? snakeKey,
]) {
  final value = json[camelKey] ?? (snakeKey == null ? null : json[snakeKey]);
  return value as String? ?? '';
}

DateTime? _jsonDate(
  Map<dynamic, dynamic> json,
  String camelKey, [
  String? snakeKey,
]) {
  final value = _jsonString(json, camelKey, snakeKey);
  return value.isEmpty ? null : DateTime.tryParse(value);
}

List<String> _jsonStringList(
  Map<dynamic, dynamic> json,
  String camelKey, [
  String? snakeKey,
]) {
  final value = json[camelKey] ?? (snakeKey == null ? null : json[snakeKey]);
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } on FormatException {
      throw FormatException('Invalid JSON list for $camelKey');
    }
  }
  throw FormatException('Missing JSON list for $camelKey');
}

class XBadge {
  const XBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.ruleKey,
  });

  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String ruleKey;

  factory XBadge.fromJson(Map<dynamic, dynamic> json) => XBadge(
    id: _jsonString(json, 'id'),
    name: _jsonString(json, 'name'),
    description: _jsonString(json, 'description'),
    iconUrl: _jsonString(json, 'iconUrl', 'icon_url').isNotEmpty
        ? _jsonString(json, 'iconUrl', 'icon_url')
        : _jsonString(json, 'icon'),
    ruleKey: _jsonString(json, 'ruleKey', 'rule_key'),
  );

  @override
  String toString() => name;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    this.icon = 'auto_stories',
    this.color = 0xFF2563EB,
    this.lessonCount = 0,
    this.orderIndex = 0,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String title;
  final String description;
  final String icon;
  final int color;
  final int lessonCount;
  final int orderIndex;
  final bool isPublished;
  final String? createdAt;
  final String? updatedAt;

  factory Chapter.fromJson(Map<dynamic, dynamic> json) => Chapter(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    color: switch (json['id'] as String? ?? '') {
      'motion' => 0xFF2563EB,
      'force' => 0xFF16A34A,
      'electric' => 0xFFF59E0B,
      _ => 0xFF7C3AED,
    },
    lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
    isPublished: json['isPublished'] as bool? ?? true,
    createdAt: json['createdAt'] as String?,
  );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.content,
    required this.formulaLatex,
    required this.estimatedMinutes,
    required this.simulation,
    required this.questions,
    this.orderIndex = 0,
    this.isPublished = true,
    this.createdAt,
    this.updatedAt,
  });
  final String id;
  final String chapterId;
  final String title;
  final String content;
  final String formulaLatex;
  final int estimatedMinutes;
  final FormulaSimulationConfig simulation;
  final List<Question> questions;
  final int orderIndex;
  final bool isPublished;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'title': title,
    'content': content,
    'formulaLatex': formulaLatex,
    'estimatedMinutes': estimatedMinutes,
    'simulation': simulation.toJson(),
    'questions': questions.map((q) => q.toJson()).toList(),
    'orderIndex': orderIndex,
    'isPublished': isPublished,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory Lesson.fromJson(Map<dynamic, dynamic> json) {
    final simulations = json['simulations'] as List?;
    final simulationJson =
        json['simulation'] ??
        (simulations == null || simulations.isEmpty ? null : simulations.first);
    return Lesson(
      id: json['id'] as String,
      chapterId: json['chapterId'] as String,
      title: json['title'] as String,
      content: (json['content'] ?? json['contentMarkdown']) as String,
      formulaLatex: json['formulaLatex'] as String? ?? '',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 10,
      simulation: simulationJson == null
          ? FormulaSimulationConfig.empty()
          : FormulaSimulationConfig.fromJson(simulationJson as Map),
      questions: (json['questions'] as List? ?? const [])
          .map((q) => Question.fromJson(q as Map))
          .toList(),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      isPublished: json['isPublished'] as bool? ?? true,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }
}

class FormulaVariable {
  const FormulaVariable({
    required this.symbol,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    this.step = 1,
    required this.defaultValue,
  });
  final String symbol;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double step;
  final double defaultValue;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'label': label,
    'unit': unit,
    'min': min,
    'max': max,
    'step': step,
    'default': defaultValue,
    'defaultValue': defaultValue,
  };

  factory FormulaVariable.fromJson(Map<dynamic, dynamic> json) =>
      FormulaVariable(
        symbol: json['symbol'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        step: (json['step'] as num?)?.toDouble() ?? 1,
        defaultValue: (json['defaultValue'] ?? json['default'] as num)
            .toDouble(),
      );
}

class FormulaResult {
  const FormulaResult({
    required this.symbol,
    required this.label,
    required this.unit,
    required this.expression,
    this.decimalPlaces = 2,
  });
  final String symbol;
  final String label;
  final String unit;
  final String expression;
  final int decimalPlaces;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'label': label,
    'unit': unit,
    'expression': expression,
    'decimalPlaces': decimalPlaces,
  };

  factory FormulaResult.fromJson(Map<dynamic, dynamic> json) => FormulaResult(
    symbol: json['symbol'] as String,
    label: json['label'] as String,
    unit: json['unit'] as String,
    expression: json['expression'] as String? ?? '',
    decimalPlaces: (json['decimalPlaces'] as num?)?.toInt() ?? 2,
  );
}

class FormulaSimulationConfig {
  const FormulaSimulationConfig({
    required this.title,
    required this.formula,
    required this.variables,
    required this.result,
  });
  final String title;
  final String formula;
  final List<FormulaVariable> variables;
  final FormulaResult result;

  static FormulaSimulationConfig empty() => const FormulaSimulationConfig(
    title: '',
    formula: '',
    variables: [],
    result: FormulaResult(symbol: '', label: '', unit: '', expression: ''),
  );

  Map<String, dynamic> toJson() => {
    'type': 'formula_simulation',
    'title': title,
    'formula': formula,
    'variables': variables.map((v) => v.toJson()).toList(),
    'result': result.toJson(),
  };

  factory FormulaSimulationConfig.fromJson(Map<dynamic, dynamic> json) {
    final config = json['config'] is Map
        ? Map<dynamic, dynamic>.from(json['config'] as Map)
        : const <dynamic, dynamic>{};
    final result = Map<dynamic, dynamic>.from(
      (json['result'] ?? config['result']) as Map? ?? {},
    );
    result['expression'] ??= json['expression'] as String? ?? '';
    return FormulaSimulationConfig(
      title: json['title'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      variables: ((json['variables'] ?? config['variables']) as List? ?? const [])
          .map((v) => FormulaVariable.fromJson(v as Map))
          .toList(),
      result: FormulaResult.fromJson(result),
    );
  }
}

class Question {
  const Question({
    required this.id,
    this.lessonId = '',
    required this.question,
    required this.options,
    this.correctOption,
    required this.explanation,
    this.difficulty = 'MEDIUM',
    this.lessonTitle = '',
    this.chapterId = '',
    this.chapterTitle = '',
    this.createdAt,
    this.orderIndex = 0,
  });
  final String id;
  final String lessonId;
  final String question;
  final List<String> options;
  final int? correctOption;
  final String explanation;
  final String difficulty;
  final String lessonTitle;
  final String chapterId;
  final String chapterTitle;
  final DateTime? createdAt;
  final int orderIndex;

  Map<String, dynamic> toJson() => {
    'id': id,
    if (lessonId.isNotEmpty) 'lessonId': lessonId,
    'question': question,
    'options': options,
    if (correctOption != null) 'correctOption': correctOption,
    'explanation': explanation,
    'difficulty': difficulty,
    if (lessonTitle.isNotEmpty) 'lessonTitle': lessonTitle,
    if (chapterId.isNotEmpty) 'chapterId': chapterId,
    if (chapterTitle.isNotEmpty) 'chapterTitle': chapterTitle,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'orderIndex': orderIndex,
  };

  factory Question.fromJson(Map<dynamic, dynamic> json) => Question(
    id: json['id'] as String,
    lessonId: (json['lessonId'] ?? json['lesson_id']) as String? ?? '',
    question: _jsonString(json, 'question').isNotEmpty
        ? _jsonString(json, 'question')
        : _jsonString(json, 'questionText', 'question_text'),
    options: _jsonStringList(json, 'options', 'options_json'),
    correctOption: (json['correctOption'] ?? json['correct_option'] as num?)
        ?.toInt(),
    explanation: json['explanation'] as String? ?? '',
    difficulty: json['difficulty'] as String? ?? 'MEDIUM',
    lessonTitle: json['lessonTitle'] as String? ?? '',
    chapterId:
        json['chapterId'] as String? ?? json['chapter_id'] as String? ?? '',
    chapterTitle: json['chapterTitle'] as String? ?? '',
    createdAt: _jsonDate(json, 'createdAt', 'created_at'),
    orderIndex: _jsonInt(json, 'orderIndex', 'order_index'),
  );
}

class AdminQuestionPage {
  const AdminQuestionPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<Question> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AdminQuestionPage.fromJson(Map<dynamic, dynamic> json) =>
      AdminQuestionPage(
        items: (json['items'] as List? ?? const [])
            .map((item) => Question.fromJson(item as Map))
            .toList(),
        page: _jsonInt(json, 'page'),
        limit: _jsonInt(json, 'limit'),
        total: _jsonInt(json, 'total'),
        totalPages: _jsonInt(json, 'totalPages'),
      );
}

class QuizReviewItem {
  const QuizReviewItem({
    required this.questionId,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.selectedOption,
    required this.isCorrect,
    required this.explanation,
  });

  final String questionId;
  final String question;
  final List<String> options;
  final int correctOption;
  final int? selectedOption;
  final bool isCorrect;
  final String explanation;

  factory QuizReviewItem.fromJson(Map<dynamic, dynamic> json) => QuizReviewItem(
    questionId: json['questionId'] as String,
    question: json['question'] as String? ?? '',
    options: List<String>.from(json['options'] as List? ?? const []),
    correctOption: _jsonInt(json, 'correctOption', 'correct_option'),
    selectedOption: (json['selectedOption'] ?? json['selected_option'] as num?)
        ?.toInt(),
    isCorrect:
        json['isCorrect'] as bool? ?? json['is_correct'] as bool? ?? false,
    explanation: json['explanation'] as String? ?? '',
  );
}

class QuizAttempt {
  const QuizAttempt({
    this.attemptId = '',
    required this.lessonId,
    required this.answers,
    required this.score,
    required this.earnedCoins,
    required this.newBadges,
    this.correctCount = 0,
    this.totalQuestions = 0,
    this.durationSeconds = 0,
    this.totalCoins = 0,
    this.review = const [],
  });
  final String attemptId;
  final String lessonId;
  final Map<String, int> answers;
  final double score;
  final int earnedCoins;
  final List<XBadge> newBadges;
  final int correctCount;
  final int totalQuestions;
  final int durationSeconds;
  final int totalCoins;
  final List<QuizReviewItem> review;

  int get coins => earnedCoins;

  factory QuizAttempt.fromSubmitJson(
    Map<dynamic, dynamic> json,
    Map<String, int> answers,
  ) => QuizAttempt(
    attemptId:
        json['attemptId'] as String? ??
        json['attempt_id'] as String? ??
        json['id'] as String? ??
        '',
    lessonId: json['lessonId'] as String,
    answers: answers,
    score: _jsonDouble(json, 'score'),
    earnedCoins: _jsonInt(json, 'earnedCoins', 'coins_earned') != 0
        ? _jsonInt(json, 'earnedCoins', 'coins_earned')
        : _jsonInt(json, 'coinsEarned'),
    totalCoins: _jsonInt(json, 'totalCoins', 'total_coins'),
    newBadges: (json['newBadges'] as List? ?? const [])
        .map(
          (badge) => badge is String
              ? XBadge(
                  id: badge,
                  name: badge,
                  description: '',
                  iconUrl: '',
                  ruleKey: '',
                )
              : XBadge.fromJson(badge as Map),
        )
        .toList(),
    correctCount: _jsonInt(json, 'correctCount', 'correct_count'),
    totalQuestions: _jsonInt(json, 'totalQuestions', 'total_questions'),
    durationSeconds: _jsonInt(json, 'durationSeconds', 'duration_seconds'),
    review: (json['review'] as List? ?? const [])
        .map((item) => QuizReviewItem.fromJson(item as Map))
        .toList(),
  );
}

class ProgressDashboard {
  const ProgressDashboard({
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
  final List<ChapterProgressSummary> chapterProgress;
  final List<RecentQuizAttempt> recentAttempts;

  bool get isEmpty => completedLessons == 0 && recentAttempts.isEmpty;

  factory ProgressDashboard.fromJson(Map<dynamic, dynamic> json) =>
      ProgressDashboard(
        overallProgress: _jsonDouble(json, 'overallProgress'),
        completedLessons: _jsonInt(json, 'completedLessons'),
        totalLessons: _jsonInt(json, 'totalLessons'),
        averageScore: _jsonDouble(json, 'averageScore'),
        totalCoins: _jsonInt(json, 'totalCoins'),
        chapterProgress: (json['chapterProgress'] as List? ?? const [])
            .map((item) => ChapterProgressSummary.fromJson(item as Map))
            .toList(),
        recentAttempts: (json['recentAttempts'] as List? ?? const [])
            .map((item) => RecentQuizAttempt.fromJson(item as Map))
            .toList(),
      );
}

class ChapterProgressSummary {
  const ChapterProgressSummary({
    required this.chapterId,
    required this.title,
    required this.completedLessons,
    required this.totalLessons,
    required this.progressPercent,
  });

  final String chapterId;
  final String title;
  final int completedLessons;
  final int totalLessons;
  final double progressPercent;

  factory ChapterProgressSummary.fromJson(Map<dynamic, dynamic> json) {
    final percent = json['progressPercent'] != null
        ? _jsonDouble(json, 'progressPercent')
        : _jsonDouble(json, 'progress') * 100;
    return ChapterProgressSummary(
      chapterId: _jsonString(json, 'chapterId', 'chapter_id'),
      title: _jsonString(json, 'title'),
      completedLessons: _jsonInt(json, 'completedLessons'),
      totalLessons: _jsonInt(json, 'totalLessons'),
      progressPercent: percent,
    );
  }
}

class RecentQuizAttempt {
  const RecentQuizAttempt({
    required this.attemptId,
    required this.lessonId,
    required this.lessonTitle,
    required this.score,
    required this.submittedAt,
    required this.durationSeconds,
  });

  final String attemptId;
  final String lessonId;
  final String lessonTitle;
  final double score;
  final DateTime submittedAt;
  final int durationSeconds;

  factory RecentQuizAttempt.fromJson(Map<dynamic, dynamic> json) {
    final attemptId = _jsonString(json, 'attemptId', 'attempt_id');
    return RecentQuizAttempt(
      attemptId: attemptId.isNotEmpty ? attemptId : _jsonString(json, 'id'),
      lessonId: _jsonString(json, 'lessonId', 'lesson_id'),
      lessonTitle: _jsonString(json, 'lessonTitle', 'lesson_title'),
      score: _jsonDouble(json, 'score'),
      submittedAt:
          DateTime.tryParse(_jsonString(json, 'submittedAt', 'submitted_at')) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: _jsonInt(json, 'durationSeconds', 'duration_seconds'),
    );
  }
}

class ProfileSummary {
  const ProfileSummary({
    required this.user,
    required this.totalCoins,
    required this.completedLessons,
    required this.averageScore,
    required this.recentAttempts,
    required this.earnedBadges,
    required this.lockedBadges,
  });

  final ProfileUser user;
  final int totalCoins;
  final int completedLessons;
  final double averageScore;
  final List<RecentQuizAttempt> recentAttempts;
  final List<AchievementBadge> earnedBadges;
  final List<AchievementBadge> lockedBadges;

  bool get hasNoAchievements =>
      earnedBadges.isEmpty && lockedBadges.isEmpty && recentAttempts.isEmpty;

  factory ProfileSummary.fromJson(Map<dynamic, dynamic> json) => ProfileSummary(
    user: ProfileUser.fromJson(json['user'] as Map? ?? const {}),
    totalCoins: _jsonInt(json, 'totalCoins'),
    completedLessons: _jsonInt(json, 'completedLessons'),
    averageScore: _jsonDouble(json, 'averageScore'),
    recentAttempts: (json['recentAttempts'] as List? ?? const [])
        .map((item) => RecentQuizAttempt.fromJson(item as Map))
        .toList(),
    earnedBadges: (json['earnedBadges'] as List? ?? const [])
        .map((item) => AchievementBadge.fromJson(item as Map, earned: true))
        .toList(),
    lockedBadges: (json['lockedBadges'] as List? ?? const [])
        .map((item) => AchievementBadge.fromJson(item as Map, earned: false))
        .toList(),
  );
}

class ProfileUser {
  const ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  factory ProfileUser.fromJson(Map<dynamic, dynamic> json) => ProfileUser(
    id: _jsonString(json, 'id'),
    name: _jsonString(json, 'name'),
    email: _jsonString(json, 'email'),
    avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
  );
}

class AchievementBadge {
  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.ruleKey,
    required this.isEarned,
    this.achievedAt,
    this.progressCurrent = 0,
    this.progressTarget = 0,
  });

  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String ruleKey;
  final bool isEarned;
  final DateTime? achievedAt;
  final int progressCurrent;
  final int progressTarget;

  double get progressValue {
    if (progressTarget <= 0) return 0;
    return (progressCurrent / progressTarget).clamp(0.0, 1.0);
  }

  factory AchievementBadge.fromJson(
    Map<dynamic, dynamic> json, {
    required bool earned,
  }) => AchievementBadge(
    id: _jsonString(json, 'id'),
    name: _jsonString(json, 'name'),
    description: _jsonString(json, 'description'),
    iconUrl: _jsonString(json, 'iconUrl', 'icon_url').isNotEmpty
        ? _jsonString(json, 'iconUrl', 'icon_url')
        : _jsonString(json, 'icon'),
    ruleKey: _jsonString(json, 'ruleKey', 'rule_key'),
    isEarned: earned,
    achievedAt: DateTime.tryParse(
      _jsonString(json, 'achievedAt', 'achieved_at'),
    ),
    progressCurrent: _jsonInt(json, 'progressCurrent'),
    progressTarget: _jsonInt(json, 'progressTarget'),
  );
}
