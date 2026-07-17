import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../shared/models/x_models.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../progress/application/app_state.dart';
import '../widgets/admin_layout.dart';

class AdminChaptersScreen extends StatefulWidget {
  const AdminChaptersScreen({super.key});

  @override
  State<AdminChaptersScreen> createState() => _AdminChaptersScreenState();
}

class _AdminChaptersScreenState extends State<AdminChaptersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().loadAdminChapters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filteredChapters = state.chapters.where((chapter) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      return chapter.title.toLowerCase().contains(q) ||
          chapter.id.toLowerCase().contains(q) ||
          chapter.description.toLowerCase().contains(q);
    }).toList();

    return AdminLayout(
      title: 'Qu?n lý Ch??ng h?c',
      subtitle: 'T?t c? ch??ng h?c hi?n có trên h? th?ng',
      activeRoute: '/admin/chapters',
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      child: state.isBusy && state.chapters.isEmpty
          ? const LoadingView(message: '?ang t?i chapters...')
          : state.errorMessage != null && state.chapters.isEmpty
              ? ErrorView(
                  message: state.errorMessage!,
                  onRetry: () => Provider.of<AppState>(context, listen: false).loadAdminChapters(),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final totalChapters = filteredChapters.length;
                    final publishedChapters = filteredChapters.where((c) => c.isPublished).length;

                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalChapters ch??ng - $publishedChapters ?ã xu?t b?n',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => _showChapterDialog(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Thêm ch??ng'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Container(
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
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: Table(
                                columnWidths: const {
                                  0: FixedColumnWidth(48),
                                  1: FlexColumnWidth(3),
                                  2: FixedColumnWidth(90),
                                  3: FixedColumnWidth(110),
                                  4: FixedColumnWidth(130),
                                  5: FixedColumnWidth(130),
                                  6: FixedColumnWidth(110),
                                },
                                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Color(0xFFF1F5F9),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    children: [
                                      const SizedBox(height: 48),
                                      _buildHeaderCell('TÊN CH??NG', alignment: TextAlign.left),
                                      _buildHeaderCell('TH? T?'),
                                      _buildHeaderCell('S? BÀI H?C'),
                                      _buildHeaderCell('TR?NG THÁI'),
                                      _buildHeaderCell('NGÀY T?O'),
                                      _buildHeaderCell('THAO TÁC'),
                                    ],
                                  ),
                                  for (final chapter in filteredChapters)
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Color(0xFFF1F5F9),
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.drag_indicator_rounded,
                                            color: Color(0xFF94A3B8),
                                            size: 20,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          child: Text(
                                            chapter.title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () => _updateOrder(context, chapter, true),
                                              icon: const Icon(Icons.keyboard_arrow_up_rounded),
                                              iconSize: 16,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: const Color(0xFF94A3B8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${chapter.orderIndex}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            IconButton(
                                              onPressed: () => _updateOrder(context, chapter, false),
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                              iconSize: 16,
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ],
                                        ),
                                        Center(
                                          child: Text(
                                            '${chapter.lessonCount}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: chapter.isPublished
                                                  ? const Color(0xFFD1FAE5)
                                                  : const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              chapter.isPublished ? '?ã xu?t b?n' : 'Nháp',
                                              style: TextStyle(
                                                color: chapter.isPublished
                                                    ? const Color(0xFF065F46)
                                                    : const Color(0xFF92400E),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            _formatDate(chapter.createdAt),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () => _showChapterDialog(context, chapter: chapter),
                                              icon: const Icon(Icons.edit_rounded),
                                              iconSize: 16,
                                              color: const Color(0xFF2563EB),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFEFF6FF),
                                                padding: const EdgeInsets.all(6),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              onPressed: () => _confirmDelete(context, chapter.id),
                                              icon: const Icon(Icons.delete_rounded),
                                              iconSize: 16,
                                              color: const Color(0xFFEF4444),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(0xFFFEF2F2),
                                                padding: const EdgeInsets.all(6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildHeaderCell(String label, {TextAlign alignment = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Text(
        label,
        textAlign: alignment,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  String _formatDate(String? createdAtStr) {
    if (createdAtStr == null) return '01/05/2026';
    try {
      final dt = DateTime.parse(createdAtStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '01/05/2026';
    }
  }

  Future<void> _updateOrder(BuildContext context, Chapter chapter, bool isUp) async {
    final state = Provider.of<AppState>(context, listen: false);
    final newOrder = chapter.orderIndex + (isUp ? -1 : 1);
    if (newOrder < 0) return;

    final updated = Chapter(
      id: chapter.id,
      title: chapter.title,
      description: chapter.description,
      orderIndex: newOrder,
      icon: chapter.icon,
      color: chapter.color,
      isPublished: chapter.isPublished,
    );

    await state.updateAdminChapter(updated);
  }

  Future<void> _showChapterDialog(BuildContext context, {Chapter? chapter}) async {
    final state = Provider.of<AppState>(context, listen: false);
    final maxOrder = state.chapters.isEmpty
        ? 0
        : state.chapters.map((c) => c.orderIndex).reduce((a, b) => a > b ? a : b);
    final defaultOrder = chapter?.orderIndex ?? (maxOrder + 1);

    final id = TextEditingController(text: chapter?.id ?? '');
    final title = TextEditingController(text: chapter?.title ?? '');
    final description = TextEditingController(text: chapter?.description ?? '');
    final order = TextEditingController(text: '$defaultOrder');
    var isPublished = chapter?.isPublished ?? true;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Chapter>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            chapter == null ? 'Thêm Ch??ng h?c' : 'C?p nh?t Ch??ng h?c',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close_rounded),
                            color: const Color(0xFF64748B),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        chapter == null
                            ? 'T?o m?t ch??ng m?i ?? t? ch?c các bài h?c v?t lý.'
                            : 'Ch?nh s?a thông tin chi ti?t c?a ch??ng h?c hi?n có.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Divider(color: Color(0xFFF1F5F9), height: 32),

                      const Text(
                        'MÃ CH??NG (ID)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: id,
                        enabled: chapter == null,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'VD: motion, force, electric',
                          prefixIcon: const Icon(Icons.vpn_key_rounded, color: Color(0xFF94A3B8), size: 20),
                          filled: true,
                          fillColor: chapter == null ? const Color(0xFFF8FAFC) : const Color(0xFFE2E8F0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Mã ch??ng là b?t bu?c' : null,
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'TÊN CH??NG H?C',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: title,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'Nh?p tên ch??ng h?c',
                          prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF94A3B8), size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Tên ch??ng là b?t bu?c' : null,
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'MÔ T? NG?N',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: description,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Nh?p mô t? tóm t?t n?i dung ch??ng h?c',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 32),
                            child: Icon(Icons.description_rounded, color: Color(0xFF94A3B8), size: 20),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'Mô t? là b?t bu?c' : null,
                      ),
                      const SizedBox(height: 18),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TH? T? S?P X?P',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: order,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.sort_rounded, color: Color(0xFF94A3B8), size: 20),
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TR?NG THÁI',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isPublished ? 'Xu?t b?n' : 'B?n nháp',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isPublished ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        ),
                                      ),
                                      Switch(
                                        value: isPublished,
                                        activeThumbColor: const Color(0xFF2563EB),
                                        onChanged: (value) =>
                                            setDialogState(() => isPublished = value),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            child: const Text(
                              'H?y b?',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() != true) {
                                return;
                              }
                              Navigator.pop(
                                dialogContext,
                                Chapter(
                                  id: id.text.trim(),
                                  title: title.text.trim(),
                                  description: description.text.trim(),
                                  orderIndex: int.tryParse(order.text) ?? 0,
                                  isPublished: isPublished,
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            child: const Text(
                              'L?u ch??ng h?c',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (result == null || !context.mounted) return;
    if (chapter == null) {
      await state.saveAdminChapter(result);
    } else {
      await state.updateAdminChapter(result);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Xóa chapter?'),
            content: const Text('Chapter s? ???c ?n kh?i l??ng h?c sinh.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('H?y'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ??
        false;
    if (ok && context.mounted) {
      await Provider.of<AppState>(context, listen: false).deleteAdminChapter(id);
    }
  }
}
