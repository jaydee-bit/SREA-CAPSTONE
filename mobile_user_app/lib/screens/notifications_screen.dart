// File: notifications_screen.dart
// Path: mobile_user_app/lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../models/incident_report_model.dart';
import 'alert_detail_screen.dart';
import 'announcements_screen.dart'; // for Announcement class
import 'announcement_detail_screen.dart';
import 'traffic_advisories_screen.dart'; // for TrafficAdvisory class
import 'traffic_advisory_detail_screen.dart';
import 'incident_report_detail_screen.dart';

class NotificationItem {
  final String id;
  final String type; // 'alert', 'announcement', 'traffic', 'incident'
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? rawData;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.rawData,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final user = await api.getUser();
      final role = user['role'];
      final userBarangay = user['barangay'] ?? '';
      final isResident = role == 'resident';

      final results = await Future.wait([
        api.getAlerts(),
        api.getAnnouncements(),
        api.getTrafficAdvisories(),
        api.getMyIncidents(),
      ]);

      final alerts = results[0] as List<dynamic>;
      final announcements = results[1] as List<dynamic>;
      final traffic = results[2] as List<dynamic>;
      final incidents = results[3] as List<dynamic>;

      final List<NotificationItem> items = [];

      // 1. Alerts (filter by barangay for residents)
      for (var alert in alerts) {
        if (isResident) {
          final barangay = alert['barangay'];
          if (barangay != null &&
              barangay.isNotEmpty &&
              barangay != userBarangay) {
            continue;
          }
        }
        items.add(
          NotificationItem(
            id: 'alert_${alert['id']}',
            type: 'alert',
            title: alert['title'] ?? '',
            message: alert['description'] ?? '',
            timestamp: DateTime.parse(alert['created_at']),
            rawData: alert,
          ),
        );
      }

      // 2. Announcements (filter by barangay for residents)
      for (var ann in announcements) {
        if (isResident) {
          final barangay = ann['barangay'];
          if (barangay != null &&
              barangay.isNotEmpty &&
              barangay != userBarangay) {
            continue;
          }
        }
        items.add(
          NotificationItem(
            id: 'announcement_${ann['id']}',
            type: 'announcement',
            title: ann['title'] ?? '',
            message: ann['content'] ?? '',
            timestamp: DateTime.parse(
              ann['published_at'] ??
                  ann['created_at'] ??
                  DateTime.now().toIso8601String(),
            ),
            rawData: ann,
          ),
        );
      }

      // 3. Traffic advisories (all)
      for (var adv in traffic) {
        items.add(
          NotificationItem(
            id: 'traffic_${adv['id']}',
            type: 'traffic',
            title: adv['title'] ?? '',
            message: adv['description'] ?? '',
            timestamp: DateTime.parse(adv['created_at']),
            rawData: adv,
          ),
        );
      }

      // 4. Incident status updates (non-pending)
      for (var inc in incidents) {
        final status = inc['status'] ?? 'Pending';
        if (status == 'Pending') continue;
        String statusMessage = '';
        switch (status.toLowerCase()) {
          case 'under review':
            statusMessage = 'Your report is now under review by MDRRMO.';
            break;
          case 'resolved':
            statusMessage = 'Your report has been resolved.';
            break;
          case 'rejected':
            statusMessage =
                'Your report was rejected. Please contact MDRRMO for details.';
            break;
          case 'escalated':
            statusMessage =
                'Your report has been escalated to higher authorities.';
            break;
          default:
            statusMessage = 'Status updated to $status.';
        }
        items.add(
          NotificationItem(
            id: 'incident_${inc['id']}',
            type: 'incident',
            title: 'Incident Update: ${inc['type']}',
            message: statusMessage,
            timestamp: DateTime.parse(inc['updated_at'] ?? inc['reported_at']),
            rawData: inc,
          ),
        );
      }

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (!mounted) return;
      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadNotifications();
  }

  void _onNotificationTap(NotificationItem item) {
    if (item.type == 'alert' && item.rawData != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlertDetailScreen(alert: item.rawData!),
        ),
      );
    } else if (item.type == 'announcement' && item.rawData != null) {
      final announcement = Announcement(
        id: item.rawData!['id'],
        title: item.rawData!['title'] ?? '',
        body: item.rawData!['content'] ?? '',
        publishedAt: DateTime.parse(
          item.rawData!['published_at'] ??
              item.rawData!['created_at'] ??
              DateTime.now().toIso8601String(),
        ),
        barangay: item.rawData!['barangay'],
        imageUrl: item.rawData!['image_url'],
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnouncementDetailScreen(announcement: announcement),
        ),
      );
    } else if (item.type == 'traffic' && item.rawData != null) {
      final severityMap = {
        'high': SreaBadgeType.high,
        'medium': SreaBadgeType.medium,
        'low': SreaBadgeType.low,
      };
      final severity =
          severityMap[item.rawData!['severity']] ?? SreaBadgeType.low;
      final advisory = TrafficAdvisory(
        id: item.rawData!['id'],
        title: item.rawData!['title'] ?? '',
        description: item.rawData!['description'] ?? '',
        location: item.rawData!['location'] ?? '',
        severity: severity,
        publishedAt: DateTime.parse(
          item.rawData!['created_at'] ?? DateTime.now().toIso8601String(),
        ),
        effectiveFrom: item.rawData!['effective_from'] != null
            ? DateTime.parse(item.rawData!['effective_from'])
            : null,
        effectiveTo: item.rawData!['effective_to'] != null
            ? DateTime.parse(item.rawData!['effective_to'])
            : null,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrafficAdvisoryDetailScreen(advisory: advisory),
        ),
      );
    } else if (item.type == 'incident' && item.rawData != null) {
      final reporter = item.rawData!['reporter'] ?? {};
      final incident = IncidentReport(
        id: item.rawData!['id'].toString(),
        type: item.rawData!['type'] ?? '',
        description: item.rawData!['description'] ?? '',
        photoPath: item.rawData!['photo_path'],
        barangay: item.rawData!['barangay'] ?? '',
        locationDetails: item.rawData!['location_details'],
        coordinates: LatLng(
          double.parse(item.rawData!['latitude'].toString()),
          double.parse(item.rawData!['longitude'].toString()),
        ),
        address: item.rawData!['address'] ?? '',
        status: item.rawData!['status'] ?? 'Pending',
        reportedAt: DateTime.parse(item.rawData!['reported_at']),
        personsInvolved: item.rawData!['persons_involved'],
        reporterRole: reporter['role'] ?? '',
        reporterIsVerified: reporter['is_verified'] ?? false,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IncidentReportDetailScreen(report: incident),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SreaColors.background,
      appBar: AppBar(
        backgroundColor: SreaColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: SreaColors.textOnPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: SreaText.bodySmall(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none_outlined,
                      size: 64,
                      color: SreaColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No notifications',
                      style: SreaText.bodyLarge(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final item = _notifications[index];
                  IconData icon;
                  switch (item.type) {
                    case 'alert':
                      icon = Icons.warning_amber_rounded;
                      break;
                    case 'announcement':
                      icon = Icons.campaign_rounded;
                      break;
                    case 'traffic':
                      icon = Icons.traffic_rounded;
                      break;
                    default:
                      icon = Icons.info_outline_rounded;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SreaCard(
                      onTap: () => _onNotificationTap(item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 22, color: SreaColors.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: SreaText.bodyLarge(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SreaColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.message,
                            style: SreaText.bodySmall(context).copyWith(
                              color: SreaColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(item.timestamp),
                            style: SreaText.label(
                              context,
                            ).copyWith(color: SreaColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
