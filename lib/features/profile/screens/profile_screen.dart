import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_view.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/unsaved_changes_dialog.dart';
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
      showThemeModeAction: false,
      showOfflineSimulationAction: false,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _ProfileLayout.fromWidth(constraints.maxWidth);
        final badges = [...profile.earnedBadges, ...profile.lockedBadges];
        final bottomPadding =
            MediaQuery.viewPaddingOf(context).bottom +
            XScaffold.bottomNavigationHeight +
            24;
        return CustomScrollView(
          key: const PageStorageKey<String>('profile-scroll'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalInset,
                20,
                layout.horizontalInset,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _ProfileIntro(
                  profile: profile,
                  state: appState,
                  isAdmin: isAdmin,
                  layout: layout,
                ),
              ),
            ),
            if (!isAdmin) ...[
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.horizontalInset,
                  20,
                  layout.horizontalInset,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _AchievementsHeader(
                    earned: profile.earnedBadges.length,
                    total: badges.length,
                  ),
                ),
              ),
              if (badges.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    layout.horizontalInset,
                    0,
                    layout.horizontalInset,
                    0,
                  ),
                  sliver: const SliverToBoxAdapter(
                    child: Card(
                      child: SizedBox(
                        height: 160,
                        child: EmptyView(message: 'Chưa có huy hiệu nào.'),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    layout.horizontalInset,
                    0,
                    layout.horizontalInset,
                    0,
                  ),
                  sliver: _AchievementSliverGrid(
                    badges: badges,
                    columns: layout.badgeColumns,
                  ),
                ),
            ],
            SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
          ],
        );
      },
    );
  }
}

class _ProfileLayout {
  const _ProfileLayout({
    required this.contentWidth,
    required this.horizontalInset,
    required this.badgeColumns,
    required this.isCompact,
    required this.isDesktop,
  });

  final double contentWidth;
  final double horizontalInset;
  final int badgeColumns;
  final bool isCompact;
  final bool isDesktop;

  static _ProfileLayout fromWidth(double width) {
    final basePadding = width < 600 ? 16.0 : 24.0;
    final maxWidth = width > 1024 ? 1220.0 : (width >= 600 ? 920.0 : width);
    final contentWidth = (width - basePadding * 2).clamp(0.0, maxWidth);
    final horizontalInset = ((width - contentWidth) / 2).clamp(
      basePadding,
      double.infinity,
    );
    return _ProfileLayout(
      contentWidth: contentWidth,
      horizontalInset: horizontalInset,
      badgeColumns: width < 600 ? 2 : (contentWidth >= 1040 ? 4 : 3),
      isCompact: width < 700,
      isDesktop: width > 1024,
    );
  }
}

class _ProfileIntro extends StatelessWidget {
  const _ProfileIntro({
    required this.profile,
    required this.state,
    required this.isAdmin,
    required this.layout,
  });

  final ProfileSummary profile;
  final AppState state;
  final bool isAdmin;
  final _ProfileLayout layout;

