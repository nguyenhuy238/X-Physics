import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({required this.repository});

  final NotificationRepository repository;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  Timer? _pollingTimer;
  final _newNotificationController = StreamController<NotificationModel>.broadcast();

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Stream<NotificationModel> get onNewNotification => _newNotificationController.stream;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      pollNewNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _newNotificationController.close();
    super.dispose();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    if (refresh) {
      notifyListeners();
    }

    try {
      final result = await repository.getNotifications(page: 1, limit: 50);
      _notifications = result.items;
      _unreadCount = result.unreadCount;
      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pollNewNotifications() async {
    try {
      final result = await repository.getNotifications(page: 1, limit: 10);
      
      final newItems = result.items.where((newItem) => 
        !_notifications.any((existing) => existing.id == newItem.id)
      ).toList();

      if (newItems.isNotEmpty) {
        _notifications = [
          ...newItems,
          ..._notifications.where((existing) => !newItems.any((n) => n.id == existing.id))
        ];
        _unreadCount = result.unreadCount;
        notifyListeners();

        if (_isInitialized) {
          for (final item in newItems.reversed) {
            _newNotificationController.add(item);
          }
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to poll notifications: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await repository.markAsRead(id);
      
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
      
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }
}
