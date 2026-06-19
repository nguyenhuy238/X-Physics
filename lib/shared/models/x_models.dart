class XUser {
  const XUser({required this.name, required this.email, required this.role});
  final String name;
  final String email;
  final String role;
}

class Chapter {
  const Chapter({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
  final String id;
  final String title;
  final String description;
  final String icon;
  final int color;
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
    content: json['content'] as String,
    formulaLatex: json['formulaLatex'] as String,
    estimatedMinutes: json['estimatedMinutes'] as int,
    simulation: FormulaSimulationConfig.fromJson(json['simulation'] as Map),
    questions: (json['questions'] as List)
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
    'default': defaultValue,
  };

  factory FormulaVariable.fromJson(Map<dynamic, dynamic> json) =>
      FormulaVariable(
        symbol: json['symbol'] as String,
        label: json['label'] as String,
        unit: json['unit'] as String,
        min: (json['min'] as num).toDouble(),
        max: (json['max'] as num).toDouble(),
        defaultValue: (json['default'] as num).toDouble(),
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
    expression: json['expression'] as String,
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

  Map<String, dynamic> toJson() => {
    'type': 'formula_simulation',
    'title': title,
    'formula': formula,
    'variables': variables.map((v) => v.toJson()).toList(),
    'result': result.toJson(),
  };

  factory FormulaSimulationConfig.fromJson(Map<dynamic, dynamic> json) =>
      FormulaSimulationConfig(
        title: json['title'] as String,
        formula: json['formula'] as String,
        variables: (json['variables'] as List)
            .map((v) => FormulaVariable.fromJson(v as Map))
            .toList(),
        result: FormulaResult.fromJson(json['result'] as Map),
      );
}

class Question {
  const Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOption,
    required this.explanation,
  });
  final String id;
  final String question;
  final List<String> options;
  final int correctOption;
  final String explanation;

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'correctOption': correctOption,
    'explanation': explanation,
  };

  factory Question.fromJson(Map<dynamic, dynamic> json) => Question(
    id: json['id'] as String,
    question: json['question'] as String,
    options: List<String>.from(json['options'] as List),
    correctOption: json['correctOption'] as int,
    explanation: json['explanation'] as String,
  );
}

class QuizAttempt {
  const QuizAttempt({
    required this.lessonId,
    required this.answers,
    required this.score,
    required this.coins,
    required this.newBadges,
  });
  final String lessonId;
  final Map<String, int> answers;
  final double score;
  final int coins;
  final List<String> newBadges;
}
