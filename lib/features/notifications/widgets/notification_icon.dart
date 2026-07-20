import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/notification_provider.dart';

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key, this.color});

  final Color? color;

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  void _handleTap(BuildContext context) {
    context.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationProvider, int>(
      (p) => p.unreadCount,
    );

    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _handleTap(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 20,
              color: widget.color ?? Colors.black87,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
