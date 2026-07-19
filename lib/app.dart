import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/progress/application/app_state.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/notifications/widgets/in_app_notification.dart';
import 'features/notifications/services/local_notification_service.dart';

class XPhysicsApp extends StatelessWidget {
  const XPhysicsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = context.watch<AppState>().router;
    return MaterialApp.router(
      title: 'X-Physics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: context.watch<AppState>().themeMode,
      routerConfig: router ?? buildRouter(context.read<AppState>()),
      builder: (context, child) {
        return NotificationListenerWrapper(child: child!);
      },
    );
  }
}

class NotificationListenerWrapper extends StatefulWidget {
  const NotificationListenerWrapper({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState extends State<NotificationListenerWrapper> {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NotificationProvider>();
      
      // Initialize local notifications for mobile (Android/iOS)
      LocalNotificationService.initialize((payload) {
        if (mounted) {
          context.push('/notifications');
        }
      });

      
      _subscription = provider.onNewNotification.listen((notification) {
        final isMobile = defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS;
            
        if (isMobile && !kIsWeb) {
          // Show native system notification in tray
          LocalNotificationService.showNotification(
            id: notification.id.hashCode,
            title: notification.title,
            body: notification.message,
          );
        } else {
          // Show premium in-app sliding top banner for Web/Desktop
          InAppNotification.show(
            context: context,
            notification: notification,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    context.read<NotificationProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
