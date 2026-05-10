// File: home_screen.dart
// Path: mobile_user_app/lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/srea_sidebar.dart';
import '../widgets/srea_bottom_nav.dart';
import 'auth/login_screen.dart';
import 'complete_profile_screen.dart';
import 'incident_reports_screen.dart';
import 'profile_screen.dart';
import 'announcements_screen.dart';
import 'announcement_detail_screen.dart';
import 'traffic_advisories_screen.dart';
import 'traffic_advisory_detail_screen.dart';
import 'alerts_screen.dart';
import 'alert_detail_screen.dart';
import 'privacy_policy_screen.dart';
import 'notifications_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // User data from API
  String _userName = '';
  String _email = '';
  String? _profileImageUrl;
  bool _isVerified = false;
  String _role = '';
  String _barangay = '';
  String? _street;
  String? _province;
  String? _municipality;
  String? _validIdPhoto;

  // Data from API
  List<dynamic> _alerts = [];
  List<dynamic> _announcements = [];
  List<dynamic> _traffic = [];
  bool _isLoading = true;
  String? _error;

  // Welcome banner flag – only show once per session
  bool _hasShownWelcome = false;

  final ValueNotifier<int> _unreadCountNotifier = ValueNotifier(0);

  final List<Map<String, String>> _goBagItems = [
    {
      'text':
          'Valid ID, Birth Certificate and other important documents in a waterproof folder.',
    },
    {
      'text':
          '3-day supply of water (1 liter/person/day) and non-perishable food.',
    },
    {'text': 'First aid kit, flashlight, extra batteries, and whistle.'},
    {'text': 'Nearest evacuation center location saved on your phone.'},
    {'text': 'Emergency contact numbers of family, barangay, and MDRRMC.'},
  ];

  bool get _hasCompletedProfile {
    if (_role != 'resident') return false;
    return (_street?.isNotEmpty == true) &&
        (_province?.isNotEmpty == true) &&
        (_municipality?.isNotEmpty == true) &&
        (_validIdPhoto?.isNotEmpty == true);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateUnreadCount();
      NotificationService().addListener(_updateUnreadCount);
    });
  }

  @override
  void dispose() {
    NotificationService().removeListener(_updateUnreadCount);
    _unreadCountNotifier.dispose();
    super.dispose();
  }

  void _updateUnreadCount() {
    _unreadCountNotifier.value = NotificationService().unreadCount;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();

      final user = await api.getUser();
      setState(() {
        _userName = user['name'] ?? '';
        _email = user['email'] ?? '';
        _isVerified = user['is_verified'] ?? false;
        _role = user['role'] ?? '';
        _barangay = user['barangay'] ?? '';
        _street = user['street'];
        _province = user['province'];
        _municipality = user['municipality'];
        _validIdPhoto = user['valid_id_photo'];
        _profileImageUrl = user['profile_image'];
      });

      try {
        final alerts = await api.getAlerts();
        setState(() => _alerts = alerts);
      } catch (e) {
        print('Failed to load alerts: $e');
        setState(() => _alerts = []);
      }

      try {
        final announcements = await api.getAnnouncements();
        setState(() => _announcements = announcements);
      } catch (e) {
        print('Failed to load announcements: $e');
        setState(() => _announcements = []);
      }

      try {
        final traffic = await api.getTrafficAdvisories();
        setState(() => _traffic = traffic);
      } catch (e) {
        print('Failed to load traffic: $e');
        setState(() => _traffic = []);
      }

      setState(() => _isLoading = false);

      if (!_hasShownWelcome && _userName.isNotEmpty) {
        setState(() => _hasShownWelcome = true);
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _hasShownWelcome) {
            setState(() => _hasShownWelcome = false);
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data. Pull to refresh.';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  void _updateProfileImage(String? imagePath) {
    setState(() {
      _profileImageUrl = imagePath;
    });
  }

  void _onBottomNavTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrafficAdvisoriesScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              onProfileImageUpdated: _updateProfileImage,
              onRefreshNeeded: _loadData,
            ),
          ),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
    }
  }

  void _onSidebarNavigate(String route) {
    switch (route) {
      case '/profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              onProfileImageUpdated: _updateProfileImage,
              onRefreshNeeded: _loadData,
            ),
          ),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case '/announcements':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case '/traffic':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrafficAdvisoriesScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case '/incidents':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncidentReportsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case '/alerts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlertsScreen()),
        ).then((_) => setState(() => _currentIndex = 0));
        break;
      case '/privacy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
        );
        break;
      case '/about':
        break;
      default:
        debugPrint('Navigate to $route');
    }
  }

  Future<void> _onLogout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: SreaRadius.modal),
          backgroundColor: SreaColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: SreaColors.primary),
              const SizedBox(height: 16),
              Text(
                'Logging out...',
                style: SreaText.bodySmall(context).copyWith(
                  color: SreaColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final api = ApiService();
      await api.logout();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed. Please try again.'),
            backgroundColor: SreaColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        drawer: SreaSidebar(
          userName: '',
          email: '',
          verificationStatus: '',
          activeRoute: '/home',
          onNavigate: _onSidebarNavigate,
          onLogout: _onLogout,
          profileImageUrl: null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        drawer: SreaSidebar(
          userName: _userName,
          email: _email,
          verificationStatus: '',
          activeRoute: '/home',
          onNavigate: _onSidebarNavigate,
          onLogout: _onLogout,
          profileImageUrl: _profileImageUrl,
        ),
        body: Center(
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
              ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    String verificationStatus = '';
    if (_role == 'resident') {
      if (!_hasCompletedProfile) {
        verificationStatus = 'Unverified';
      } else if (!_isVerified) {
        verificationStatus = 'Pending Verification';
      } else {
        verificationStatus = 'Verified';
      }
    } else if (_role == 'non_resident') {
      verificationStatus = 'Non-Resident';
    }

    final List<Map<String, dynamic>> recentUpdates = [];

    for (var alert in _alerts.take(2)) {
      recentUpdates.add({
        'type': 'alert',
        'title': alert['title'],
        'location': alert['barangay'] ?? 'All barangays',
        'time': _formatDate(alert['created_at']),
        'badgeType': _levelToBadgeType(alert['level']),
        'badgeLabel': alert['level'].toUpperCase(),
        'icon': Icons.warning_amber_rounded,
        'id': alert['id'],
      });
    }
    for (var ann in _announcements.take(2)) {
      recentUpdates.add({
        'type': 'announcement',
        'title': ann['title'],
        'location': ann['barangay'] ?? 'All barangays',
        'time': _formatDate(ann['published_at']),
        'badgeType': null,
        'badgeLabel': null,
        'icon': Icons.campaign_outlined,
        'id': ann['id'],
      });
    }
    for (var traffic in _traffic.take(2)) {
      recentUpdates.add({
        'type': 'traffic',
        'title': traffic['title'],
        'location': traffic['location'],
        'time': _formatDate(traffic['created_at']),
        'badgeType': _severityToBadgeType(traffic['severity']),
        'badgeLabel': traffic['severity'].toUpperCase(),
        'icon': Icons.traffic_outlined,
        'id': traffic['id'],
      });
    }
    recentUpdates.sort((a, b) => b['time'].compareTo(a['time']));

    final bool hasActiveAlert = _alerts.isNotEmpty;
    final String activeAlertLevel = _alerts.isNotEmpty
        ? _alerts.first['level']
        : 'none';

    return Scaffold(
      backgroundColor: SreaColors.background,
      drawer: SreaSidebar(
        userName: _userName,
        email: _email,
        verificationStatus: verificationStatus,
        activeRoute: '/home',
        onNavigate: _onSidebarNavigate,
        onLogout: _onLogout,
        profileImageUrl: _profileImageUrl,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              _SreaAppBar(unreadCountNotifier: _unreadCountNotifier),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_hasShownWelcome) ...[
                        _WelcomeBanner(
                          userName: _userName,
                          onClose: () =>
                              setState(() => _hasShownWelcome = false),
                        ),
                        const SizedBox(height: 16),
                      ],
                      hasActiveAlert
                          ? _ActiveAlertBanner(level: activeAlertLevel)
                          : const SreaAllClearBanner(),
                      const SizedBox(height: 20),

                      if (_role == 'resident') ...[
                        if (!_hasCompletedProfile)
                          _CompleteProfileBanner(onComplete: _loadData),
                        if (_hasCompletedProfile && !_isVerified)
                          const _PendingVerificationBanner(),
                        if (_hasCompletedProfile || !_isVerified)
                          const SizedBox(height: 16),
                      ],

                      _SectionLabel(title: 'Emergency Preparedness'),
                      const SizedBox(height: 10),
                      const _PreparednessBanner(),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SectionLabel(title: 'Recent Updates'),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'See all',
                              style: SreaText.label(context).copyWith(
                                color: SreaColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (recentUpdates.isEmpty)
                        _EmptyAlerts()
                      else
                        Column(
                          children: recentUpdates.map((update) {
                            final badgeWidget = update['badgeType'] != null
                                ? SreaBadge(
                                    type: update['badgeType'] as SreaBadgeType,
                                    label: update['badgeLabel'] as String,
                                  )
                                : const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: SreaAlertCard(
                                title: update['title'] as String,
                                location: update['location'] as String,
                                time: update['time'] as String,
                                icon: update['icon'] as IconData,
                                badge: badgeWidget,
                                onTap: () async {
                                  final type = update['type'] as String;
                                  final id = update['id'] as int;
                                  final api = ApiService();

                                  if (type == 'announcement') {
                                    try {
                                      final data = await api.getAnnouncement(
                                        id,
                                      );
                                      if (!mounted) return;
                                      final announcement = Announcement(
                                        id: data['id'],
                                        title: data['title'] ?? '',
                                        body: data['content'] ?? '',
                                        publishedAt: DateTime.parse(
                                          data['published_at'] ??
                                              DateTime.now().toIso8601String(),
                                        ),
                                        barangay: data['barangay'],
                                        imageUrl: data['image_url'],
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AnnouncementDetailScreen(
                                                announcement: announcement,
                                              ),
                                        ),
                                      );
                                    } catch (e) {
                                      print('Error loading announcement: $e');
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not load announcement',
                                          ),
                                          backgroundColor: SreaColors.error,
                                        ),
                                      );
                                    }
                                  } else if (type == 'traffic') {
                                    try {
                                      final data = await api.getTrafficAdvisory(
                                        id,
                                      );
                                      if (!mounted) return;
                                      final severityMap = {
                                        'high': SreaBadgeType.high,
                                        'medium': SreaBadgeType.medium,
                                        'low': SreaBadgeType.low,
                                      };
                                      final severity =
                                          severityMap[data['severity']] ??
                                          SreaBadgeType.low;
                                      final advisory = TrafficAdvisory(
                                        id: data['id'],
                                        title: data['title'] ?? '',
                                        description: data['description'] ?? '',
                                        location: data['location'] ?? '',
                                        severity: severity,
                                        publishedAt: DateTime.parse(
                                          data['created_at'] ??
                                              DateTime.now().toIso8601String(),
                                        ),
                                        effectiveFrom:
                                            data['effective_from'] != null
                                            ? DateTime.parse(
                                                data['effective_from'],
                                              )
                                            : null,
                                        effectiveTo:
                                            data['effective_to'] != null
                                            ? DateTime.parse(
                                                data['effective_to'],
                                              )
                                            : null,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TrafficAdvisoryDetailScreen(
                                                advisory: advisory,
                                              ),
                                        ),
                                      );
                                    } catch (e) {
                                      print(
                                        'Error loading traffic advisory: $e',
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not load traffic advisory',
                                          ),
                                          backgroundColor: SreaColors.error,
                                        ),
                                      );
                                    }
                                  } else if (type == 'alert') {
                                    try {
                                      final alert = await api.getAlert(id);
                                      if (!mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              AlertDetailScreen(alert: alert),
                                        ),
                                      );
                                    } catch (e) {
                                      print('Error loading alert: $e');
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Could not load alert'),
                                          backgroundColor: SreaColors.error,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),

                      _SectionLabel(title: 'Disaster Preparedness'),
                      const SizedBox(height: 10),
                      _GoBagCard(items: _goBagItems),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SreaBottomNav(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
      floatingActionButton: const SreaEmergencyFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes} minutes ago';
      return 'Just now';
    } catch (e) {
      return 'Recently';
    }
  }

  SreaBadgeType _levelToBadgeType(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return SreaBadgeType.critical;
      case 'high':
        return SreaBadgeType.high;
      case 'medium':
        return SreaBadgeType.medium;
      default:
        return SreaBadgeType.low;
    }
  }

  SreaBadgeType _severityToBadgeType(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return SreaBadgeType.high;
      case 'medium':
        return SreaBadgeType.medium;
      default:
        return SreaBadgeType.low;
    }
  }
}

