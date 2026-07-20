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
      badgeColumns: width < 420
          ? 3
          : width < 720
          ? 4
          : (contentWidth >= 1180 ? 6 : (contentWidth >= 900 ? 5 : 4)),
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
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
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
                  label: Text(
                    roleLabel,
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final progress = total == 0 ? 0.0 : (earned / total).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Huy hiệu của tôi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$earned/$total đã đạt',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _AchievementStatChip(
                  icon: Icons.verified_rounded,
                  label: '$earned Đã đạt',
                  color: colorScheme.primary,
                ),
                _AchievementStatChip(
                  icon: Icons.lock_rounded,
                  label: '${(total - earned).clamp(0, total)} Đang khóa',
                  color: colorScheme.onSurfaceVariant,
                ),
                _AchievementStatChip(
                  icon: Icons.pie_chart_rounded,
                  label: '${(progress * 100).round()}% Hoàn thành',
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementStatChip extends StatelessWidget {
  const _AchievementStatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 176,
      ),
    );
  }
}

class _BadgeTile extends StatefulWidget {
  const _BadgeTile({required this.badge});

  final AchievementBadge badge;

  @override
  State<_BadgeTile> createState() => _BadgeTileState();
}

class _BadgeTileState extends State<_BadgeTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final colorScheme = Theme.of(context).colorScheme;
    final visual = _BadgeVisualStyle.forBadge(badge);
    final progressText = _badgeProgressText(badge);
    final child = AnimatedScale(
      scale: _hovered ? 1.02 : 1,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: badge.isEarned
              ? visual.background
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isEarned ? visual.border : colorScheme.outlineVariant,
            width: badge.isEarned ? 1.4 : 1,
          ),
          boxShadow: badge.isEarned
              ? [
                  BoxShadow(
                    color: visual.foreground.withValues(
                      alpha: _hovered ? 0.20 : 0.12,
                    ),
                    blurRadius: _hovered ? 18 : 12,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showBadgeDetail(context, badge),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: badge.isEarned
                            ? Colors.white.withValues(alpha: 0.66)
                            : colorScheme.surface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: badge.isEarned
                              ? visual.border
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      child: Icon(
                        visual.icon,
                        color: badge.isEarned
                            ? visual.foreground
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.58,
                              ),
                        size: 34,
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: badge.isEarned
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          badge.isEarned
                              ? Icons.check_rounded
                              : Icons.lock_rounded,
                          color: colorScheme.onPrimary,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  badge.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: badge.isEarned
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  badge.isEarned ? 'Đã đạt' : progressText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: badge.isEarned
                        ? visual.foreground
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (!badge.isEarned && badge.progressTarget > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: badge.progressValue,
                      backgroundColor: colorScheme.surface,
                      color: visual.foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label:
          '${badge.name}, ${badge.isEarned ? 'đã mở khóa' : 'chưa mở khóa, tiến độ $progressText'}.',
      child: Tooltip(
        message: '${badge.name} - ${badge.isEarned ? 'Đã đạt' : progressText}',
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: child,
        ),
      ),
    );
  }
}

class _BadgeVisualStyle {
  const _BadgeVisualStyle({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;

  static _BadgeVisualStyle forBadge(AchievementBadge badge) {
    final key = '${badge.id} ${badge.ruleKey}'.toLowerCase();
    if (key.contains('perfect') || key.contains('quiz_score_10')) {
      return const _BadgeVisualStyle(
        icon: Icons.star_rounded,
        foreground: Color(0xFFD97706),
        background: Color(0xFFFFF7D6),
        border: Color(0xFFFBBF24),
      );
    }
    if (key.contains('motion')) {
      return const _BadgeVisualStyle(
        icon: Icons.speed_rounded,
        foreground: Color(0xFF0891B2),
        background: Color(0xFFDDFBFF),
        border: Color(0xFF22D3EE),
      );
    }
    if (key.contains('force')) {
      return const _BadgeVisualStyle(
        icon: Icons.fitness_center_rounded,
        foreground: Color(0xFF7C3AED),
        background: Color(0xFFF0E7FF),
        border: Color(0xFFA78BFA),
      );
    }
    if (key.contains('electric')) {
      return const _BadgeVisualStyle(
        icon: Icons.electric_bolt_rounded,
        foreground: Color(0xFF2563EB),
        background: Color(0xFFE0F2FE),
        border: Color(0xFF7DD3FC),
      );
    }
    if (key.contains('streak')) {
      return const _BadgeVisualStyle(
        icon: Icons.local_fire_department_rounded,
        foreground: Color(0xFFEA580C),
        background: Color(0xFFFFEDD5),
        border: Color(0xFFFB923C),
      );
    }
    if (key.contains('all') ||
        key.contains('scientist') ||
        key.contains('complete_all_lessons')) {
      return const _BadgeVisualStyle(
        icon: Icons.diamond_rounded,
        foreground: Color(0xFF9333EA),
        background: Color(0xFFF5E8FF),
        border: Color(0xFFC084FC),
      );
    }
    if (key.contains('first') || key.contains('starter')) {
      return const _BadgeVisualStyle(
        icon: Icons.rocket_launch_rounded,
        foreground: Color(0xFF2563EB),
        background: Color(0xFFEFF6FF),
        border: Color(0xFF93C5FD),
      );
    }
    return const _BadgeVisualStyle(
      icon: Icons.workspace_premium_rounded,
      foreground: Color(0xFF475569),
      background: Color(0xFFF1F5F9),
      border: Color(0xFFCBD5E1),
    );
  }
}

String _badgeProgressText(AchievementBadge badge) {
  if (badge.isEarned) {
    return 'Đã đạt';
  }
  if (badge.progressTarget <= 0) {
    return badge.ruleKey == 'quiz_score_10' ? 'Chưa đạt điểm 10' : 'Chưa đạt';
  }
  final current = badge.progressCurrent.clamp(0, badge.progressTarget);
  final key = '${badge.ruleKey} ${badge.id}'.toLowerCase();
  final unit = key.contains('streak') ? 'ngày' : 'bài';
  return '$current/${badge.progressTarget} $unit';
}

void _showBadgeDetail(BuildContext context, AchievementBadge badge) {
  final visual = _BadgeVisualStyle.forBadge(badge);
  final colorScheme = Theme.of(context).colorScheme;
  final progressText = _badgeProgressText(badge);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? visual.background
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: badge.isEarned
                        ? visual.border
                        : colorScheme.outlineVariant,
                  ),
                ),
                child: Icon(
                  badge.isEarned ? visual.icon : Icons.lock_rounded,
                  size: 42,
                  color: badge.isEarned
                      ? visual.foreground
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              badge.isEarned ? 'Đã mở khóa' : 'Chưa mở khóa',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: badge.isEarned
                    ? visual.foreground
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              badge.description.isEmpty
                  ? 'Hoàn thành điều kiện để mở khóa huy hiệu này.'
                  : badge.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (badge.isEarned)
              Text(
                badge.achievedAt == null
                    ? 'Ngày mở khóa: chưa có dữ liệu'
                    : 'Mở khóa ngày: ${_formatDate(badge.achievedAt!)}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              )
            else ...[
              Text(
                'Tiến độ: $progressText',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (badge.progressTarget > 0) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: badge.progressValue,
                    color: visual.foreground,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
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
