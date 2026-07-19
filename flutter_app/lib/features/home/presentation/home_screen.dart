import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          leading: Icon(Icons.book_outlined),
          title: Text('Chương 1'),
          subtitle: Text('Chuyển động cơ học'),
        ),
        ListTile(
          leading: Icon(Icons.calculate_outlined),
          title: Text('Chương 2'),
          subtitle: Text('Lực và áp suất'),
        ),
      ],
    );
  }
}
