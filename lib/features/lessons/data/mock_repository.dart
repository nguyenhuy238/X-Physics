import '../../../shared/models/x_models.dart';

class MockRepository {
  final users = const [
    XUser(name: 'Nguyễn Văn Nam', email: 'nam@example.com', role: 'STUDENT'),
    XUser(name: 'Admin User', email: 'admin@example.com', role: 'ADMIN'),
  ];

  List<Chapter> get chapters => const [
    Chapter(
      id: 'motion',
      title: 'Chuyển động cơ học',
      description: 'Vận tốc, quãng đường và thời gian trong đời sống.',
      icon: 'rocket_launch',
      color: 0xFF2563EB,
    ),
    Chapter(
      id: 'force',
      title: 'Lực và áp suất',
      description: 'Lực tác dụng, áp lực, áp suất và lực đẩy Ác-si-mét.',
      icon: 'science',
      color: 0xFF7C3AED,
    ),
    Chapter(
      id: 'electric',
      title: 'Điện học',
      description: 'Dòng điện, hiệu điện thế, điện trở và công suất.',
      icon: 'bolt',
      color: 0xFFF59E0B,
    ),
  ];

  late final List<Lesson> lessons = [
    _lesson(
      'motion-1',
      'motion',
      'Chuyển động đều',
      r's = v \times t',
      'v * t',
      's',
      'Quãng đường',
      'm',
      [('v', 'Vận tốc', 'm/s', 1, 30, 5), ('t', 'Thời gian', 's', 1, 120, 10)],
    ),
    _lesson(
      'motion-2',
      'motion',
      'Vận tốc trung bình',
      r'v = \frac{s}{t}',
      's / t',
      'v',
      'Vận tốc',
      'm/s',
      [
        ('s', 'Quãng đường', 'm', 10, 1000, 100),
        ('t', 'Thời gian', 's', 1, 300, 20),
      ],
    ),
    _lesson(
      'force-1',
      'force',
      'Áp suất',
      r'p = \frac{F}{S}',
      'F / S',
      'p',
      'Áp suất',
      'Pa',
      [
        ('F', 'Áp lực', 'N', 1, 1000, 100),
        ('S', 'Diện tích bị ép', 'm²', 0.1, 20, 2),
      ],
    ),
    _lesson(
      'force-2',
      'force',
      'Lực đẩy Ác-si-mét',
      r'F_A = d \times V',
      'd * V',
      'FA',
      'Lực đẩy',
      'N',
      [
        ('d', 'Trọng lượng riêng', 'N/m³', 1000, 12000, 10000),
        ('V', 'Thể tích', 'm³', 0.01, 2, 0.05),
      ],
    ),
    _lesson(
      'electric-1',
      'electric',
      'Định luật Ohm',
      r'I = \frac{U}{R}',
      'U / R',
      'I',
      'Cường độ dòng điện',
      'A',
      [
        ('U', 'Hiệu điện thế', 'V', 0, 220, 12),
        ('R', 'Điện trở', 'Ω', 1, 100, 4),
      ],
    ),
    _lesson(
      'electric-2',
      'electric',
      'Công suất điện',
      r'P = U \times I',
      'U * I',
      'P',
      'Công suất',
      'W',
      [
        ('U', 'Hiệu điện thế', 'V', 1, 220, 12),
        ('I', 'Cường độ dòng điện', 'A', 0.1, 20, 2),
      ],
    ),
  ];

  Lesson lessonById(String id) =>
      lessons.firstWhere((lesson) => lesson.id == id);
  Chapter chapterById(String id) =>
      chapters.firstWhere((chapter) => chapter.id == id);
  List<Lesson> lessonsByChapter(String chapterId) =>
      lessons.where((l) => l.chapterId == chapterId).toList();

  Lesson _lesson(
    String id,
    String chapterId,
    String title,
    String latex,
    String expression,
    String resultSymbol,
    String resultLabel,
    String resultUnit,
    List<(String, String, String, double, double, double)> variables,
  ) {
    final formulaText = latex
        .replaceAll(r'\frac', '')
        .replaceAll('{', '')
        .replaceAll('}', '');
    return Lesson(
      id: id,
      chapterId: chapterId,
      title: title,
      formulaLatex: latex,
      estimatedMinutes: 10 + id.hashCode.abs() % 7,
      content:
          '''
# $title

Trong bài này, em sẽ quan sát đại lượng Vật Lí qua công thức **$formulaText** và luyện cách thay số.

## Ghi nhớ

- Xác định đúng đại lượng đã biết và đại lượng cần tìm.
- Đổi đơn vị trước khi tính toán.
- Viết kết quả kèm đơn vị.

## Ví dụ

Một tình huống thực tế được mô phỏng ở phần phòng thí nghiệm bên dưới. Hãy kéo các thanh trượt để xem kết quả thay đổi như thế nào.
''',
      simulation: FormulaSimulationConfig(
        title: 'Mô phỏng $title',
        formula: latex,
        variables: variables
            .map(
              (v) => FormulaVariable(
                symbol: v.$1,
                label: v.$2,
                unit: v.$3,
                min: v.$4,
                max: v.$5,
                defaultValue: v.$6,
              ),
            )
            .toList(),
        result: FormulaResult(
          symbol: resultSymbol,
          label: resultLabel,
          unit: resultUnit,
          expression: expression,
        ),
      ),
      questions: List.generate(
        5,
        (index) => _question(id, title, expression, index),
      ),
    );
  }

  Question _question(
    String lessonId,
    String title,
    String expression,
    int index,
  ) {
    final base = [
      'Công thức chính của bài "$title" là gì?',
      'Khi kéo thanh trượt trong mô phỏng, đại lượng nào thay đổi?',
      'Vì sao cần ghi đơn vị ở kết quả?',
      'Bước đầu tiên khi giải bài tập định lượng là gì?',
      'Biểu thức "$expression" nên được tính như thế nào?',
    ];
    return Question(
      id: '$lessonId-q$index',
      question: base[index],
      options: [
        index == 0 ? expression : 'Bỏ qua đơn vị',
        index == 1 ? 'Kết quả cập nhật theo biến đầu vào' : 'Chỉ nhìn đáp án',
        index == 2 ? 'Để kết quả có ý nghĩa Vật Lí' : 'Không cần đọc đề',
        index == 3 ? 'Xác định dữ kiện và đổi đơn vị' : 'Chọn ngẫu nhiên',
      ],
      correctOption: index.clamp(0, 3).toInt(),
      explanation:
          'Áp dụng đúng công thức $expression, kiểm tra đơn vị và thay số cẩn thận.',
    );
  }
}
