import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/notification_router.dart';
import 'package:projecta_app/models/notification_model.dart';

void main() {
  group('NotificationRouter URL Parsing & Route Deduction Tests', () {
    test('Parses task-details.php with numerical ID', () {
      const n = NotificationModel(
        id: 1,
        type: 'task_assigned',
        title: 'New Task',
        message: 'You have been assigned a task.',
        link: 'task-details.php?id=42',
        createdAt: '2026-11-11 10:00:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.taskDetail);
      expect(route.entityId, 42);
      expect(n.category, 'task');
      expect(n.targetEntityId, 42);
    });

    test('Parses project-details.php with fragment #milestones', () {
      const n = NotificationModel(
        id: 2,
        type: 'project_update',
        title: 'Milestone Completed',
        message: 'Milestone completed in Project Alpha.',
        link: 'project-details.php?id=108#milestones',
        createdAt: '2026-11-11 10:05:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.projectDetail);
      expect(route.entityId, 108);
      expect(n.category, 'project');
      expect(n.targetEntityId, 108);
    });

    test('Parses employee-details.php with ID', () {
      const n = NotificationModel(
        id: 3,
        type: 'registration',
        title: 'New Admin Registered',
        message: 'A new manager registered.',
        link: 'employee-details.php?id=15',
        createdAt: '2026-11-11 10:10:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.employeeDetail);
      expect(route.entityId, 15);
      expect(n.category, 'team');
      expect(n.targetEntityId, 15);
    });

    test('Parses submit-report.php with date query', () {
      const n = NotificationModel(
        id: 4,
        type: 'report_missing',
        title: 'Daily Report Missing',
        message: 'Reporting deadline has passed.',
        link: 'submit-report.php?date=2026-11-11',
        createdAt: '2026-11-11 18:30:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.reportSubmission);
      expect(route.date, '2026-11-11');
      expect(n.category, 'report');
      expect(n.isUrgent, isTrue);
    });

    test('Parses compliance.php for managers', () {
      const n = NotificationModel(
        id: 5,
        type: 'compliance_alert',
        title: 'Team Compliance Alert',
        message: 'Several employees have not submitted daily reports.',
        link: 'compliance.php?date=2026-11-11',
        createdAt: '2026-11-11 19:00:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.reportsList);
      expect(route.initialViewMode, 'compliance');
      expect(route.date, '2026-11-11');
      expect(n.category, 'report');
      expect(n.isUrgent, isTrue);
    });

    test('Parses generic list links (tasks.php, projects.php, dashboard.php)', () {
      const nTasks = NotificationModel(
        id: 6,
        type: 'task_assigned',
        title: 'Tasks Updated',
        message: 'Review task list',
        link: 'tasks.php',
        createdAt: '2026-11-11 11:00:00',
      );
      expect(NotificationRouter.parse(nTasks).target, NotificationRouteTarget.tasksList);

      const nProjects = NotificationModel(
        id: 7,
        type: 'project_update',
        title: 'Projects Directory',
        message: 'Projects directory updated',
        link: 'projects.php',
        createdAt: '2026-11-11 11:00:00',
      );
      expect(NotificationRouter.parse(nProjects).target, NotificationRouteTarget.projectsList);

      const nDash = NotificationModel(
        id: 8,
        type: 'account_activated',
        title: 'Account Activated',
        message: 'You can now log in',
        link: 'dashboard.php',
        createdAt: '2026-11-11 11:00:00',
      );
      expect(NotificationRouter.parse(nDash).target, NotificationRouteTarget.dashboard);
    });

    test('Parses modern REST path format (/tasks/99, /projects/77)', () {
      const nRest = NotificationModel(
        id: 9,
        type: 'task_status_changed',
        title: 'Task In Review',
        message: 'Task moved to review',
        link: '/tasks/99',
        createdAt: '2026-11-11 12:00:00',
      );
      final route = NotificationRouter.parse(nRest);
      expect(route.target, NotificationRouteTarget.taskDetail);
      expect(route.entityId, 99);
    });

    test('Graceful fallback when link is null using notification type', () {
      const nNoLinkTask = NotificationModel(
        id: 10,
        type: 'deadline_reminder',
        title: 'Deadline Approaching',
        message: 'Your task is due tomorrow',
        link: null,
        createdAt: '2026-11-11 12:00:00',
      );
      expect(NotificationRouter.parse(nNoLinkTask).target, NotificationRouteTarget.tasksList);
      expect(nNoLinkTask.category, 'task');

      const nNoLinkReport = NotificationModel(
        id: 11,
        type: 'report_missing',
        title: 'Submit Report',
        message: 'Missing daily report',
        link: null,
        createdAt: '2026-11-11 18:00:00',
      );
      expect(NotificationRouter.parse(nNoLinkReport).target, NotificationRouteTarget.reportSubmission);

      const nNoLinkProj = NotificationModel(
        id: 12,
        type: 'project_assigned',
        title: 'New Project',
        message: 'Assigned to new project',
        link: null,
        createdAt: '2026-11-11 09:00:00',
      );
      expect(NotificationRouter.parse(nNoLinkProj).target, NotificationRouteTarget.projectsList);
    });

    test('Urgent flag and copyWith function correctly', () {
      const nOverdue = NotificationModel(
        id: 13,
        type: 'overdue',
        title: 'Overdue task: Critical Bug Fix',
        message: '2 days overdue',
        isRead: false,
        createdAt: '2026-11-11 08:00:00',
      );
      expect(nOverdue.isUrgent, isTrue);
      expect(nOverdue.isRead, isFalse);

      final nRead = nOverdue.copyWith(isRead: true, readAt: '2026-11-11 13:00:00');
      expect(nRead.isRead, isTrue);
      expect(nRead.readAt, '2026-11-11 13:00:00');
      expect(nRead.id, 13);
    });

    test('Parses report-details.php with numerical ID (singular)', () {
      const n = NotificationModel(
        id: 14,
        type: 'report_reviewed',
        title: 'Report Approved',
        message: 'Your report was approved by manager.',
        link: 'report-details.php?id=88',
        createdAt: '2026-11-11 19:30:00',
      );

      final route = NotificationRouter.parse(n);
      expect(route.target, NotificationRouteTarget.reportsList);
      expect(route.entityId, 88);
      expect(n.category, 'report');
    });

    test('Handles live PHP extension types (deadline_extension_request & extension_decision)', () {
      const nReq = NotificationModel(
        id: 15,
        type: 'deadline_extension_request',
        title: 'Extension requested: Redesign',
        message: 'Staff requested 3 additional days.',
        link: null,
        createdAt: '2026-11-11 14:00:00',
      );
      expect(NotificationRouter.parse(nReq).target, NotificationRouteTarget.tasksList);
      expect(nReq.category, 'task');

      const nDec = NotificationModel(
        id: 16,
        type: 'extension_decision',
        title: 'Extension request approved',
        message: 'Your deadline was extended.',
        link: 'task-details.php?id=44',
        createdAt: '2026-11-11 15:00:00',
      );
      final routeDec = NotificationRouter.parse(nDec);
      expect(routeDec.target, NotificationRouteTarget.taskDetail);
      expect(routeDec.entityId, 44);
      expect(nDec.category, 'task');
    });

    test('Handles comment and mention types with and without links', () {
      const nCommentTask = NotificationModel(
        id: 17,
        type: 'comment',
        title: 'Alice commented on task',
        message: 'Please check the latest revision.',
        link: null,
        createdAt: '2026-11-11 16:00:00',
      );
      expect(NotificationRouter.parse(nCommentTask).target, NotificationRouteTarget.tasksList);
      expect(nCommentTask.category, 'task');

      const nMentionProj = NotificationModel(
        id: 18,
        type: 'mention',
        title: 'Bob mentioned you',
        message: '@piyush please review Project Alpha scope',
        link: null,
        createdAt: '2026-11-11 16:30:00',
      );
      expect(NotificationRouter.parse(nMentionProj).target, NotificationRouteTarget.projectsList);
      expect(nMentionProj.category, 'project');
    });
  });
}
