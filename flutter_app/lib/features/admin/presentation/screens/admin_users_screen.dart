import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api_client.dart';
import '../../providers/admin_provider.dart';
import '../../../../shared/widgets/status_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quan ly nguoi dung'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tim theo email hoac ten',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _search(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.lastUsers.isEmpty) {
            return const LoadingWidget();
          }
          if (provider.error != null) {
            return ErrorView(message: provider.error!, onRetry: () => provider.fetchUsers());
          }

          final users = provider.lastUsers;

          if (users.isEmpty) {
            return const EmptyView(message: 'Chua co nguoi dung');
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchUsers(),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(user['name'] ?? ''),
                          subtitle: Text(user['email'] ?? ''),
                          trailing: Text(user['role'] ?? ''),
                        ),
                      );
                    },
                  ),
                ),
                _PaginationControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _search(BuildContext context) async {
    final provider = context.read<AdminProvider>();
    await provider.fetchUsers(search: _searchController.text.trim());
  }
}

class _PaginationControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AppButton(
            label: 'Truoc',
            onPressed: provider.usersPage <= 1 ? null : () => provider.setUsersPage(provider.usersPage - 1),
          ),
          const SizedBox(width: 12),
          Text('Trang ${provider.usersPage}/${provider.usersTotalPages}'),
          const Spacer(),
          Text('${provider.usersTotal ?? 0} nguoi dung'),
          const SizedBox(width: 12),
          AppButton(
            label: 'Sau',
            onPressed: provider.usersPage >= provider.usersTotalPages ? null : () => provider.setUsersPage(provider.usersPage + 1),
          ),
        ],
      ),
    );
  }
}
