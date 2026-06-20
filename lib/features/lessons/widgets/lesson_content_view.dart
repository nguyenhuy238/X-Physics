import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class LessonContentView extends StatelessWidget {
  const LessonContentView({
    super.key,
    required this.markdown,
    required this.formulaLatex,
  });

  final String markdown;
  final String formulaLatex;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(data: markdown),
        const SizedBox(height: 16),
        Center(child: Math.tex(formulaLatex)),
      ],
    );
  }
}
