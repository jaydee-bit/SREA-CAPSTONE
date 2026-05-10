// File: onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srea_shared/srea_shared.dart';
import 'auth/login_screen.dart';

class SreaApp extends StatelessWidget {
  const SreaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SREA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: SreaColors.background,
        fontFamily: 'PlusJakartaSans',
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the same key as in main.dart
    final seen = prefs.getBool('hasSeenOnboarding') ?? false;
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => seen ? const LoginScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: SreaColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: SreaColors.textOnPrimary),
      ),
    );
  }
}

enum _PageType { welcome, feature }

class _OnboardingPage {
  final _PageType type;
  final String title;
  final String subtitle;
  final String description;
  final IconData? icon;
  final Color? iconBgColor;
  final Color? iconColor;
  const _OnboardingPage({
    required this.type,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.icon,
    this.iconBgColor,
    this.iconColor,
  });
}

const List<_OnboardingPage> _pages = [
  _OnboardingPage(
    type: _PageType.welcome,
    title: 'SREA',
    subtitle: 'San Rafael Emergency Alert',
    description:
        'Your community\'s safety companion.\nAlways ready, always with you.',
  ),
  _OnboardingPage(
    type: _PageType.feature,
    title: 'Stay Alert,\nStay Safe',
    subtitle: 'Real-time emergency alerts',
    description:
        'Receive instant notifications for floods, fires, and emergencies in San Rafael, Bulacan — before it\'s too late.',
    icon: Icons.notifications_active_rounded,
    iconBgColor: SreaColors.primaryLight,
    iconColor: SreaColors.primary,
  ),
  _OnboardingPage(
    type: _PageType.feature,
    title: 'Report\nIncidents Fast',
    subtitle: 'Be the first to report',
    description:
        'Spotted a hazard? Submit an incident report directly to local authorities in seconds. Your report can save lives.',
    icon: Icons.report_rounded,
    iconBgColor: Color(0xFFFFEDEC),
    iconColor: SreaColors.buttonReport,
  ),
  _OnboardingPage(
    type: _PageType.feature,
    title: 'Prepared for\nAny Disaster',
    subtitle: 'Know what to do',
    description:
        'Access evacuation routes, go-bag checklists, and emergency contacts for your barangay — all in one place.',
    icon: Icons.health_and_safety_rounded,
    iconBgColor: Color(0xFFEAF9EE),
    iconColor: SreaColors.buttonUpdate,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndGoToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    // Use the same key as in main.dart
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _markSeenAndGoToLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final isWelcome = _pages[_currentPage].type == _PageType.welcome;

    return Scaffold(
      backgroundColor: isWelcome ? SreaColors.primary : SreaColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: GestureDetector(
                    onTap: _markSeenAndGoToLogin,
                    child: Text(
                      'Skip',
                      style: SreaText.bodySmall(context).copyWith(
                        color: isWelcome
                            ? SreaColors.bottomNavInactive
                            : SreaColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) {
                  final page = _pages[i];
                  return page.type == _PageType.welcome
                      ? _WelcomePage(page: page)
                      : _FeaturePage(page: page);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => _DotIndicator(
                        isActive: i == _currentPage,
                        isOnDark: isWelcome,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SreaButton(
                    label: isLast ? 'Get Started' : 'Next',
                    onPressed: _nextPage,
                    fullWidth: true,
                    size: SreaButtonSize.large,
                    icon: isLast ? Icons.arrow_forward_rounded : null,
                    type: isWelcome
                        ? SreaButtonType.outline
                        : SreaButtonType.primary,
                  ),
                  if (!isLast) ...[
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _markSeenAndGoToLogin,
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account?  ',
                          style: SreaText.bodySmall(context).copyWith(
                            color: isWelcome
                                ? SreaColors.bottomNavInactive
                                : SreaColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Login',
                              style: SreaText.bodySmall(context).copyWith(
                                color: isWelcome
                                    ? Colors.white
                                    : SreaColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatefulWidget {
  final _OnboardingPage page;
  const _WelcomePage({required this.page});

  @override
  State<_WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<_WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.montserrat(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 4,
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
              const SizedBox(height: 8),
              Text(
                widget.page.subtitle,
                style: SreaText.label(context).copyWith(
                  color: SreaColors.bottomNavInactive,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                height: 1,
                width: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 32),
              Text(
                widget.page.description,
                style: SreaText.bodyLarge(
                  context,
                ).copyWith(color: SreaColors.bottomNavInactive, height: 1.7),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePage extends StatefulWidget {
  final _OnboardingPage page;
  const _FeaturePage({required this.page});

  @override
  State<_FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<_FeaturePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 148,
                height: 148,
                decoration: BoxDecoration(
                  color: widget.page.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.page.icon,
                  size: 72,
                  color: widget.page.iconColor,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: SreaColors.primaryLight,
                  borderRadius: SreaRadius.pill,
                ),
                child: Text(
                  widget.page.subtitle,
                  style: SreaText.label(context).copyWith(
                    color: SreaColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.page.title,
                style: SreaText.headlineSmall(context).copyWith(
                  color: SreaColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                widget.page.description,
                style: SreaText.bodyLarge(
                  context,
                ).copyWith(color: SreaColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  final bool isOnDark;
  const _DotIndicator({required this.isActive, this.isOnDark = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? (isOnDark ? Colors.white : SreaColors.primary)
            : (isOnDark ? Colors.white.withOpacity(0.35) : SreaColors.border),
        borderRadius: SreaRadius.pill,
      ),
    );
  }
}
