import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/theme.dart';
import 'package:projecta_app/core/widgets/module_app_bar.dart';
import 'package:projecta_app/models/project_model.dart';
import 'package:projecta_app/models/task_model.dart';
import 'package:projecta_app/screens/dashboard/widgets/compliance_card.dart';
import 'package:projecta_app/screens/projects/widgets/project_milestones_section.dart';
import 'package:projecta_app/screens/projects/widgets/project_team_section.dart';
import 'package:projecta_app/screens/tasks/widgets/task_card.dart';

Widget _wrapNarrow(Widget child, {double width = 320, double textScale = 1.3}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 640),
        textScaler: TextScaler.linear(textScale),
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('Layout Overflow Regression Tests (320px width, 1.3x text scale)', () {
    final longOverdueTask = TaskModel(
      id: 1,
      taskCode: 'T-0001',
      projectId: 10,
      projectName: 'Ambiora Hotel ERP Enterprise Modernization',
      title: 'Revision 1 requirements & architectural sign-off',
      deadline: '2026-10-30',
      priority: 'high',
      status: 'pending_review',
      progress: 100,
      isOverdue: true,
      overdueDays: 13,
      assignees: const [
        TaskAssigneeModel(userId: 1, fullName: 'Aarav Patel'),
        TaskAssigneeModel(userId: 2, fullName: 'Priya Sharma'),
        TaskAssigneeModel(userId: 3, fullName: 'Rohan Verma'),
        TaskAssigneeModel(userId: 4, fullName: 'Neha Gupta'),
      ],
    );

    testWidgets('TaskCard List mode does not overflow at 320px and 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(TaskCard(task: longOverdueTask, isKanban: false)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('T-0001'), findsOneWidget);
      expect(find.text('Revision 1 requirements & architectural sign-off'), findsOneWidget);
    });

    testWidgets('TaskCard Kanban mode does not overflow at 320px and 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(
          SizedBox(
            width: 280,
            child: TaskCard(task: longOverdueTask, isKanban: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('T-0001'), findsOneWidget);
    });

    testWidgets('ComplianceCard does not overflow at 320px and 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(
          const ComplianceCard(
            badgeData: {
              'status_key': 'submitted',
              'label': 'Submitted — On Time',
              'deadline_time': '07:00 PM IST',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ProjectMilestonesSection does not overflow at 320px and 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(
          ProjectMilestonesSection(
            milestones: const [
              ProjectMilestoneModel(
                id: 1,
                title: 'Phase 1 Production Release & QA Audit',
                dueDate: '2025-01-15',
                status: 'pending',
                taskCount: 14,
              ),
            ],
            canManage: true,
            onToggle: (_) {},
            onAdd: () {},
            onEdit: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('ProjectTeamSection does not overflow at 320px and 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapNarrow(
          ProjectTeamSection(
            members: const [
              ProjectMemberModel(
                id: 1,
                userId: 101,
                memberRole: 'member',
                fullName: 'Alexander Maximilian',
                designation: 'Senior Principal Systems Architect',
                openTasks: 12,
              ),
              ProjectMemberModel(
                id: 2,
                userId: 102,
                memberRole: 'viewer',
                fullName: 'Priya Nair',
                designation: 'QA Lead',
                openTasks: 3,
              ),
            ],
            canManage: true,
            onAdd: () {},
            onRemove: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'ModuleAppBar with Refresh and Add Dept does not overflow at 320px and 1.3x scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                appBar: ModuleAppBar(
                  title: 'Department Management',
                  subtitle: '3 registered department(s)',
                  actions: [
                    IconButton(
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
                      onPressed: () {},
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.add_business, size: 17),
                        label: const Text('Add Dept'),
                      ),
                    ),
                  ],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Add Dept'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ModuleAppBar with Mark all read and Refresh does not overflow at 320px and 1.3x scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 640),
                textScaler: TextScaler.linear(1.3),
              ),
              child: Scaffold(
                appBar: ModuleAppBar(
                  title: 'Notifications',
                  subtitle: '4 unread · 12 total',
                  actions: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Mark all read'),
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      icon: const Icon(Icons.refresh, color: AppTheme.deepSlate),
                      onPressed: () {},
                    ),
                  ],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Mark all read'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

