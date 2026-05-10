import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'package:latlong2/latlong.dart';
import '../models/incident_report_model.dart';
import '../services/api_service.dart';
import 'report_incident_screen.dart';
import 'incident_report_detail_screen.dart';

class IncidentReportsScreen extends StatefulWidget {
  const IncidentReportsScreen({super.key});

  @override
  State<IncidentReportsScreen> createState() => _IncidentReportsScreenState();
}

class _IncidentReportsScreenState extends State<IncidentReportsScreen> {
  List<IncidentReport> _reports = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getMyIncidents();

      if (data is List) {
        final List<IncidentReport> incidents = data.map((json) {
          final reporter = json['reporter'] ?? {};
          return IncidentReport(
            id: json['id'].toString(),
            type: json['type'] ?? '',
            description: json['description'] ?? '',
            photoPath: json['photo_path'],
            barangay: json['barangay'] ?? '',
            locationDetails: json['location_details'],
            coordinates: LatLng(
              double.parse(json['latitude'].toString()),
              double.parse(json['longitude'].toString()),
            ),
            address: json['address'] ?? '',
            status: json['status'] ?? 'Pending',
            reportedAt: DateTime.parse(json['reported_at']),
            personsInvolved: json['persons_involved'],
            reporterRole: reporter['role'] ?? '',
            reporterIsVerified: reporter['is_verified'] ?? false,
          );
        }).toList();

        // Sort: active (Pending, Under Review) newest first, resolved/rejected at bottom
        incidents.sort((a, b) {
          const sunk = {'resolved', 'rejected'};
          final aS = sunk.contains(a.status.toLowerCase());
          final bS = sunk.contains(b.status.toLowerCase());
          if (aS != bS) return aS ? 1 : -1;
          return b.reportedAt.compareTo(a.reportedAt);
        });

        if (!mounted) return;
        setState(() {
          _reports = incidents;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load incidents. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadReports();
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
          'My Incident Reports',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                elevation: 4,
                borderRadius: SreaRadius.button,
                shadowColor: SreaColors.buttonReport.withOpacity(0.4),
                child: SreaButton.report(
                  label: 'Report Incident',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportIncidentScreen(),
                      ),
                    ).then((_) => _loadReports());
                  },
                  fullWidth: true,
                  icon: Icons.add_alert_rounded,
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
            ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_reports.isEmpty) {
      return const _EmptyReports();
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return _ReportCard(
          report: report,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => IncidentReportDetailScreen(report: report),
            ),
          ).then((_) => _loadReports()),
        );
      },
    );
  }
}

// ─── Restructured Report Card (matches HTML mockup) ──────────────
class _ReportCard extends StatelessWidget {
  final IncidentReport report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  String _getThumbnailUrl() {
    final path = report.photoPath;
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final base = ApiService.baseImageUrl.endsWith('/')
        ? ApiService.baseImageUrl.substring(
            0,
            ApiService.baseImageUrl.length - 1,
          )
        : ApiService.baseImageUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$base$normalizedPath';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final thumbSize = width * 0.19; // ~76px on 400px screen
    final thumbRadius = width * 0.018; // ~8px
    final innerGap = width * 0.012;

    // Reporter badge
    String reporterLabel;
    Color reporterColor;
    if (report.reporterRole == 'resident') {
      if (report.reporterIsVerified) {
        reporterLabel = 'Verified Resident';
        reporterColor = SreaColors.low;
      } else {
        reporterLabel = 'Unverified Resident';
        reporterColor = SreaColors.medium;
      }
    } else {
      reporterLabel = 'Non-Resident';
      reporterColor = SreaColors.textHint;
    }

    final description = report.description.length > 120
        ? '${report.description.substring(0, 120)}...'
        : report.description;

    final thumbnailUrl = _getThumbnailUrl();
    final hasPhoto = thumbnailUrl.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: SreaSpacing.sm(context)),
      child: SreaCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Type + stacked badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.type,
                    style: SreaText.bodyLarge(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: width * 0.02),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SreaBadge(
                      type: _statusToBadgeType(report.status),
                      label: report.status,
                      showDot: true,
                    ),
                    SizedBox(height: width * 0.008),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.015,
                        vertical: width * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: reporterColor.withOpacity(0.1),
                        borderRadius: SreaRadius.pill,
                        border: reporterLabel == 'Non-Resident'
                            ? Border.all(color: SreaColors.border, width: 0.5)
                            : null,
                      ),
                      child: Text(
                        reporterLabel,
                        style: SreaText.label(context).copyWith(
                          color: reporterColor,
                          fontSize: width * 0.022,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: innerGap),

            // Row 2: Left text + Right thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: text block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barangay · Date
                      Text(
                        '${report.barangay}  ·  ${_formatDate(report.reportedAt)}',
                        style: SreaText.label(
                          context,
                        ).copyWith(color: SreaColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: innerGap),

                      // Description (max 3 lines)
                      Text(
                        description,
                        style: SreaText.bodySmall(context).copyWith(
                          color: SreaColors.textSecondary,
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Optional location details
                      if (report.locationDetails != null &&
                          report.locationDetails!.isNotEmpty) ...[
                        SizedBox(height: innerGap),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: width * 0.03,
                              color: SreaColors.textHint,
                            ),
                            SizedBox(width: width * 0.01),
                            Expanded(
                              child: Text(
                                report.locationDetails!,
                                style: SreaText.label(
                                  context,
                                ).copyWith(color: SreaColors.textHint),
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
                SizedBox(width: SreaSpacing.sm(context)),
                // Right: thumbnail (fixed size)
                ClipRRect(
                  borderRadius: BorderRadius.circular(thumbRadius),
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    color: SreaColors.surfaceVariant,
                    child: hasPhoto
                        ? Image.network(
                            thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              size: thumbSize * 0.42,
                              color: SreaColors.textHint,
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported_outlined,
                            size: thumbSize * 0.42,
                            color: SreaColors.textHint,
                          ),
                  ),
                ),
              ],
            ),

            SizedBox(height: innerGap * 1.2),
            const Divider(height: 1, color: SreaColors.divider),
            SizedBox(height: innerGap),

            // View details button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: SreaSpacing.sm(context),
                    vertical: width * 0.012,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View details →',
                  style: SreaText.label(context).copyWith(
                    color: SreaColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${_monthAbbr(date.month)} ${date.day}, ${date.year}';

  String _monthAbbr(int m) => const [
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
  ][m - 1];

  SreaBadgeType _statusToBadgeType(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return SreaBadgeType.resolved;
      case 'rejected':
        return SreaBadgeType.rejected;
      case 'under review':
        return SreaBadgeType.underReview;
      default:
        return SreaBadgeType.pending;
    }
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report_off_outlined, size: 64, color: SreaColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No incident reports',
            style: SreaText.bodyLarge(
              context,
            ).copyWith(color: SreaColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
