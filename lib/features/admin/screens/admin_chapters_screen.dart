import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AdminChaptersScreen extends StatelessWidget {
  const AdminChaptersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const XScaffold(
      title: 'Admin Chapters',
      child: Center(child: Text('CRUD chapters skeleton')),
    );
  }
}