// ========== APP BAR WITH SREA LOGO ==========
class _SreaAppBar extends StatelessWidget {
  final ValueNotifier<int> unreadCountNotifier;
  const _SreaAppBar({required this.unreadCountNotifier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: SreaColors.primary),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: SreaRadius.input,
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: SreaColors.textOnPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 2,
                ),
                children: const [
                  TextSpan(
                    text: 'SR',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'EA',
                    style: TextStyle(color: Color(0xFFFF3B30)),
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: unreadCountNotifier,
            builder: (context, count, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: SreaColors.textOnPrimary,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: SreaColors.buttonReport,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ========== ONE‑TIME WELCOME BANNER ==========
class _WelcomeBanner extends StatelessWidget {
  final String userName;
  final VoidCallback onClose;
  const _WelcomeBanner({required this.userName, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SreaColors.lowBg,
        borderRadius: SreaRadius.card,
        border: Border.all(color: SreaColors.low.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SreaColors.low.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_rounded, color: SreaColors.low),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${userName.split(' ').first}!',
                  style: SreaText.bodyLarge(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: SreaColors.textPrimary,
                  ),
                ),
                Text(
                  'Thank you for joining SREA. Stay safe and report incidents promptly.',
                  style: SreaText.label(
                    context,
                  ).copyWith(color: SreaColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close,
              size: 18,
              color: SreaColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ========== ACTIVE ALERT BANNER ==========
class _ActiveAlertBanner extends StatelessWidget {
  final String level;
  const _ActiveAlertBanner({required this.level});

  Color get _color {
    switch (level) {
      case 'critical':
        return SreaColors.critical;
      case 'high':
        return SreaColors.high;
      case 'medium':
        return SreaColors.medium;
      default:
        return SreaColors.low;
    }
  }

  Color get _bgColor {
    switch (level) {
      case 'critical':
        return SreaColors.criticalBg;
      case 'high':
        return SreaColors.highBg;
      case 'medium':
        return SreaColors.mediumBg;
      default:
        return SreaColors.lowBg;
    }
  }

  String get _message {
    switch (level) {
      case 'critical':
        return 'Critical alert active in your area!';
      case 'high':
        return 'High-risk alert in your area';
      case 'medium':
        return 'Advisory issued for your area';
      default:
        return 'Low-level alert in your area';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SreaSpacing.cardPaddingSmall(context),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: SreaRadius.card,
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: _color, size: 20),
          ),
          SizedBox(width: SreaSpacing.iconGap(context)),
          Expanded(
            child: Text(
              _message,
              style: SreaText.bodySmall(
                context,
              ).copyWith(color: _color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== SECTION LABEL ==========
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: SreaText.bodySmall(context).copyWith(
        color: SreaColors.textSecondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ========== EMPTY ALERTS ==========
class _EmptyAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SreaSpacing.cardPadding(context),
      decoration: BoxDecoration(
        color: SreaColors.surface,
        borderRadius: SreaRadius.card,
        border: Border.all(color: SreaColors.divider),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: SreaColors.low,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No recent updates',
              style: SreaText.bodySmall(
                context,
              ).copyWith(color: SreaColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== PREPAREDNESS BANNER ==========
class _PreparednessBanner extends StatelessWidget {
  const _PreparednessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: SreaSpacing.cardPadding(context),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [SreaColors.primaryDark, SreaColors.primary],
        ),
        borderRadius: SreaRadius.card,
        boxShadow: [
          BoxShadow(
            color: SreaColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.safety_check_rounded,
                color: SreaColors.textOnPrimary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Be Ready, Be Safe',
                  style: SreaText.titleLarge(context).copyWith(
                    color: SreaColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Always have your go‑bag ready\n'
            '• Know your barangay evacuation center\n'
            '• Save emergency contacts: MDRRMO, Barangay, NDRRMC\n'
            '• Monitor official weather updates from PAGASA\n'
            '• Stay tuned to SREA alerts for real‑time information',
            style: SreaText.bodySmall(
              context,
            ).copyWith(color: SreaColors.textOnPrimary, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: SreaRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 14,
                  color: SreaColors.textOnPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Emergency Hotline: (044) 123-4567',
                  style: SreaText.label(context).copyWith(
                    color: SreaColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== COMPLETE PROFILE BANNER (with callback) ==========
class _CompleteProfileBanner extends StatelessWidget {
  final VoidCallback onComplete;
  const _CompleteProfileBanner({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SreaSpacing.cardPaddingSmall(context),
      decoration: BoxDecoration(
        color: SreaColors.primaryLight,
        borderRadius: SreaRadius.card,
        border: Border.all(color: SreaColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_document, color: SreaColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get verified',
                  style: SreaText.bodySmall(context).copyWith(
                    color: SreaColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Verified reports are prioritized by MDRRMO. Complete your profile to increase credibility.',
                  style: SreaText.label(
                    context,
                  ).copyWith(color: SreaColors.primary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompleteProfileScreen(),
                ),
              );
              if (result == true) {
                onComplete();
              }
            },
            child: Text(
              'Verify now',
              style: SreaText.label(context).copyWith(
                color: SreaColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== PENDING VERIFICATION BANNER ==========
class _PendingVerificationBanner extends StatelessWidget {
  const _PendingVerificationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: SreaSpacing.cardPaddingSmall(context),
      decoration: BoxDecoration(
        color: SreaColors.mediumBg,
        borderRadius: SreaRadius.card,
        border: Border.all(color: SreaColors.medium.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: SreaColors.medium,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification pending',
                  style: SreaText.bodySmall(context).copyWith(
                    color: SreaColors.medium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Your account is under review. You\'ll be notified when approved.',
                  style: SreaText.label(
                    context,
                  ).copyWith(color: SreaColors.medium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========== GO-BAG CARD ==========
class _GoBagCard extends StatelessWidget {
  final List<Map<String, String>> items;
  const _GoBagCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return SreaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: const Icon(
                  Icons.backpack_outlined,
                  color: SreaColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: SreaSpacing.iconGap(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Go-Bag Checklist',
                      style: SreaText.bodyLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                        color: SreaColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Be ready in case of evacuation',
                      style: SreaText.label(
                        context,
                      ).copyWith(color: SreaColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: SreaColors.divider, height: 1),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < items.length - 1 ? 10 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.input,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: SreaColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: SreaText.label(context).copyWith(
                            color: SreaColors.textOnPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: SreaSpacing.iconGap(context)),
                    Expanded(
                      child: Text(
                        item['text']!,
                        style: SreaText.bodySmall(
                          context,
                        ).copyWith(color: SreaColors.textPrimary, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
