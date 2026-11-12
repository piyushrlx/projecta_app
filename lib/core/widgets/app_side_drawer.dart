import 'dart:async';
import 'package:flutter/material.dart';
import '../api_client.dart';
import '../company_settings.dart';
import '../theme.dart';
import '../../models/user_model.dart';
import '../../screens/analytics/analytics_hub_screen.dart';
import '../../screens/audit/audit_log_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/contact/contact_messages_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/reports/report_submission_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/team/departments_screen.dart';
import 'projeqta_logo.dart';

class AppSideDrawer extends StatelessWidget {
  final UserModel user;
  final int currentTabIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onLogout;
  final VoidCallback onComplianceTap;
  final VoidCallback onFilterTap;
  final VoidCallback onTeamListTap;
  final void Function(int initialTab)? onTeamSubTabTap;
  final VoidCallback onOverdueTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onApprovalsTap;
  final VoidCallback? onDepartmentsTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSubmitReportTap;
  final int unreadNotifications;

  const AppSideDrawer({
    super.key,
    required this.user,
    required this.currentTabIndex,
    required this.onTabSelected,
    required this.onLogout,
    required this.onComplianceTap,
    required this.onFilterTap,
    required this.onTeamListTap,
    this.onTeamSubTabTap,
    required this.onOverdueTap,
    required this.onNotificationsTap,
    required this.onApprovalsTap,
    this.onDepartmentsTap,
    this.onProfileTap,
    this.onSubmitReportTap,
    this.unreadNotifications = 0,
  });

