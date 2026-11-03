import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/models/project_model.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/models/report_model.dart';
import 'package:projecta_app/models/notification_model.dart';

void main() {
  group('Project Models Deserialization', () {
    test('ProjectModel parses fields and flags properly', () {
      final json = {
        'id': 101,
        'project_code': 'P-0101',
        'name': 'Cloud Platform Migration',
        'client_name': 'Alpha Inc',
        'status': 'active',
        'priority': 'critical',
        'overdue_tasks': 2,
        'completion_percent': 75.5,
        'member_count': 4,
        'total_tasks': 16,
        'done_tasks': 12,
        'can_manage': true,
      };

      final p = ProjectModel.fromJson(json);
      expect(p.id, 101);
      expect(p.projectCode, 'P-0101');
      expect(p.isActive, true);
      expect(p.isAtRisk, true);
      expect(p.canManage, true);
      expect(p.completionPercent, 75.5);
    });

    test('ProjectDetailModel parses nested milestones and members', () {
      final json = {
        'project': {
          'id': 101,
          'project_code': 'P-0101',
          'name': 'Cloud Platform Migration',
          'priority': 'high',
          'status': 'active',
        },
        'milestones': [
          {
            'id': 1,
            'title': 'Phase 1 Architecture',
            'status': 'completed',
          },
          {
            'id': 2,
            'title': 'Phase 2 Execution',
            'status': 'pending',
          }
        ],
        'members': [
          {
            'id': 10,
            'user_id': 5,
            'member_role': 'lead',
            'full_name': 'Sarah Connor',
          }
        ]
      };

      final detail = ProjectDetailModel.fromJson(json);
      expect(detail.project.id, 101);
      expect(detail.milestones.length, 2);
      expect(detail.milestones.first.isCompleted, true);
      expect(detail.milestones.last.isCompleted, false);
      expect(detail.members.first.fullName, 'Sarah Connor');
    });
  });

  group('Task Models Deserialization', () {
    test('TaskModel parses lock status and assignees', () {
      final json = {
        'id': 202,
        'task_code': 'T-0202',
        'project_id': 101,
        'title': 'Setup Docker Containers',
        'priority': 'high',
        'status': 'in_progress',
        'progress': 40,
        'open_dependencies_count': 1,
        'assignees': [
          {
            'user_id': 5,
            'full_name': 'Sarah Connor',
            'responsibility': 'owner',
          }
        ]
      };

      final t = TaskModel.fromJson(json);
      expect(t.id, 202);
      expect(t.isLocked, true);
      expect(t.isInProgress, true);
      expect(t.assignees.first.isOwner, true);
    });

    test('TaskDetailModel parses allowedStatuses and extensionRequests', () {
      final json = {
        'task': {
          'id': 202,
          'task_code': 'T-0202',
          'project_id': 101,
          'title': 'Setup Docker Containers',
          'priority': 'high',
          'status': 'in_progress',
          'allowed_statuses': ['in_progress', 'blocked', 'pending_review'],
          'can_work': true,
        },
        'extension_requests': [
          {
            'id': 1,
            'task_id': 202,
            'requested_by': 5,
            'requester_name': 'Sarah Connor',
            'requested_deadline': '2026-11-20',
            'reason': 'Hardware delay',
            'status': 'pending',
            'created_at': '2026-11-03 12:00:00',
          }
        ]
      };

      final detail = TaskDetailModel.fromJson(json);
      expect(detail.allowedStatuses.length, 3);
      expect(detail.canWork, true);
      expect(detail.extensionRequests.first.isPending, true);
    });
  });

  group('Report & Notification Models Deserialization', () {
    test('ReportModel parses status and late flag', () {
      final json = {
        'id': 303,
        'user_id': 5,
        'report_date': '2026-11-03',
        'project_id': 101,
        'work_summary': 'Containerized core services',
        'minutes_spent': 180,
        'status': 'submitted',
        'is_late': true,
      };

      final r = ReportModel.fromJson(json);
      expect(r.id, 303);
      expect(r.isSubmitted, true);
      expect(r.isLate, true);
      expect(r.hoursFormatted, '3h 0m');
    });

    test('NotificationModel parses unread state', () {
      final json = {
        'id': 404,
        'type': 'task_assigned',
        'title': 'New Task',
        'message': 'You have been assigned to Docker Setup',
        'is_read': 0,
        'created_at': '2026-11-03 14:00:00',
      };

      final n = NotificationModel.fromJson(json);
      expect(n.id, 404);
      expect(n.isRead, false);
      expect(n.type, 'task_assigned');
    });
  });
}

