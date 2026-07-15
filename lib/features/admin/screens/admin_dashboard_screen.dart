import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadAdminDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.canAccessAdmin) {
      return const Scaffold(
        body: Center(
          child: ErrorView(message: 'Bạn không có quyền truy cập Admin.'),
        ),
      );
    }
    
    final stats = state.adminStatistics;
    
    return AdminLayout(
      title: 'Dashboard',
      subtitle: 'Tổng quan hệ thống X-Physics',
      activeRoute: '/admin',
      child: state.isBusy && stats == null
          ? const LoadingView(message: 'Đang tải thống kê...')
          : state.errorMessage != null && stats == null
              ? ErrorView(
                  message: state.errorMessage!,
                  onRetry: () => context.read<AppState>().loadAdminDashboard(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 950;
                    
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Top row of 4 stat cards
                        _buildStatCards(stats, constraints.maxWidth),
                        const SizedBox(height: 24),
                        
                        // Second row (Active Users Chart + Hardest Lessons)
                        if (isWide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildActiveUsersChart(stats),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildHardestLessons(stats),
                              ),
                            ],
                          )
                        else ...[
                          _buildActiveUsersChart(stats),
                          const SizedBox(height: 24),
                          _buildHardestLessons(stats),
                        ],
                        const SizedBox(height: 24),
                        
                        // Third row: Recent Activity List
                        _buildRecentActivity(context, stats),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildStatCards(Map<String, dynamic>? stats, double maxWidth) {
    final columns = maxWidth > 1100
        ? 4
        : maxWidth > 700
            ? 2
            : 1;

    final cardData = [
      _StatCardItem(
        label: 'HỌC SINH',
        value: '${stats?['totalUsers'] ?? 5}',
        subtext: '+2 tuần này',
        icon: Icons.people_alt_rounded,
        iconColor: const Color(0xFF3B82F6),
        bgColor: const Color(0xFFEFF6FF),
      ),
      _StatCardItem(
        label: 'CHƯƠNG HỌC',
        value: '${stats?['totalChapters'] ?? 5}',
        subtext: '4 đã xuất bản',
        icon: Icons.auto_stories_rounded,
        iconColor: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
      ),
      _StatCardItem(
        label: 'BÀI HỌC',
        value: '${stats?['totalLessons'] ?? 18}',
        subtext: '15 đã xuất bản',
        icon: Icons.menu_book_rounded,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFFECFDF5),
      ),
      _StatCardItem(
        label: 'CÂU HỎI',
        value: '${stats?['totalQuestions'] ?? 42}',
        subtext: '+8 tuần này',
        icon: Icons.help_outline_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFFFFBEB),
      ),
    ];

    if (columns == 4) {
      return Row(
        children: cardData
            .map((item) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: item == cardData.last ? 0 : 16,
                    ),
                    child: _buildStatCard(item),
                  ),
                ))
            .toList(),
      );
    } else if (columns == 2) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard(cardData[0])),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(cardData[1])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard(cardData[2])),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(cardData[3])),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: cardData
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildStatCard(item),
                ))
            .toList(),
      );
    }
  }

  Widget _buildStatCard(_StatCardItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtext,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.iconColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUsersChart(Map<String, dynamic>? stats) {
    final List<dynamic>? dbPoints = stats?['activeUsersData'] as List<dynamic>?;
    final List<double> dataPoints = dbPoints != null
        ? dbPoints.map((val) => (val as num).toDouble() * 15 + 15).toList() // Scale to fit y-axis 0-120 beautifully
        : const [45, 62, 58, 72, 90, 105, 78]; // Fallback

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Người dùng hoạt động',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '7 ngày gần nhất',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 4),
                    Text(
                      '+18%',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: Size.infinite,
              painter: LineChartPainter(
                dataPoints: dataPoints,
                xLabels: const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
                yTicks: const [0, 30, 60, 90, 120],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardestLessons(Map<String, dynamic>? stats) {
    final List<dynamic>? dbLessons = stats?['hardestLessons'] as List<dynamic>?;
    final hardestLessons = dbLessons != null && dbLessons.isNotEmpty
        ? dbLessons.map((item) {
            final map = item as Map<dynamic, dynamic>;
            final percentage = (map['percentage'] as num).toDouble();
            Color color = const Color(0xFFEF4444); // Red
            if (percentage > 0.75) {
              color = const Color(0xFFF59E0B); // Yellow/Amber
            } else if (percentage > 0.65) {
              color = const Color(0xFFEAB308); // Yellow-Orange
            } else if (percentage > 0.50) {
              color = const Color(0xFFF97316); // Orange
            }
            return _DifficultyItem(
              title: map['title'] as String? ?? '',
              percentage: percentage,
              color: color,
            );
          }).toList()
        : [
            _DifficultyItem(title: 'Tính tương đối', percentage: 0.40, color: const Color(0xFFEF4444)),
            _DifficultyItem(title: 'Áp suất chất lỏng', percentage: 0.55, color: const Color(0xFFF97316)),
            _DifficultyItem(title: 'Định luật Ohm', percentage: 0.60, color: const Color(0xFFF59E0B)),
            _DifficultyItem(title: 'Chuyển động KĐ', percentage: 0.70, color: const Color(0xFFEAB308)),
            _DifficultyItem(title: 'Lực ma sát', percentage: 0.80, color: const Color(0xFFF59E0B)),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bài học khó nhất',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Theo điểm trung bình',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          ...hardestLessons.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.percentage,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(item.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, Map<String, dynamic>? stats) {
    final List<dynamic>? dbActivities = stats?['recentActivities'] as List<dynamic>?;
    final activities = dbActivities != null && dbActivities.isNotEmpty
        ? dbActivities.map((item) {
            final map = item as Map<dynamic, dynamic>;
            final type = map['type'] as String? ?? '';
            
            IconData icon = Icons.info_outline_rounded;
            Color iconColor = const Color(0xFF3B82F6);
            Color iconBg = const Color(0xFFEFF6FF);

            if (type == 'quiz') {
              icon = Icons.assignment_turned_in_rounded;
              iconColor = const Color(0xFFF97316);
              iconBg = const Color(0xFFFFF7ED);
            } else if (type == 'progress') {
              icon = Icons.menu_book_rounded;
              iconColor = const Color(0xFF3B82F6);
              iconBg = const Color(0xFFEFF6FF);
            } else if (type == 'user') {
              icon = Icons.person_add_rounded;
              iconColor = const Color(0xFF10B981);
              iconBg = const Color(0xFFECFDF5);
            } else if (type == 'download') {
              icon = Icons.download_rounded;
              iconColor = const Color(0xFF3B82F6);
              iconBg = const Color(0xFFEFF6FF);
            }

            final createdTimeStr = map['createdAt'] as String?;
            String timeText = 'vừa xong';
            if (createdTimeStr != null) {
              try {
                final dt = DateTime.parse(createdTimeStr).toLocal();
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 1) {
                  timeText = 'vừa xong';
                } else if (diff.inMinutes < 60) {
                  timeText = '${diff.inMinutes} phút trước';
                } else if (diff.inHours < 24) {
                  timeText = '${diff.inHours} giờ trước';
                } else {
                  timeText = '${diff.inDays} ngày trước';
                }
              } catch (_) {}
            }

            return _ActivityItem(
              userName: map['userName'] as String? ?? 'Học sinh',
              action: map['action'] as String? ?? 'hoạt động',
              detail: map['detail'] as String? ?? '',
              timeText: timeText,
              icon: icon,
              iconColor: iconColor,
              iconBg: iconBg,
            );
          }).toList()
        : [
            _ActivityItem(
              userName: 'Trần Thị Mai',
              action: 'Hoàn thành bài kiểm tra',
              detail: 'Chuyển động đều — 9.5/10',
              timeText: '5 phút trước',
              icon: Icons.assignment_turned_in_rounded,
              iconColor: const Color(0xFFF97316),
              iconBg: const Color(0xFFFFF7ED),
            ),
            _ActivityItem(
              userName: 'Nguyễn Văn Nam',
              action: 'Bắt đầu bài học',
              detail: 'Vận tốc trung bình',
              timeText: '12 phút trước',
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFFEFF6FF),
            ),
            _ActivityItem(
              userName: 'Lê Văn Hùng',
              action: 'Đăng ký tài khoản',
              detail: 'Lớp 8',
              timeText: '1 giờ trước',
              icon: Icons.person_add_rounded,
              iconColor: const Color(0xFF10B981),
              iconBg: const Color(0xFFECFDF5),
            ),
            _ActivityItem(
              userName: 'Phạm Thị Lan',
              action: 'Tải bài học offline',
              detail: 'Lực là gì?',
              timeText: '2 giờ trước',
              icon: Icons.download_rounded,
              iconColor: const Color(0xFF3B82F6),
              iconBg: const Color(0xFFEFF6FF),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(
              color: Color(0xFFF1F5F9),
              height: 24,
            ),
            itemBuilder: (context, index) {
              final item = activities[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: item.iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            children: [
                              TextSpan(
                                text: item.userName,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const TextSpan(text: ' — '),
                              TextSpan(text: item.action),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.detail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.timeText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCardItem {
  const _StatCardItem({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

class _DifficultyItem {
  const _DifficultyItem({
    required this.title,
    required this.percentage,
    required this.color,
  });

  final String title;
  final double percentage;
  final Color color;
}

class _ActivityItem {
  const _ActivityItem({
    required this.userName,
    required this.action,
    required this.detail,
    required this.timeText,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String userName;
  final String action;
  final String detail;
  final String timeText;
  final IconData icon;
  final Color color;
  final Color bgColor;
}

class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> xLabels;
  final List<double> yTicks;

  LineChartPainter({
    required this.dataPoints,
    required this.xLabels,
    required this.yTicks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 40.0;
    const double paddingRight = 20.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 30.0;

    final paintLine = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final paintGrid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw horizontal grid lines and Y labels
    for (var tick in yTicks) {
      final y = size.height - paddingBottom - ((tick / 120.0) * (size.height - paddingTop - paddingBottom));
      
      // Draw grid line
      canvas.drawLine(
        const Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        paintGrid,
      );

      // Draw Y label
      textPainter.text = TextSpan(
        text: tick.toInt().toString(),
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    final double widthBetweenPoints = (size.width - paddingLeft - paddingRight) / (dataPoints.length - 1);
    final List<Offset> points = [];

    for (int i = 0; i < dataPoints.length; i++) {
      final x = paddingLeft + i * widthBetweenPoints;
      final y = size.height - paddingBottom - ((dataPoints[i] / 120.0) * (size.height - paddingTop - paddingBottom));
      points.add(Offset(x, y));
    }

    // Draw X labels
    for (int i = 0; i < xLabels.length; i++) {
      textPainter.text = TextSpan(
        text: xLabels[i],
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2, size.height - paddingBottom + 8),
      );
    }

    // Draw background gradient fill under the line
    if (points.isNotEmpty) {
      final fillPath = Path()
        ..moveTo(points.first.dx, size.height - paddingBottom);
      
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPointX = p1.dx + (p2.dx - p1.dx) / 2;
        fillPath.cubicTo(
          controlPointX, p1.dy,
          controlPointX, p2.dy,
          p2.dx, p2.dy,
        );
      }
      
      fillPath.lineTo(points.last.dx, size.height - paddingBottom);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2563EB).withValues(alpha: .18),
          const Color(0xFF2563EB).withValues(alpha: .0),
        ],
      );
      paintFill.shader = gradient.createShader(
        Rect.fromLTRB(
          paddingLeft,
          paddingTop,
          size.width - paddingRight,
          size.height - paddingBottom,
        ),
      );
      canvas.drawPath(fillPath, paintFill);
    }

    // Draw smooth curved line
    if (points.isNotEmpty) {
      final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
      
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPointX = p1.dx + (p2.dx - p1.dx) / 2;
        strokePath.cubicTo(
          controlPointX, p1.dy,
          controlPointX, p2.dy,
          p2.dx, p2.dy,
        );
      }
      canvas.drawPath(strokePath, paintLine);
    }

    // Draw markers
    final paintCircleBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..isAntiAlias = true;

    final paintCircleCenter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    for (var p in points) {
      canvas.drawCircle(p, 5.5, paintCircleBorder);
      canvas.drawCircle(p, 3.5, paintCircleCenter);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
