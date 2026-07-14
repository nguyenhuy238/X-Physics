import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_scaffold.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <_AdminItem>[
      _AdminItem(icon: Icons.bar_chart, label: 'Thong ke'),
      _AdminItem(icon: Icons.people, label: 'Nguoi dung'),
      _AdminItem(icon: Icons.menu_book, label: 'Chuong'),
      _AdminItem(icon: Icons.quiz, label: 'Bai hoc'),
      _AdminItem(icon: Icons.help_outline, label: 'Cau hoi'),
    ];

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

class _AdminItem {
  const _AdminItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}
