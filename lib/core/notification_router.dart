import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/projects/projects_list_screen.dart';
import '../screens/team/employee_detail_screen.dart';
import '../screens/team/team_list_screen.dart';
import '../screens/reports/report_submission_screen.dart';
import '../screens/reports/reports_list_screen.dart';

enum NotificationRouteTarget {
  taskDetail,
  tasksList,
  projectDetail,
  projectsList,
  employeeDetail,
  teamList,
  reportSubmission,
  reportsList,
  dashboard,
  none,
}

class NotificationRouteInfo {
  final NotificationRouteTarget target;
  final int? entityId;
  final String? date;
  final String? initialFilter;
  final String? initialViewMode;

  const NotificationRouteInfo({
    required this.target,
    this.entityId,
    this.date,
    this.initialFilter,
    this.initialViewMode,
  });
}

class NotificationRouter {
  /// Parses a NotificationModel into a resolved route target and arguments.
  static NotificationRouteInfo parse(NotificationModel notification) {
    final rawLink = notification.link?.trim() ?? '';
    final type = notification.type.toLowerCase();

    // 1. Check direct URL patterns in rawLink
    if (rawLink.isNotEmpty) {
      final cleanLink = rawLink.split('#').first; // strip URL fragment like #milestones
      final uri = Uri.tryParse(cleanLink);
      final path = uri?.path.toLowerCase() ?? cleanLink.toLowerCase();

      // Extract query parameters
      int? queryId;
      String? queryDate;
      if (uri != null && uri.queryParameters.isNotEmpty) {
        if (uri.queryParameters.containsKey('id')) {
          queryId = int.tryParse(uri.queryParameters['id']!);
        }
        if (uri.queryParameters.containsKey('date')) {
          queryDate = uri.queryParameters['date'];
        }
      }

      // Fallback regex for query id
      if (queryId == null) {
        final m = RegExp(r'[?&]id=(\d+)').firstMatch(cleanLink);
        if (m != null) {
          queryId = int.tryParse(m.group(1)!);
        }
      }

      // Fallback regex for path /tasks/123, /projects/45, /employees/7
      if (queryId == null) {
        final m = RegExp(r'/(?:tasks|projects|employees)/(\d+)').firstMatch(cleanLink);
        if (m != null) {
          queryId = int.tryParse(m.group(1)!);
        }
      }

      // Check task-details.php or /tasks/
      if (path.contains('task-details') || path.contains('tasks/')) {
        if (queryId != null) {
          return NotificationRouteInfo(
            target: NotificationRouteTarget.taskDetail,
            entityId: queryId,
          );
        }
        return const NotificationRouteInfo(target: NotificationRouteTarget.tasksList);
      }

      // Check tasks.php
      if (path.contains('tasks.php') || path == '/tasks') {
        return const NotificationRouteInfo(target: NotificationRouteTarget.tasksList);
      }

      // Check project-details.php or /projects/
      if (path.contains('project-details') || path.contains('projects/')) {
        if (queryId != null) {
          return NotificationRouteInfo(
            target: NotificationRouteTarget.projectDetail,
            entityId: queryId,
          );
        }
        return const NotificationRouteInfo(target: NotificationRouteTarget.projectsList);
      }

      // Check projects.php
      if (path.contains('projects.php') || path == '/projects') {
        return const NotificationRouteInfo(target: NotificationRouteTarget.projectsList);
      }

      // Check employee-details.php or /employees/
      if (path.contains('employee-details') || path.contains('employees/')) {
        if (queryId != null) {
          return NotificationRouteInfo(
            target: NotificationRouteTarget.employeeDetail,
            entityId: queryId,
          );
        }
        return const NotificationRouteInfo(target: NotificationRouteTarget.teamList);
      }

      // Check submit-report.php or daily-reports.php
      if (path.contains('submit-report') || path.contains('daily-reports')) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.reportSubmission,
          date: queryDate,
        );
      }

