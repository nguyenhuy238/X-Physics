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

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    this.icon = 'auto_stories',
    this.color = 0xFF2563EB,
    this.lessonCount = 0,
    this.orderIndex = 0,
  });
  final String id;
  final String title;
  final String description;
  final String icon;
  final int color;
  final int lessonCount;
  final int orderIndex;

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
  });
  final String id;
  final String chapterId;
  final String title;
  final String content;
  final String formulaLatex;
  final int estimatedMinutes;
  final FormulaSimulationConfig simulation;
  final List<Question> questions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapterId': chapterId,
    'title': title,
    'content': content,
    'formulaLatex': formulaLatex,
    'estimatedMinutes': estimatedMinutes,
    'simulation': simulation.toJson(),
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory Lesson.fromJson(Map<dynamic, dynamic> json) => Lesson(
    id: json['id'] as String,
    chapterId: json['chapterId'] as String,
    title: json['title'] as String,
    content: (json['content'] ?? json['contentMarkdown']) as String,
    formulaLatex: json['formulaLatex'] as String? ?? '',
    estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 10,
    simulation: json['simulation'] == null
        ? FormulaSimulationConfig.empty()
        : FormulaSimulationConfig.fromJson(json['simulation'] as Map),
    questions: (json['questions'] as List? ?? const [])
        .map((q) => Question.fromJson(q as Map))
        .toList(),
  );
}

class FormulaVariable {
  const FormulaVariable({
    required this.symbol,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.defaultValue,
  });
  final String symbol;
  final String label;
  final String unit;
  final double min;
  final double max;
  final double defaultValue;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'label': label,
    'unit': unit,
    'min': min,
    'max': max,
    'defaultValue': defaultValue,
  };

  factory FormulaVariable.fromJson(Map<dynamic, dynamic> json) =>
      FormulaVariable(
        symbol: json['symbol'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
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
  });
  final String symbol;
  final String label;
  final String unit;
  final String expression;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'label': label,
    'unit': unit,
    'expression': expression,
  };

  factory FormulaResult.fromJson(Map<dynamic, dynamic> json) => FormulaResult(
    symbol: json['symbol'] as String,
    label: json['label'] as String,
    unit: json['unit'] as String,
    expression: json['expression'] as String? ?? '',
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
    final result = Map<dynamic, dynamic>.from(json['result'] as Map? ?? {});
    result['expression'] ??= json['expression'] as String? ?? '';
    return FormulaSimulationConfig(
        title: json['title'] as String,
        formula: json['formula'] as String,
        variables: (json['variables'] as List? ?? const [])
            .map((v) => FormulaVariable.fromJson(v as Map))
            .toList(),
        result: FormulaResult.fromJson(result),
      );
  }
}

class Question {
  const Question({
    required this.id,
    required this.question,
    required this.options,
    this.correctOption,
    required this.explanation,
  });
  final String id;
  final String question;
  final List<String> options;
  final int? correctOption;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    if (correctOption != null) 'correctOption': correctOption,
    'explanation': explanation,
  };

  factory Question.fromJson(Map<dynamic, dynamic> json) => Question(
    id: json['id'] as String,
    question: json['question'] as String,
    options: List<String>.from(json['options'] as List),
    correctOption: (json['correctOption'] as num?)?.toInt(),
    explanation: json['explanation'] as String? ?? '',
  );
}

class QuizReviewItem {
  const QuizReviewItem({
    required this.questionId,
    required this.correctOption,
    required this.selectedOption,
    required this.explanation,
  });

  final String questionId;
  final int correctOption;
  final int? selectedOption;
  final String explanation;

  factory QuizReviewItem.fromJson(Map<dynamic, dynamic> json) => QuizReviewItem(
    questionId: json['questionId'] as String,
    correctOption: (json['correctOption'] as num).toInt(),
    selectedOption: (json['selectedOption'] as num?)?.toInt(),
    explanation: json['explanation'] as String? ?? '',
  );
}

class QuizAttempt {
  const QuizAttempt({
    required this.lessonId,
    required this.answers,
    required this.score,
    required this.coins,
    required this.newBadges,
    this.correctCount = 0,
    this.totalQuestions = 0,
    this.review = const [],
  });
  final String lessonId;
  final Map<String, int> answers;
  final double score;
  final int coins;
  final List<String> newBadges;
  final int correctCount;
  final int totalQuestions;
  final List<QuizReviewItem> review;

  factory QuizAttempt.fromSubmitJson(
    Map<dynamic, dynamic> json,
    Map<String, int> answers,
  ) => QuizAttempt(
    lessonId: json['lessonId'] as String,
    answers: answers,
    score: (json['score'] as num).toDouble(),
    coins: (json['coinsEarned'] as num?)?.toInt() ?? 0,
    newBadges: List<String>.from(json['newBadges'] as List? ?? const []),
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
    review: (json['review'] as List? ?? const [])
        .map((item) => QuizReviewItem.fromJson(item as Map))
        .toList(),
  );
}
