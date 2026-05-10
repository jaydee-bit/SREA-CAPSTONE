// File: traffic_advisories_screen.dart
// Path: mobile_user_app/lib/screens/traffic_advisories_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../services/api_service.dart';
import 'traffic_advisory_detail_screen.dart';

// ========== TrafficAdvisory Model ==========
class TrafficAdvisory {
  final int id;
  final String title;
  final String description;
  final String location;
  final SreaBadgeType severity;
  final DateTime publishedAt;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;

  TrafficAdvisory({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.publishedAt,
    this.effectiveFrom,
    this.effectiveTo,
  });
}

// ========== Screen ==========
class TrafficAdvisoriesScreen extends StatefulWidget {
  const TrafficAdvisoriesScreen({super.key});

  @override
  State<TrafficAdvisoriesScreen> createState() =>
      _TrafficAdvisoriesScreenState();
}

class _TrafficAdvisoriesScreenState extends State<TrafficAdvisoriesScreen> {
  List<TrafficAdvisory> _advisories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAdvisories();
  }

  Future<void> _loadAdvisories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getTrafficAdvisories();
      if (!mounted) return;
      final List<TrafficAdvisory> loaded = data.map((json) {
        final severityStr = (json['severity'] ?? 'low').toLowerCase();
        SreaBadgeType severity;
        switch (severityStr) {
          case 'high':
            severity = SreaBadgeType.high;
            break;
          case 'medium':
            severity = SreaBadgeType.medium;
            break;
          default:
            severity = SreaBadgeType.low;
        }
        return TrafficAdvisory(
          id: json['id'],
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          location: json['location'] ?? '',
          severity: severity,
          publishedAt: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String(),
          ),
          effectiveFrom: json['effective_from'] != null
              ? DateTime.parse(json['effective_from'])
              : null,
          effectiveTo: json['effective_to'] != null
              ? DateTime.parse(json['effective_to'])
              : null,
        );
      }).toList();
      setState(() {
        _advisories = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load traffic advisories. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAdvisories();
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatEffectiveRange(TrafficAdvisory adv) {
    if (adv.effectiveFrom == null && adv.effectiveTo == null) return '';
    if (adv.effectiveFrom != null && adv.effectiveTo == null) {
      return 'From ${_formatDate(adv.effectiveFrom!)}';
    }
    if (adv.effectiveFrom == null && adv.effectiveTo != null) {
      return 'Until ${_formatDate(adv.effectiveTo!)}';
    }
    return '${_formatDate(adv.effectiveFrom!)} – ${_formatDate(adv.effectiveTo!)}';
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
          'Traffic Advisories',
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
                      onPressed: _loadAdvisories,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _advisories.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.traffic_outlined,
                      size: 64,
                      color: SreaColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No traffic advisories',
                      style: SreaText.bodyLarge(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _advisories.length,
                itemBuilder: (context, index) {
                  final adv = _advisories[index];
                  final severityLabel = adv.severity.name.toUpperCase();
                  final hasLongDesc = adv.description.length > 100;
                  final preview = hasLongDesc
                      ? '${adv.description.substring(0, 100)}...'
                      : adv.description;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SreaCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TrafficAdvisoryDetailScreen(advisory: adv),
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
                                  adv.title,
                                  style: SreaText.bodyLarge(context).copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SreaColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SreaBadge(
                                type: adv.severity,
                                label: severityLabel,
                                showDot: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: SreaColors.primaryLight,
                                  borderRadius: SreaRadius.input,
                                  border: Border.all(color: SreaColors.border),
                                ),
                                child: const Icon(
                                  Icons.map_outlined,
                                  size: 40,
                                  color: SreaColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: SreaColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            adv.location,
                                            style: SreaText.bodySmall(context)
                                                .copyWith(
                                                  color: SreaColors.primary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: SreaColors.textHint,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(adv.publishedAt),
                                          style: SreaText.label(context)
                                              .copyWith(
                                                color: SreaColors.textHint,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (_formatEffectiveRange(
                                      adv,
                                    ).isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_outlined,
                                            size: 12,
                                            color: SreaColors.textHint,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _formatEffectiveRange(adv),
                                              style: SreaText.label(context)
                                                  .copyWith(
                                                    color: SreaColors.textHint,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            preview,
                            style: SreaText.bodySmall(context).copyWith(
                              color: SreaColors.textSecondary,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'View details →',
                              style: SreaText.label(context).copyWith(
                                color: SreaColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
