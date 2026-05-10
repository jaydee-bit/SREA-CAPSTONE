// File: traffic_advisory_detail_screen.dart
// Path: mobile_user_app/lib/screens/traffic_advisory_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'traffic_advisories_screen.dart';

class TrafficAdvisoryDetailScreen extends StatelessWidget {
  final TrafficAdvisory advisory;

  const TrafficAdvisoryDetailScreen({super.key, required this.advisory});

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

  String _formatDateRange() {
    if (advisory.effectiveFrom == null && advisory.effectiveTo == null)
      return '';
    if (advisory.effectiveFrom != null && advisory.effectiveTo == null) {
      return 'From ${_formatDate(advisory.effectiveFrom!)}';
    }
    if (advisory.effectiveFrom == null && advisory.effectiveTo != null) {
      return 'Until ${_formatDate(advisory.effectiveTo!)}';
    }
    return '${_formatDate(advisory.effectiveFrom!)} – ${_formatDate(advisory.effectiveTo!)}';
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
          'Traffic Advisory',
          style: SreaText.titleLarge(
            context,
          ).copyWith(color: SreaColors.textOnPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                advisory.title,
                style: SreaText.headlineSmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: SreaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SreaBadge(
                    type: advisory.severity,
                    label: advisory.severity.name.toUpperCase(),
                    showDot: true,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: SreaColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(advisory.publishedAt),
                        style: SreaText.bodySmall(
                          context,
                        ).copyWith(color: SreaColors.textHint),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: SreaColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        advisory.location,
                        style: SreaText.bodySmall(context).copyWith(
                          color: SreaColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_formatDateRange().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: SreaColors.surfaceVariant,
                    borderRadius: SreaRadius.input,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        size: 16,
                        color: SreaColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDateRange(),
                          style: SreaText.bodySmall(
                            context,
                          ).copyWith(color: SreaColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                advisory.description,
                style: SreaText.bodyLarge(
                  context,
                ).copyWith(color: SreaColors.textPrimary, height: 1.6),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.card,
                  border: Border.all(color: SreaColors.border),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Container(
                        height: 180,
                        color: SreaColors.primaryLight,
                        child: const Center(
                          child: Icon(
                            Icons.map_outlined,
                            size: 48,
                            color: SreaColors.primary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: SreaColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Affected area: ${advisory.location}',
                              style: SreaText.bodySmall(context).copyWith(
                                color: SreaColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.phone_in_talk_rounded,
                      size: 20,
                      color: SreaColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'For questions, contact MDRRMO',
                            style: SreaText.bodySmall(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: SreaColors.primary,
                            ),
                          ),
                          Text(
                            '(044) 123-4567',
                            style: SreaText.label(
                              context,
                            ).copyWith(color: SreaColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
