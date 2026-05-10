// File: notification_service.dart
// Path: mobile_user_app/lib/services/notification_service.dart

import '../screens/notifications_screen.dart'; // only for type reference; not used actually

class AppNotification {
  final String id;
  final String type; // 'alert', 'announcement', 'traffic', 'incident'
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final List<void Function()> _listeners = [];

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = AppNotification(
        id: _notifications[index].id,
        type: _notifications[index].type,
        title: _notifications[index].title,
        body: _notifications[index].body,
        timestamp: _notifications[index].timestamp,
        isRead: true,
        payload: _notifications[index].payload,
      );
      _notifyListeners();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          body: _notifications[i].body,
          timestamp: _notifications[i].timestamp,
          isRead: true,
          payload: _notifications[i].payload,
        );
      }
    }
    _notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void clearAll() {
    _notifications.clear();
    _notifyListeners();
  }
}
