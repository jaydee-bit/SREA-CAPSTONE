import 'package:flutter/material.dart';

class ResponderNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  ResponderNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class ResponderNotificationService extends ChangeNotifier {
  static final ResponderNotificationService _instance =
      ResponderNotificationService._internal();
  factory ResponderNotificationService() => _instance;
  ResponderNotificationService._internal();

  List<ResponderNotification> _notifications = [];

  List<ResponderNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Load mock data (replace with API later)
  void loadMockNotifications() {
    _notifications = [
      ResponderNotification(
        id: '1',
        title: 'New incident reported',
        body: 'Flooding in Barangay Poblacion. Take action.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ResponderNotification(
        id: '2',
        title: 'Incident status changed',
        body: 'Incident #123 has been resolved by admin.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ResponderNotification(
        id: '3',
        title: 'Incident reassigned',
        body: 'Incident #456 was escalated because you were busy.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void addNotification(ResponderNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}
