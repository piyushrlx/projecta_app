import 'package:flutter/material.dart';
import '../api_client.dart';
import '../theme.dart';
import '../../models/user_model.dart';
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
    this.unreadNotifications = 0,
  });

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  void _handleCalendarTap(BuildContext context) async {
    Navigator.pop(context);
    final now = DateTime.now();
    await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.royalBlue,
              onPrimary: AppTheme.pureWhite,
              onSurface: AppTheme.deepSlate,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.royalBlue, size: 22),
            const SizedBox(width: 8),
            Text(title, style: AppTheme.heading(fontSize: 16)),
          ],
        ),
        content: Text(
          message,
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.royalBlue, size: 22),
            const SizedBox(width: 8),
            Text('Coming Soon', style: AppTheme.heading(fontSize: 16)),
          ],
        ),
        content: Text(
          '$featureName will be available in the next release.',
          style: AppTheme.body(fontSize: 13, color: AppTheme.mutedSlate),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
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
            // Drawer Header: Projeqta Logo & Admin Executive Branding (Matching Reference Step 3 & 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  const ProjeqtaIcon(size: 38, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.isAdmin ? 'Admin Executive' : 'Staff Executive',
                          style: AppTheme.heading(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepSlate,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Management Portal',
                          style: AppTheme.body(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.mutedSlate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.deepSlate,
                      size: 20,
                    ),
                    tooltip: 'Close Menu',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
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

                  // 2. OPERATIONS SECTION
                  _buildSectionLabel('OPERATIONS'),
                  _buildMenuItem(
                    icon: Icons.assignment_outlined,
                    label: 'Reports',
                    isActive: currentTabIndex == 3,
                    onTap: () {
                      Navigator.pop(context);
                      onTabSelected(3);
                    },
                  ),
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
                  _buildMenuItem(
                    icon: Icons.event_note_outlined,
                    label: 'Attendance & Activities',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showComingSoon(context, 'Attendance & Activities');
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
                  _buildMenuItem(
                    icon: Icons.verified_outlined,
                    label: 'Reporting Compliance',
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      onComplianceTap();
                    },
                  ),

                  const SizedBox(height: 14),

                  // 4. SYSTEM SECTION
                  _buildSectionLabel('SYSTEM'),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isActive: false,
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Settings',
                        'System configurations and workspace settings are managed locally in this app build.',
                      );
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.history_edu_outlined,
                    label: 'Audit Log',
                    isActive: false,
                    onTap: () {
                      _showInfoDialog(
                        context,
                        'Audit Log',
                        'Audit logs record all project updates, submissions, and task management actions.',
                      );
                    },
                  ),
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
                          user.isAdmin ? 'Administrator' : user.fullName,
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
                          'View Profile',
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