  @override
  Widget build(BuildContext context) {
    final settings = _SettingsSection(profile: profile, state: state);
    final adminSection = isAdmin ? _AdminSection(state: state) : null;
    final chart = _RecentScoreChart(
      attempts: profile.recentAttempts,
      isLoading: state.isProfileLoading,
      error: state.profileError,
    );

    final side = Column(
      children: [
        settings,
        if (adminSection != null) ...[const SizedBox(height: 16), adminSection],
      ],
    );

    return Column(
      children: [
        if (state.isProfileLoading) ...[
          const LinearProgressIndicator(minHeight: 3),
          const SizedBox(height: 12),
        ],
        if (state.profileError != null && !state.isProfileLoading) ...[
          _InlineErrorBanner(message: state.profileError!),
          const SizedBox(height: 12),
        ],
        _ProfileHeader(
          profile: profile,
          state: state,
          compact: layout.isCompact,
        ),
        const SizedBox(height: 16),
        if (layout.isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAdmin)
                Expanded(flex: 7, child: chart)
              else
                Expanded(child: adminSection ?? const SizedBox.shrink()),
              const SizedBox(width: 16),
              SizedBox(width: 360, child: settings),
            ],
          )
        else ...[
          if (!isAdmin) ...[chart, const SizedBox(height: 16)],
          side,
        ],
      ],
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  const _InlineErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.state,
    required this.compact,
  });

  final ProfileSummary profile;
  final AppState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = profile.user;
    final initial = user.name.isNotEmpty ? user.name.characters.first : '?';
    final roleLabel = _roleLabel(state.user?.role);
    final stats = [
      _ProfileStatData(
        icon: Icons.monetization_on_rounded,
        label: 'Xu',
        value: '${profile.totalCoins}',
      ),
      _ProfileStatData(
        icon: Icons.task_alt_rounded,
        label: 'Bài đã hoàn thành',
        value: '${profile.completedLessons}',
      ),
      _ProfileStatData(
        icon: Icons.leaderboard_rounded,
        label: 'Điểm trung bình',
        value: profile.averageScore.toStringAsFixed(2),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileIdentity(
                    initial: initial,
                    user: user,
                    roleLabel: roleLabel,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _showEditProfileDialog(context, profile.user.name),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Chỉnh sửa hồ sơ'),
                  ),
                  const SizedBox(height: 16),
                  _StatsGrid(stats: stats, columns: 1),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: _ProfileIdentity(
                      initial: initial,
                      user: user,
                      roleLabel: roleLabel,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _StatsGrid(stats: stats, columns: 3),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _showEditProfileDialog(context, profile.user.name),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Chỉnh sửa'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.initial,
    required this.user,
    required this.roleLabel,
  });

  final String initial;
  final ProfileUser user;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 34,
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name.isEmpty ? 'Học sinh' : user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Vai trò $roleLabel',
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  label: Text(roleLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatData {
  const _ProfileStatData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.columns});

  final List<_ProfileStatData> stats;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = columns == 1 ? 8.0 : 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: width,
                child: _StatTile(stat: stat),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _ProfileStatData stat;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(stat.icon, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScoreChart extends StatelessWidget {
  const _RecentScoreChart({
    required this.attempts,
    required this.isLoading,
    required this.error,
  });

  final List<RecentQuizAttempt> attempts;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final recent = attempts.take(5).toList().reversed.toList();
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Điểm gần đây',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (error != null && attempts.isEmpty && !isLoading) ...[
              const SizedBox(height: 12),
              ErrorView(
                message: error!,
                onRetry: context.read<AppState>().refreshProfile,
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: recent.isEmpty
                    ? const EmptyView(
                        message: 'Chưa có điểm quiz nào.',
                        icon: Icons.query_stats_rounded,
                      )
                    : BarChart(
                        BarChartData(
                          minY: 0,
                          maxY: 10,
                          alignment: BarChartAlignment.spaceAround,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 2,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: colorScheme.outlineVariant,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              fitInsideHorizontally: true,
                              fitInsideVertically: true,
                              getTooltipColor: (_) =>
                                  colorScheme.inverseSurface,
                              getTooltipItem:
                                  (group, groupIndex, rod, rodIndex) {
                                    final attempt = recent[group.x.toInt()];
                                    final title = attempt.lessonTitle.isEmpty
                                        ? 'Quiz ${group.x + 1}'
                                        : attempt.lessonTitle;
                                    return BarTooltipItem(
                                      '$title\n${rod.toY.toStringAsFixed(1)}/10',
                                      TextStyle(
                                        color: colorScheme.onInverseSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    );
                                  },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                interval: 2,
                                getTitlesWidget: (value, meta) {
                                  if (value % 2 != 0) {
                                    return const SizedBox.shrink();
                                  }
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(
                                      value.toInt().toString(),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 46,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value != value.roundToDouble()) {
                                    return const SizedBox.shrink();
                                  }
                                  final index = value.toInt();
                                  if (index < 0 || index >= recent.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final title =
                                      recent[index].lessonTitle.isEmpty
                                      ? 'Quiz ${index + 1}'
                                      : recent[index].lessonTitle;
                                  return SideTitleWidget(
                                    meta: meta,
                                    space: 8,
                                    child: Tooltip(
                                      message: title,
                                      child: SizedBox(
                                        width: 58,
                                        child: Text(
                                          _shortQuizTitle(title),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (var index = 0; index < recent.length; index++)
                              BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: recent[index].score.clamp(0, 10),
                                    width: 20,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                    ),
                                    color: colorScheme.primary,
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: 10,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AchievementsHeader extends StatelessWidget {
  const _AchievementsHeader({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Thành tích',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Text(
          '$earned/$total đã đạt',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _AchievementSliverGrid extends StatelessWidget {
  const _AchievementSliverGrid({required this.badges, required this.columns});

  final List<AchievementBadge> badges;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _BadgeTile(badge: badges[index]),
        childCount: badges.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 168,
      ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    badge.isEarned
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                    color: foreground,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      badge.isEarned ? 'Đã đạt' : 'Đang khóa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  badge.isEarned
                      ? (badge.achievedAt == null
                            ? 'Thành tích đã mở khóa'
                            : 'Mở khóa ${_formatDate(badge.achievedAt!)}')
                      : (badge.description.isEmpty
                            ? 'Hoàn thành điều kiện để mở khóa'
                            : badge.description),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (!badge.isEarned && badge.progressTarget > 0) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: badge.progressValue),
                const SizedBox(height: 4),
                Text(
                  '${badge.progressCurrent}/${badge.progressTarget}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.profile, required this.state});

  final ProfileSummary profile;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: Text(
                'Cài đặt',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(_themeModeIcon(state.themeMode)),
              title: const Text('Giao diện'),
              subtitle: Text(_themeModeLabel(state.themeMode)),
              minLeadingWidth: 24,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('Hệ thống'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Sáng'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Tối'),
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (values) {
                    if (values.isNotEmpty) {
                      state.setThemeMode(values.first);
                    }
                  },
                ),
              ),
            ),
            const Divider(height: 1),
            if (kDebugMode) ...[
              SwitchListTile(
                secondary: const Icon(Icons.wifi_off_rounded),
                title: const Text('Giả lập ngoại tuyến'),
                subtitle: const Text('Chỉ sử dụng để kiểm tra và trình diễn'),
                value: state.simulateOffline,
                onChanged: state.setOfflineMode,
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.download_done_rounded),
              title: const Text('Bài học đã tải'),
              subtitle: Text(
                '${state.downloadedLessons.length} bài học sẵn sàng đọc offline',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/offline'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Cập nhật họ tên'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showEditProfileDialog(context, profile.user.name),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showChangePasswordDialog(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout_rounded, color: colorScheme.error),
              title: Text(
                'Đăng xuất',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final roleLabel = state.user?.role == 'TEACHER'
        ? 'Giáo viên'
        : 'Quản trị viên';
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.admin_panel_settings_rounded,
                color: colorScheme.primary,
              ),
              title: Text(
                'Quản trị hệ thống ($roleLabel)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Bảng điều khiển Admin'),
              subtitle: const Text('Tổng quan CMS & Quản lý danh sách'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.folder_special_rounded),
              title: const Text('Quản lý Chương học'),
              subtitle: const Text('Thêm, sửa, xóa các chương học'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin/chapters'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: const Text('Quản lý Bài học'),
              subtitle: const Text('Chỉnh sửa lý thuyết & mô phỏng'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/admin/lessons'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.quiz_rounded),
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

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed =
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục học.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
      ) ??
      false;
  if (confirmed && context.mounted) {
    await context.read<AppState>().logout();
  }
}

String _themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Theo cài đặt hệ thống',
  ThemeMode.light => 'Luôn dùng giao diện sáng',
  ThemeMode.dark => 'Luôn dùng giao diện tối',
};

IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_rounded,
  ThemeMode.light => Icons.light_mode_rounded,
  ThemeMode.dark => Icons.dark_mode_rounded,
};

String _roleLabel(String? role) => switch (role) {
  'ADMIN' => 'Quản trị viên',
  'TEACHER' => 'Giáo viên',
  _ => 'Học sinh',
};

String _shortQuizTitle(String title) {
  final normalized = title.trim();
  if (normalized.isEmpty) {
    return 'Quiz';
  }
  final words = normalized.split(RegExp(r'\s+'));
  if (words.length == 1) {
    return words.first.length <= 12
        ? words.first
        : '${words.first.substring(0, 11)}...';
  }
  final firstTwo = words.take(2).join(' ');
  return firstTwo.length <= 14 ? firstTwo : '${firstTwo.substring(0, 13)}...';
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
    _controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges =>
      _controller.text.trim() != widget.currentName.trim();

  void _handleTextChanged() {
    final appState = context.read<AppState>();
    if (appState.profileFieldErrors.isNotEmpty ||
        appState.profileError != null) {
      appState.clearProfileErrors();
    }
    setState(() {});
  }

  Future<void> _requestClose() async {
    if (_isSubmitting) {
      return;
    }
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showUnsavedChangesDialog(
      context: context,
      title: 'Hủy cập nhật hồ sơ?',
      message: 'Thông tin hồ sơ đã nhập chưa được lưu.',
      stayLabel: 'Tiếp tục chỉnh sửa',
      leaveLabel: 'Hủy thay đổi',
    );
    if (leave && mounted) {
      Navigator.of(context).pop();
    }
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
    return PopScope(
      canPop: !_isSubmitting && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _requestClose();
        }
      },
      child: AlertDialog(
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Không được để trống!'
                    : null,
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
            onPressed: _isSubmitting ? null : _requestClose,
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
      ),
    );
  }
}

Future<void> _showChangePasswordDialog(BuildContext context) async {
  final appState = context.read<AppState>();
  appState.clearProfileErrors();
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
  appState.clearProfileErrors();
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công.')));
  }
}

String? _passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Không được để trống!';
  }
  if (value.length < 6) {
    return 'Tối thiểu 6 ký tự';
  }
  if (value.length > 72) {
    return 'Mật khẩu không được vượt quá 72 ký tự.';
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
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _currentPassword.removeListener(_handleTextChanged);
    _newPassword.removeListener(_handleTextChanged);
    _confirmNewPassword.removeListener(_handleTextChanged);
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmNewPassword.dispose();
    widget.onDisposed();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentPassword.addListener(_handleTextChanged);
    _newPassword.addListener(_handleTextChanged);
    _confirmNewPassword.addListener(_handleTextChanged);
  }

  bool get _hasUnsavedChanges =>
      _currentPassword.text.isNotEmpty ||
      _newPassword.text.isNotEmpty ||
      _confirmNewPassword.text.isNotEmpty;

  void _handleTextChanged() {
    if (_fieldErrors.isNotEmpty) {
      _fieldErrors = const {};
    }
    final appState = context.read<AppState>();
    if (appState.profileFieldErrors.isNotEmpty ||
        appState.profileError != null) {
      appState.clearProfileErrors();
    }
    setState(() {});
  }

  Future<void> _requestClose() async {
    if (_isSubmitting) {
      return;
    }
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showUnsavedChangesDialog(
      context: context,
      title: 'Hủy đổi mật khẩu?',
      message: 'Mật khẩu đã nhập chưa được lưu.',
      stayLabel: 'Tiếp tục chỉnh sửa',
      leaveLabel: 'Hủy thay đổi',
    );
    if (leave && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _fieldErrors = const {};
    });
    final appState = context.read<AppState>();
    appState.clearProfileErrors();
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
      _fieldErrors = appState.profileFieldErrors;
      _errorMessage = appState.profileFieldErrors.isEmpty
          ? appState.profileError ?? 'Đổi mật khẩu thất bại.'
          : appState.profileFieldErrors['_form'];
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();
    final fieldErrors = _fieldErrors;
    return PopScope(
      canPop: !_isSubmitting && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await _requestClose();
        }
      },
      child: AlertDialog(
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
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  errorText: fieldErrors['currentPassword'],
                ),
                validator: _passwordValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPassword,
                enabled: !_isSubmitting,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  errorText: fieldErrors['newPassword'],
                ),
                validator: (value) {
                  final passwordError = _passwordValidator(value);
                  if (passwordError != null) return passwordError;
                  return value == _currentPassword.text
                      ? 'Mật khẩu mới phải khác mật khẩu hiện tại.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmNewPassword,
                enabled: !_isSubmitting,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  errorText: fieldErrors['confirmNewPassword'],
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
            onPressed: _isSubmitting ? null : _requestClose,
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
      ),
    );
  }
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
