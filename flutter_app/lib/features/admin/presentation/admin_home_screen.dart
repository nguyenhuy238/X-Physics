import 'package:flutter/material.dart';

import 'admin_users_screen.dart';
import 'admin_chapters_screen.dart';
import 'admin_lessons_screen.dart';
import 'admin_questions_screen.dart';
import 'admin_statistics_screen.dart';
import 'widgets/admin_drawer.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminDashboard();
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const AdminStatisticsScreen(),
      const AdminUsersScreen(),
      const AdminChaptersScreen(),
      const AdminLessonsScreen(),
      const AdminQuestionsScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AdminDrawer(
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
    );
  }
}
