import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../progress/application/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.profileSummary == null && !state.isProfileLoading) {
        state.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profileSummary;
    final error = state.profileError;

    return XScaffold(
      title: 'Hồ sơ',
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: state.isProfileLoading ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (state.isProfileLoading && profile == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null && profile == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: ErrorView(
                      message: error,
                      onRetry: context.read<AppState>().refreshProfile,
                    ),
                  ),
                ],
              );
            }
            if (profile == null) {
              return const _ProfileEmptyState();
            }
            return _ProfileContent(profile: profile);
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final state = context.read<AppState>();
    final hadData = state.profileSummary != null;
    await state.refreshProfile();
    if (!mounted || !hadData || state.profileError == null) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.profileError!)));
  }
}

class _ProfileEmptyState extends StatelessWidget {
  const _ProfileEmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: const EmptyView(message: 'Chưa có dữ liệu hồ sơ.'),
        ),
      ],
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAdmin = appState.canAccessAdmin;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _ProfileHeader(profile: profile),
        if (isAdmin) ...[
          const SizedBox(height: 16),
          _buildAdminSection(context, appState),
        ],
        if (!isAdmin) ...[
          const SizedBox(height: 16),
          _StatsRow(profile: profile),
          const SizedBox(height: 16),
          _RecentScoreChart(attempts: profile.recentAttempts),
          const SizedBox(height: 16),
          _BadgeGrid(badges: [...profile.earnedBadges, ...profile.lockedBadges]),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _showEditProfileDialog(context, profile.user.name),
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Cập nhật họ tên'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showChangePasswordDialog(context),
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Đổi mật khẩu'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.read<AppState>().logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Đăng xuất'),
        ),
      ],
    );
  }

  Widget _buildAdminSection(BuildContext context, AppState state) {
    final roleLabel = state.user?.role == 'TEACHER' ? 'Giáo viên' : 'Quản trị viên';
    final roleColor = state.user?.role == 'TEACHER' ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: roleColor),
                const SizedBox(width: 8),
                Text(
                  'Quản trị hệ thống ($roleLabel)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF2563EB)),
              title: const Text('Bảng điều khiển Admin'),
              subtitle: const Text('Tổng quan CMS & Quản lý danh sách'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.folder_special_rounded, color: Color(0xFFEC4899)),
              title: const Text('Quản lý Chương học'),
              subtitle: const Text('Thêm, sửa, xóa các chương học'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin/chapters'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF16A34A)),
              title: const Text('Quản lý Bài học'),
              subtitle: const Text('Chỉnh sửa lý thuyết & mô phỏng'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin/lessons'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.quiz_rounded, color: Color(0xFFEC4899)),
              title: const Text('Quản lý Câu hỏi'),
              subtitle: const Text('Ngân hàng câu hỏi trắc nghiệm'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin/questions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final initial = user.name.isNotEmpty ? user.name.characters.first : '?';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? null
              : NetworkImage(user.avatarUrl!),
          child: user.avatarUrl == null || user.avatarUrl!.isEmpty
              ? Text(
                  initial,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                )
              : null,
        ),
        title: Text(
          user.name.isEmpty ? 'Học sinh' : user.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(user.email),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final ProfileSummary profile;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(label: 'Xu', value: '${profile.totalCoins}'),
        _StatCard(label: 'Bài đã xong', value: '${profile.completedLessons}'),
        _StatCard(
          label: 'Điểm TB',
          value: profile.averageScore.toStringAsFixed(2),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScoreChart extends StatelessWidget {
  const _RecentScoreChart({required this.attempts});

  final List<RecentQuizAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final chronological = attempts.reversed.toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điểm gần đây',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: chronological.isEmpty
                  ? const Center(child: Text('Chưa có điểm quiz nào.'))
                  : LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 10,
                        gridData: const FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (var i = 0; i < chronological.length; i++)
                                FlSpot(i.toDouble(), chronological[i].score),
                            ],
                            isCurved: chronological.length > 2,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 2,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 ||
                                    index >= chronological.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: SizedBox(
                                    width: 48,
                                    child: Text(
                                      chronological[index].lessonTitle.isEmpty
                                          ? 'Quiz ${index + 1}'
                                          : chronological[index].lessonTitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.badges});

  final List<AchievementBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const EmptyView(message: 'Chưa có huy hiệu nào.');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: badges.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 3 ? 1.15 : 1.05,
          ),
          itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final AchievementBadge badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = badge.isEarned
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    return Card(
      color: badge.isEarned
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showBadgeDetail(context, badge),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge.isEarned
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_rounded,
                color: foreground,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (!badge.isEarned && badge.progressTarget > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: badge.progressValue),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showBadgeDetail(BuildContext context, AchievementBadge badge) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                badge.isEarned
                    ? Icons.workspace_premium_rounded
                    : Icons.lock_rounded,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  badge.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(badge.description),
          const SizedBox(height: 12),
          if (badge.isEarned)
            Text(
              badge.achievedAt == null
                  ? 'Đã đạt'
                  : 'Đã đạt: ${_formatDate(badge.achievedAt!)}',
            )
          else ...[
            Text('Tiến độ: ${badge.progressCurrent}/${badge.progressTarget}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: badge.progressValue),
          ],
        ],
      ),
    ),
  );
}

Future<void> _showEditProfileDialog(
  BuildContext context,
  String currentName,
) async {
  final updated = await showDialog<bool>(
    context: context,
    builder: (_) => _EditProfileDialog(currentName: currentName),
  );
  if (!context.mounted || updated != true) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Đã cập nhật hồ sơ.')));
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final appState = context.read<AppState>();
    final ok = await appState.updateProfileName(_controller.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = appState.profileError ?? 'Cập nhật hồ sơ thất bại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cập nhật hồ sơ'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              enabled: !_isSubmitting,
              maxLength: 120,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Bắt buộc' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

Future<void> _showChangePasswordDialog(BuildContext context) async {
  final appState = context.read<AppState>();
  final dialogDisposed = Completer<void>();
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => _ChangePasswordDialog(
      onDisposed: () {
        if (!dialogDisposed.isCompleted) {
          dialogDisposed.complete();
        }
      },
    ),
  );
  if (changed != true) {
    return;
  }
  await dialogDisposed.future;
  await appState.signOutAfterPasswordChange();
}

String? _passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Bắt buộc';
  }
  if (value.length < 6) {
    return 'Tối thiểu 6 ký tự';
  }
  return null;
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onDisposed});

  final VoidCallback onDisposed;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmNewPassword = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmNewPassword.dispose();
    widget.onDisposed();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final appState = context.read<AppState>();
    final ok = await appState.changePassword(
      currentPassword: _currentPassword.text,
      newPassword: _newPassword.text,
      confirmNewPassword: _confirmNewPassword.text,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage = appState.profileError ?? 'Đổi mật khẩu thất bại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _currentPassword,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: _passwordValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPassword,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: _passwordValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmNewPassword,
              enabled: !_isSubmitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
              ),
              validator: (value) {
                final passwordError = _passwordValidator(value);
                if (passwordError != null) return passwordError;
                return value == _newPassword.text
                    ? null
                    : 'Xác nhận mật khẩu không khớp';
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
