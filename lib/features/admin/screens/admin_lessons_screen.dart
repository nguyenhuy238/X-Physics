import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AdminLessonsScreen extends StatelessWidget {
  const AdminLessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const XScaffold(
      title: 'Admin Lessons',
      child: Center(child: Text('CRUD lessons skeleton')),
    );
  }
}
