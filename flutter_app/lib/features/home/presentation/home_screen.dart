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
          title: Text('Chuong 1'),
          subtitle: Text('Chuyen dong co hoc'),
        ),
        ListTile(
          leading: Icon(Icons.calculate_outlined),
          title: Text('Chuong 2'),
          subtitle: Text('Luc va ap suat'),
        ),
      ],
    );
  }
}
