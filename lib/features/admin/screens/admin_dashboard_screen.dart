import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const XScaffold(
      title: 'Admin Dashboard',
      child: Center(child: Text('Admin statistics skeleton')),
    );
  }
}
