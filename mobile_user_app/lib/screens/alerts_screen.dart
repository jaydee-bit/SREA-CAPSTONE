// File: alerts_screen.dart
// Path: mobile_user_app/lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../services/api_service.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<dynamic> _alerts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getAlerts();
      setState(() {
        _alerts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load alerts. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAlerts();
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
          'Alerts',
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
                      onPressed: _loadAlerts,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_outlined, size: 64, color: SreaColors.textHint),
                          const SizedBox(height: 16),
                          Text(
                            'No active alerts',
                            style: SreaText.bodyLarge(context).copyWith(color: SreaColors.textSecondary),
                          ),
                        ],
                      ),
                    )
    
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _alerts.length,
                itemBuilder: (context, index) {
                  final alert = _alerts[index];
                  final level = alert['level']?.toLowerCase() ?? 'low';
                  SreaBadgeType badgeType;
                  switch (level) {
                    case 'critical':
                      badgeType = SreaBadgeType.critical;
                      break;
                    case 'high':
                      badgeType = SreaBadgeType.high;
                      break;
                    case 'medium':
                      badgeType = SreaBadgeType.medium;
                      break;
                    default:
                      badgeType = SreaBadgeType.low;
                  }
                  final isBarangaySpecific =
                      alert['barangay'] != null && alert['barangay'].isNotEmpty;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SreaCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlertDetailScreen(alert: alert),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  alert['title'] ?? '',
                                  style: SreaText.bodyLarge(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SreaColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SreaBadge(
                                type: badgeType,
                                label: level.toUpperCase(),
                                showDot: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            alert['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: SreaText.bodySmall(context).copyWith(
                              color: SreaColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: SreaColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(alert['created_at']),
                                style: SreaText.label(
                                  context,
                                ).copyWith(color: SreaColors.textHint),
                              ),
                              if (isBarangaySpecific) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 12,
                                  color: SreaColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  alert['barangay'],
                                  style: SreaText.label(
                                    context,
                                  ).copyWith(color: SreaColors.primary),
                                ),
                              ],
                            ],
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${_monthAbbr(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