  void _openProfile(BuildContext context) {
    Navigator.pop(context);
    if (onProfileTap != null) {
      onProfileTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
      );
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  void _handleCalendarTap(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CalendarScreen(currentUser: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.pureWhite,
      elevation: 16,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header: Full Company Logo Banner with Company Name Below (Matching Website Sidebar)
            AnimatedBuilder(
              animation: CompanySettings.instance,
              builder: (context, _) {
                final companySettings = CompanySettings.instance;
                final companyName = companySettings.companyName;
                final logoUrl = companySettings.logoUrl;
                final resolvedLogoUrl = ApiClient().resolveMediaUrl(logoUrl);

                if (resolvedLogoUrl != null &&
                    resolvedLogoUrl.isNotEmpty &&
                    companySettings.logoBytes == null) {
                  unawaited(companySettings.ensureLogoCached(resolvedLogoUrl));
                }

                return Container(
                  color: const Color(0xFF0F172A),
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Prominent full company logo + Close button [X]
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: companySettings.decodedLogo != null
                                ? Align(
                                    alignment: Alignment.centerLeft,
                                    child: RawImage(
                                      image: companySettings.decodedLogo,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                : companySettings.logoBytes != null
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: Image.memory(
                                          companySettings.logoBytes!,
                                          height: 32,
                                          fit: BoxFit.contain,
                                          gaplessPlayback: true,
                                          cacheHeight: (36 *
                                                  MediaQuery.of(context)
                                                      .devicePixelRatio)
                                              .round()
                                              .clamp(72, 216),
                                        ),
                                      )
                                    : (resolvedLogoUrl != null &&
                                            resolvedLogoUrl.isNotEmpty)
                                        ? Align(
                                            alignment: Alignment.centerLeft,
                                            child: Image.network(
                                              resolvedLogoUrl,
                                              height: 32,
                                              fit: BoxFit.contain,
                                              gaplessPlayback: true,
                                              cacheHeight: (36 *
                                                      MediaQuery.of(context)
                                                          .devicePixelRatio)
                                                  .round()
                                                  .clamp(72, 216),
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const ProjeqtaLogo(
                                                iconSize: 26,
                                                isDark: true,
                                              ),
                                            ),
                                          )
                                        : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ProjeqtaIcon(size: 28, borderRadius: 7),
                                        SizedBox(width: 8),
                                        Text(
                                          'projeqta',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                            tooltip: 'Close Menu',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Crisp dividing line separating logo from company details
                      Container(
                        height: 1,
                        color: const Color(0xFF1E293B),
                      ),
                      const SizedBox(height: 6),

                      // Company Name below the line
                      Text(
                        companyName.isNotEmpty
                            ? companyName
                            : (user.isAdmin
                                  ? 'Admin Executive'
                                  : 'Staff Executive'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // User role / Portal subtitle
                      Text(
                        user.isAdmin ? 'Admin Executive' : 'Staff Executive',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(
              color: AppTheme.borderSubtle,
              height: 1,
              thickness: 1,
            ),

            // Scrollable Navigation List (Grouped Progressive Disclosure)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                children: [
                  // 1. WORKSPACE SECTION
                  _buildSectionLabel('WORKSPACE'),
                  _buildMenuItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard / Pulse',
                    isActive: currentTabIndex == 0,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(0);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.check_box_outlined,
                    label: 'Tasks',
                    isActive: currentTabIndex == 1,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(1);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.folder_outlined,
                    label: 'Projects',
                    isActive: currentTabIndex == 2,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(2);
                    },
                  ),

                  // Team Management — Expandable (Admin / Super Admin only)
                  if (user.isAdmin)
                    _buildExpandableMenuItem(
                      context,
                      icon: Icons.people_outline,
                      label: 'Team Management',
                      children: [
                        _buildSubMenuItem(
                          'Team List',
                          Icons.list_alt_outlined,
                          () {
                            Navigator.pop(context);
                            onTeamListTap();
                          },
                        ),
                        _buildSubMenuItem(
                          'Assign Roles',
                          Icons.admin_panel_settings_outlined,
                          () {
                            Navigator.pop(context);
                            if (onTeamSubTabTap != null) {
                              onTeamSubTabTap!(1);
                            } else {
                              onTeamListTap();
                            }
                          },
                        ),
                        _buildSubMenuItem(
                          'Performance',
                          Icons.bar_chart_outlined,
                          () {
                            Navigator.pop(context);
                            if (onTeamSubTabTap != null) {
                              onTeamSubTabTap!(2);
                            } else {
                              onTeamListTap();
                            }
                          },
                        ),
                        _buildSubMenuItem(
                          'Team Reports',
                          Icons.assignment_outlined,
                          () {
                            Navigator.pop(context);
                            onTabSelected(3);
                          },
                        ),
                        _buildSubMenuItem(
                          'Departments',
                          Icons.domain_outlined,
                          () {
                            Navigator.pop(context);
                            if (onDepartmentsTap != null) {
                              onDepartmentsTap!();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DepartmentsScreen(),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // 2. OPERATIONS SECTION (REPORTING FOR STAFF)
                  _buildSectionLabel(user.isAdmin ? 'OPERATIONS' : 'REPORTING'),
                  if (!user.isAdmin)
                    _buildMenuItem(
                      icon: Icons.add_comment_outlined,
                      label: 'Submit Daily Report',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        if (onSubmitReportTap != null) {
                          onSubmitReportTap!();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportSubmissionScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.assignment_outlined,
                    label: user.isAdmin ? 'Reports' : 'Daily Reports',
                    isActive: currentTabIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(3);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.analytics_outlined,
                    label: 'Reports & Analytics',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnalyticsHubScreen(currentUser: user),
                        ),
                      );
                    },
                  ),
                  if (user.isAdmin)
                    _buildMenuItem(
                      icon: Icons.fact_check_outlined,
                      label: 'Approvals',
                      isActive: false,
                      badgeText: '7',
                      badgeColor: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(context);
                        onApprovalsTap();
                      },
                    ),
                  if (user.isAdmin)
                    _buildMenuItem(
                      icon: Icons.event_note_outlined,
                      label: 'Attendance & Activities',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        onTabSelected(3);
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Calendar',
                    isActive: false,
                    onTap: () => _handleCalendarTap(context),
                  ),

                  const SizedBox(height: 14),

                  // 3. MONITORING SECTION
                  _buildSectionLabel('MONITORING'),
                  if (user.isAdmin)
                    _buildMenuItem(
                      icon: Icons.warning_amber_outlined,
                      label: 'Risks & Alerts',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        onTabSelected(0);
                      },
                    ),
                  _buildMenuItem(
                    icon: Icons.history_toggle_off_outlined,
                    label: 'Overdue Backlog',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      onOverdueTap();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    isActive: false,
                    badgeText: unreadNotifications > 0
                        ? (unreadNotifications > 99
                              ? '99+'
                              : unreadNotifications.toString())
                        : null,
                    badgeColor: AppTheme.dangerText,
                    onTap: () {
                      Navigator.pop(context);
                      onNotificationsTap();
                    },
                  ),
                  if (user.isAdmin)
                    _buildMenuItem(
                      icon: Icons.verified_outlined,
                      label: 'Reporting Compliance',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        onComplianceTap();
                      },
                    ),

                  if (user.isAdmin || user.isSuperAdmin) ...[
                    const SizedBox(height: 14),

                    // 4. SYSTEM SECTION
                    _buildSectionLabel('SYSTEM'),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettingsScreen(currentUser: user),
                          ),
                        );
                      },
                    ),
                    _buildMenuItem(
                      icon: Icons.history_edu_outlined,
                      label: 'Audit Log',
                      isActive: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuditLogScreen(currentUser: user),
                          ),
                        );
                      },
                    ),
                    if (user.isSuperAdmin)
                      _buildMenuItem(
                        icon: Icons.mark_email_unread_outlined,
                        label: 'Contact Messages',
                        isActive: false,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ContactMessagesScreen(currentUser: user),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),

            const Divider(
              color: AppTheme.borderSubtle,
              height: 1,
              thickness: 1,
            ),

            // Drawer Footer: User Profile + Logout (Matching Reference Step 3 & 4)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  // Clickable User Profile Area
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openProfile(context),
                      child: Row(
                        children: [
                          // Avatar with initials fallback
                          _buildUserAvatar(),
                          const SizedBox(width: 12),
                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user.fullName.isNotEmpty
                                      ? user.fullName
                                      : (user.isAdmin
                                            ? 'Administrator'
                                            : 'Staff'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.heading(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.deepSlate,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.roleLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.mutedSlate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Logout Action
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.mutedSlate,
                      size: 20,
                    ),
                    tooltip: 'Sign Out',
                    onPressed: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: AppTheme.deepSlate, size: 20),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.deepSlate,
          ),
        ),
        iconColor: AppTheme.deepSlate,
        collapsedIconColor: AppTheme.mutedSlate,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        children: children,
      ),
    );
  }

  Widget _buildSubMenuItem(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 44, right: 12),
      leading: Icon(icon, color: AppTheme.mutedSlate, size: 17),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.deepSlate,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildUserAvatar() {
    final photoUrl = ApiClient().resolveMediaUrl(user.profilePhotoUrl);
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          photoUrl,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 120,
          cacheHeight: 120,
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsFallback(),
        ),
      );
    }
    return _buildInitialsFallback();
  }

  Widget _buildInitialsFallback() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Center(
        child: Text(
          _getInitials(user.fullName),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.pureWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isActive ? const Color(0xFFEEF2FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 0,
          ),
          leading: Icon(
            icon,
            color: isActive ? AppTheme.royalBlue : AppTheme.deepSlate,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? AppTheme.royalBlue : AppTheme.deepSlate,
            ),
          ),
          trailing: badgeText != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppTheme.royalBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                )
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
