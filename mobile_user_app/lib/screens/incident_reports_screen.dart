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
            assignedToName: json['assigned_to'] != null
                ? (json['assigned_to']['name'] as String?)
                : null,
          );
        }).toList();
        setState(() {
          _reports = incidents;
          _isLoading = false;
        });
      } else {
        setState(() {
          _reports = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading incidents: $e');
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
                shadowColor: SreaColors.buttonReport.withOpacity(
                  0.4,
                ), // fixed for older Flutter
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

// ─── Report Card with larger thumbnail on the right of description ───
class _ReportCard extends StatelessWidget {
  final IncidentReport report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  // Helper to get full image URL from relative path
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
    String descriptionPreview = report.description.length > 80
        ? '${report.description.substring(0, 80)}...'
        : report.description;
    String reporterBadgeText;
    Color reporterBadgeColor;
    if (report.reporterRole == 'resident') {
      if (report.reporterIsVerified) {
        reporterBadgeText = 'Verified Resident';
        reporterBadgeColor = SreaColors.low;
      } else {
        reporterBadgeText = 'Unverified Resident';
        reporterBadgeColor = SreaColors.medium;
      }
    } else {
      reporterBadgeText = 'Non-Resident';
      reporterBadgeColor = SreaColors.textHint;
    }

    final thumbnailUrl = _getThumbnailUrl();
    final hasPhoto = thumbnailUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SreaCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: type, barangay, date, status, reporter badge (unchanged)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.type,
                        style: SreaText.bodyLarge(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.barangay,
                        style: SreaText.bodySmall(
                          context,
                        ).copyWith(color: SreaColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(report.reportedAt),
                        style: SreaText.label(
                          context,
                        ).copyWith(color: SreaColors.textHint),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SreaBadge(
                      type: _statusToBadgeType(report.status),
                      label: report.status,
                      showDot: true,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: reporterBadgeColor.withOpacity(0.1),
                        borderRadius: SreaRadius.pill,
                      ),
                      child: Text(
                        reporterBadgeText,
                        style: SreaText.label(context).copyWith(
                          color: reporterBadgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Description + thumbnail (side by side, thumbnail larger)
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    descriptionPreview,
                    style: SreaText.bodySmall(
                      context,
                    ).copyWith(color: SreaColors.textSecondary, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasPhoto) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SreaRadius.sm),
                    child: Image.network(
                      thumbnailUrl,
                      width: 80, // larger thumbnail
                      height: 80, // larger thumbnail
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        size: 40,
                        color: SreaColors.textHint,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Location details (if any)
            if (report.locationDetails != null &&
                report.locationDetails!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: SreaColors.textHint,
                  ),
                  const SizedBox(width: 4),
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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
