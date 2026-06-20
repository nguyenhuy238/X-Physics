import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AdminQuestionsScreen extends StatelessWidget {
  const AdminQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const XScaffold(
      title: 'Admin Questions',
      child: Center(child: Text('CRUD questions skeleton')),
    );
  }
}
