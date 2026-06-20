import 'package:flutter/material.dart';

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.badges});

  final Iterable<String> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const Text('Chua co huy hieu.');
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final badge in badges)
          Chip(
            avatar: const Icon(Icons.workspace_premium_rounded),
            label: Text(badge),
          ),
      ],
    );
  }
}