      // Check compliance.php
      if (path.contains('compliance.php') || path.contains('compliance')) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.reportsList,
          date: queryDate,
          initialViewMode: 'compliance',
        );
      }

      // Check reports.php or report-details.php or /reports/
      if (path.contains('reports.php') ||
          path.contains('report-details') ||
          path.contains('reports')) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.reportsList,
          entityId: queryId,
          date: queryDate,
          initialViewMode: 'inbox',
        );
      }

      // Check dashboard.php
      if (path.contains('dashboard.php') || path == '/dashboard') {
        return const NotificationRouteInfo(target: NotificationRouteTarget.dashboard);
      }
    }

    // 2. Intelligent fallback based on notification.type
    final extractedId = notification.targetEntityId;

    if (type.contains('task') ||
        type.contains('extension') ||
        type == 'deadline_reminder' ||
        type == 'overdue' ||
        type == 'stale_task') {
      if (extractedId != null) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.taskDetail,
          entityId: extractedId,
        );
      }
      return const NotificationRouteInfo(target: NotificationRouteTarget.tasksList);
    }

    if (type.contains('project')) {
      if (extractedId != null) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.projectDetail,
          entityId: extractedId,
        );
      }
      return const NotificationRouteInfo(target: NotificationRouteTarget.projectsList);
    }

    if (type == 'report_missing') {
      return const NotificationRouteInfo(target: NotificationRouteTarget.reportSubmission);
    }

    if (type.contains('report') || type == 'compliance_alert') {
      return const NotificationRouteInfo(
        target: NotificationRouteTarget.reportsList,
        initialViewMode: 'inbox',
      );
    }

    if (type == 'comment' || type == 'mention') {
      final combined = '${notification.title} ${notification.message}'.toLowerCase();
      if (combined.contains('task')) {
        return const NotificationRouteInfo(target: NotificationRouteTarget.tasksList);
      }
      if (combined.contains('report')) {
        return const NotificationRouteInfo(
          target: NotificationRouteTarget.reportsList,
          initialViewMode: 'inbox',
        );
      }
      return const NotificationRouteInfo(target: NotificationRouteTarget.projectsList);
    }

    if (type == 'registration' ||
        type == 'account_activated' ||
        type == 'password_reset' ||
        type == 'exemption_added') {
      if (extractedId != null) {
        return NotificationRouteInfo(
          target: NotificationRouteTarget.employeeDetail,
          entityId: extractedId,
        );
      }
      return const NotificationRouteInfo(target: NotificationRouteTarget.teamList);
    }

    return const NotificationRouteInfo(target: NotificationRouteTarget.none);
  }

  /// Executes navigation for the parsed notification. Returns true if navigated.
  static Future<bool> navigate(
    BuildContext context,
    NotificationModel notification, {
    UserModel? user,
  }) async {
    final routeInfo = parse(notification);

    switch (routeInfo.target) {
      case NotificationRouteTarget.taskDetail:
        if (routeInfo.entityId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(taskId: routeInfo.entityId!),
            ),
          );
          return true;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasksScreen()),
        );
        return true;

      case NotificationRouteTarget.tasksList:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TasksScreen()),
        );
        return true;

      case NotificationRouteTarget.projectDetail:
        if (routeInfo.entityId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: routeInfo.entityId!),
            ),
          );
          return true;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectsListScreen()),
        );
        return true;

      case NotificationRouteTarget.projectsList:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProjectsListScreen()),
        );
        return true;

      case NotificationRouteTarget.employeeDetail:
        if (routeInfo.entityId != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employeeId: routeInfo.entityId!),
            ),
          );
          return true;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeamListScreen()),
        );
        return true;

      case NotificationRouteTarget.teamList:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TeamListScreen()),
        );
        return true;

      case NotificationRouteTarget.reportSubmission:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportSubmissionScreen()),
        );
        return true;

      case NotificationRouteTarget.reportsList:
        UserModel? effectiveUser = user ?? AuthService().currentUser;
        effectiveUser ??= await AuthService().getCurrentUser();
        if (effectiveUser != null && context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReportsListScreen(
                user: effectiveUser!,
                initialViewMode: routeInfo.initialViewMode,
              ),
            ),
          );
          return true;
        }
        return false;

      case NotificationRouteTarget.dashboard:
        Navigator.popUntil(context, (route) => route.isFirst);
        return true;

      case NotificationRouteTarget.none:
        return false;
    }
  }
}
