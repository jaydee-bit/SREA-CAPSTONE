import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ResponderNotificationService _notificationService =
      ResponderNotificationService();

  @override
  void initState() {
    super.initState();
    if (_notificationService.notifications.isEmpty) {
      _notificationService.loadMockNotifications();
    }
    _notificationService.addListener(_updateUnreadCount);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_updateUnreadCount);
    super.dispose();
  }

  void _updateUnreadCount() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notificationService.unreadCount;

    return Scaffold(
      backgroundColor: SreaColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
        backgroundColor: SreaColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SreaColors.textOnPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () => _notificationService.markAllAsRead(),
              child: Text(
                'Mark all read',
                style: SreaText.label(
                  context,
                ).copyWith(color: SreaColors.textOnPrimary),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _notificationService,
        builder: (context, child) {
          final notifications = _notificationService.notifications;
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return GestureDetector(
                onTap: () {
                  if (!notif.isRead) _notificationService.markAsRead(notif.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: notif.isRead
                        ? SreaColors.surface
                        : SreaColors.primaryLight,
                    borderRadius: SreaRadius.card,
                    border: Border.all(
                      color: notif.isRead
                          ? SreaColors.border
                          : SreaColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: SreaText.bodyLarge(context).copyWith(
                                fontWeight: FontWeight.w700,
                                color: notif.isRead
                                    ? SreaColors.textSecondary
                                    : SreaColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: SreaColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        style: SreaText.bodySmall(context).copyWith(
                          color: notif.isRead
                              ? SreaColors.textHint
                              : SreaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notif.timestamp),
                        style: SreaText.label(
                          context,
                        ).copyWith(color: SreaColors.textHint),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}
