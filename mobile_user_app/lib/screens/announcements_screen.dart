// File: announcements_screen.dart
// Path: mobile_user_app/lib/screens/announcements_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../services/api_service.dart';
import 'announcement_detail_screen.dart';

// ========== Announcement Model ==========
class Announcement {
  final int id;
  final String title;
  final String body;
  final DateTime publishedAt;
  final String? barangay;
  final String? imageUrl;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.barangay,
    this.imageUrl,
  });

  bool get isGeneral => barangay == null;

  String get formattedDate {
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
    return '${months[publishedAt.month - 1]} ${publishedAt.day}, ${publishedAt.year}';
  }
}

// ========== Screen ==========
class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final data = await api.getAnnouncements();
      if (!mounted) return;
      final List<Announcement> loaded = data.map((json) {
        return Announcement(
          id: json['id'],
          title: json['title'] ?? '',
          body: json['content'] ?? '',
          publishedAt: DateTime.parse(
            json['published_at'] ?? DateTime.now().toIso8601String(),
          ),
          barangay: json['barangay'],
          imageUrl: json['image_url'],
        );
      }).toList();
      setState(() {
        _announcements = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load announcements. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadAnnouncements();
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
          'Announcements',
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
                      onPressed: _loadAnnouncements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _announcements.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 64,
                      color: SreaColors.textHint,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No announcements',
                      style: SreaText.bodyLarge(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _announcements.length,
                itemBuilder: (context, index) {
                  final ann = _announcements[index];
                  final isBarangaySpecific = !ann.isGeneral;
                  final preview = ann.body.length > 120
                      ? '${ann.body.substring(0, 120)}...'
                      : ann.body;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SreaCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AnnouncementDetailScreen(announcement: ann),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ann.imageUrl != null &&
                              ann.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                SreaRadius.md,
                              ),
                              child: Image.network(
                                ann.imageUrl!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            ann.title,
                            style: SreaText.bodyLarge(context).copyWith(
                              fontWeight: FontWeight.w700,
                              color: SreaColors.textPrimary,
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
                                ann.formattedDate,
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
                                  ann.barangay!,
                                  style: SreaText.label(
                                    context,
                                  ).copyWith(color: SreaColors.primary),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            preview,
                            style: SreaText.bodySmall(context).copyWith(
                              color: SreaColors.textSecondary,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Read more →',
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
