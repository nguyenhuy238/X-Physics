import 'package:flutter/material.dart';

class ChapterProgressCard extends StatelessWidget {
  const ChapterProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.onTap,
  });

  final String title;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
    );
  }
}
