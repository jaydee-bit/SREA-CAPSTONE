// File: srea_sidebar.dart
// Path: mobile_user_app/lib/widgets/srea_sidebar.dart

import 'package:flutter/material.dart';
import 'package:srea_shared/srea_shared.dart';
import '../screens/about_screen.dart';
import '../services/api_service.dart';

class SreaSidebar extends StatelessWidget {
  final String userName;
  final String email;
  final String verificationStatus;
  final String activeRoute;
  final void Function(String route) onNavigate;
  final VoidCallback onLogout;
  final String? profileImageUrl;

  const SreaSidebar({
    super.key,
    required this.userName,
    required this.email,
    required this.verificationStatus,
    this.activeRoute = '/home',
    required this.onNavigate,
    required this.onLogout,
    this.profileImageUrl,
  });

  String? _getFullImageUrl() {
    final api = ApiService();
    return api.getFullImageUrl(profileImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final fullImageUrl = _getFullImageUrl();

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.80,
      backgroundColor: SreaColors.primary,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                SreaSpacing.lg(context),
                SreaSpacing.xl(context),
                SreaSpacing.lg(context),
                SreaSpacing.lg(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: SreaColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: fullImageUrl != null && fullImageUrl.isNotEmpty
                          ? Image.network(
                              fullImageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_outline_rounded,
                                size: 38,
                                color: SreaColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline_rounded,
                              size: 38,
                              color: SreaColors.primary,
                            ),
                    ),
                  ),
                  SizedBox(height: SreaSpacing.md(context)),
                  Text(
                    userName,
                    style: SreaText.titleLarge(context).copyWith(
                      color: SreaColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: SreaSpacing.xs(context)),
                  Text(
                    email,
                    style: SreaText.bodySmall(
                      context,
                    ).copyWith(color: SreaColors.bottomNavInactive),
                  ),
                  SizedBox(height: SreaSpacing.sm(context)),
                  _buildStatusBadge(context),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.15)),
            SizedBox(height: SreaSpacing.sm(context)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: SreaSpacing.sm(context),
                  vertical: SreaSpacing.sm(context),
                ),
                children: [
                  _SidebarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    route: '/home',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.warning_amber_outlined,
                    activeIcon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    route: '/alerts',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.campaign_outlined,
                    activeIcon: Icons.campaign_rounded,
                    label: 'Announcements',
                    route: '/announcements',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.traffic_outlined,
                    activeIcon: Icons.traffic_rounded,
                    label: 'Traffic Advisories',
                    route: '/traffic',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.report_outlined,
                    activeIcon: Icons.report_rounded,
                    label: 'Incident Reports',
                    route: '/incidents',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    route: '/profile',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  SizedBox(height: SreaSpacing.sm(context)),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  SizedBox(height: SreaSpacing.sm(context)),
                  _SidebarItem(
                    icon: Icons.privacy_tip_outlined,
                    activeIcon: Icons.privacy_tip_rounded,
                    label: 'Privacy Policy',
                    route: '/privacy',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                  _SidebarItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups_rounded,
                    label: 'About Us',
                    route: '/about',
                    activeRoute: activeRoute,
                    onTap: onNavigate,
                  ),
                ],
              ),
            ),
            Container(height: 1, color: Colors.white.withOpacity(0.15)),
            Padding(
              padding: EdgeInsets.all(SreaSpacing.sm(context)),
              child: _SidebarLogoutButton(onLogout: onLogout),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (verificationStatus) {
      case 'Verified':
        bgColor = Colors.white;
        textColor = SreaColors.primary;
        icon = Icons.verified_rounded;
        label = 'Verified';
        break;
      case 'Pending Verification':
        bgColor = Colors.white.withOpacity(0.15);
        textColor = SreaColors.textOnPrimary;
        icon = Icons.pending_outlined;
        label = 'Pending Verification';
        break;
      case 'Unverified':
        bgColor = Colors.white.withOpacity(0.15);
        textColor = SreaColors.textOnPrimary;
        icon = Icons.error_outline_rounded;
        label = 'Unverified';
        break;
      case 'Non-Resident':
        bgColor = Colors.white.withOpacity(0.15);
        textColor = SreaColors.textOnPrimary;
        icon = Icons.location_city_outlined;
        label = 'Non-Resident';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SreaSpacing.sm(context),
        vertical: SreaSpacing.xs(context),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SreaRadius.pill,
        border: (verificationStatus != 'Verified')
            ? Border.all(color: Colors.white.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: SreaSpacing.xs(context)),
          Text(
            label,
            style: SreaText.label(
              context,
            ).copyWith(color: textColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final String activeRoute;
  final void Function(String) onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.activeRoute,
    required this.onTap,
  });

  bool get _isActive => activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: SreaSpacing.xs(context)),
      child: Material(
        color: _isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: SreaRadius.input,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            if (route == '/about') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            } else {
              onTap(route);
            }
          },
          borderRadius: SreaRadius.input,
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SreaSpacing.md(context),
              vertical: SreaSpacing.sm(context),
            ),
            child: Row(
              children: [
                Icon(
                  _isActive ? activeIcon : icon,
                  color: _isActive
                      ? SreaColors.textOnPrimary
                      : SreaColors.bottomNavInactive,
                  size: 22,
                ),
                SizedBox(width: SreaSpacing.avatarGap(context)),
                Text(
                  label,
                  style: SreaText.bodySmall(context).copyWith(
                    color: _isActive
                        ? SreaColors.textOnPrimary
                        : SreaColors.bottomNavInactive,
                    fontWeight: _isActive ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (_isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: SreaColors.textOnPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogoutButton extends StatelessWidget {
  final VoidCallback onLogout;
  const _SidebarLogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: SreaRadius.input,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onLogout();
        },
        borderRadius: SreaRadius.input,
        splashColor: SreaColors.error.withOpacity(0.2),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SreaSpacing.md(context),
            vertical: SreaSpacing.sm(context),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: SreaColors.textOnPrimary,
                size: 22,
              ),
              SizedBox(width: SreaSpacing.avatarGap(context)),
              Text(
                'Log out',
                style: SreaText.bodySmall(context).copyWith(
                  color: SreaColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
