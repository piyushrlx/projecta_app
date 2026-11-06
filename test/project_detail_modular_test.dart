import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/models/project_model.dart';
import 'package:projecta_app/screens/projects/widgets/project_activity_timeline.dart';
import 'package:projecta_app/screens/projects/widgets/project_milestones_section.dart';
import 'package:projecta_app/screens/projects/widgets/project_overview_card.dart';
import 'package:projecta_app/screens/projects/widgets/project_scope_section.dart';
import 'package:projecta_app/screens/projects/widgets/project_task_metric_grid.dart';
import 'package:projecta_app/screens/projects/widgets/project_team_section.dart';

void main() {
  group('Phase 5: Project Detail Modular Component Tests', () {
    const dummyProject = ProjectModel(
      id: 1,
      projectCode: 'PRJ-001',
      name: 'Alpha Redesign',
      status: 'active',
      priority: 'high',
      startDate: '2026-10-01',
      deadline: '2026-11-30',
      completionPercent: 65.5,
      departmentName: 'Design Ops',
      managerName: 'Sarah Connor',
      clientName: 'Cyberdyne',
      canManage: true,
    );

    const dummyDetail = ProjectDetailModel(
      project: dummyProject,
      scopeOfWork: 'Complete revamp of UI/UX design tokens.',
      deliverables: 'Figma file, design system, component catalog.',
      taskCounts: ProjectTaskCountsModel(
        total: 10,
        completed: 4,
        inProgress: 3,
        blocked: 1,
      ),
      milestones: [
        ProjectMilestoneModel(
          id: 101,
          projectId: 1,
          title: 'Design System Frozen',
          status: 'completed',
          dueDate: '2026-10-15',
          taskCount: 5,
        ),
        ProjectMilestoneModel(
          id: 102,
          projectId: 1,
          title: 'Frontend Production Rollout',
          status: 'pending',
          dueDate: '2026-11-20',
          taskCount: 5,
        ),
      ],
      members: [
        ProjectMemberModel(
          id: 1,
          userId: 10,
          fullName: 'John Doe',
          memberRole: 'member',
          designation: 'Staff Engineer',
          openTasks: 3,
        ),
      ],
      recentActivity: [
        ProjectActivityModel(
          id: 1,
          activityType: 'milestone_updated',
          description: 'Updated milestone status to completed',
          createdAt: '2026-10-15 10:30:00',
        ),
      ],
    );

    testWidgets('ProjectOverviewCard renders code, name, dates and progress', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectOverviewCard(
              project: dummyProject,
              detail: dummyDetail,
            ),
          ),
        ),
      );

      expect(find.text('PRJ-001'), findsOneWidget);
      expect(find.text('Alpha Redesign'), findsOneWidget);
      expect(find.text('Client: Cyberdyne'), findsOneWidget);
      expect(find.text('65.5%'), findsOneWidget);
      expect(find.text('Design Ops'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
    });

    testWidgets('ProjectTaskMetricGrid displays tasks breakdown pills', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectTaskMetricGrid(counts: dummyDetail.taskCounts),
          ),
        ),
      );

      expect(find.text('Tasks Breakdown'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // total
      expect(find.text('3'), findsOneWidget); // inProgress
      expect(find.text('1'), findsOneWidget); // blocked
      expect(find.text('4'), findsOneWidget); // completed
    });

    testWidgets(
      'ProjectMilestonesSection renders milestones and triggers callbacks',
      (tester) async {
        bool toggleCalled = false;
        bool addCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProjectMilestonesSection(
                milestones: dummyDetail.milestones,
                canManage: true,
                onToggle: (m) => toggleCalled = true,
                onAdd: () => addCalled = true,
                onEdit: (_) {},
                onDelete: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Milestones'), findsOneWidget);
        expect(find.text('Design System Frozen'), findsOneWidget);
        expect(find.text('Frontend Production Rollout'), findsOneWidget);

        // Tap milestone check box
        await tester.tap(find.byIcon(Icons.check));
        expect(toggleCalled, isTrue);

        // Tap add milestone
        await tester.tap(find.text('+ Add Milestone'));
        expect(addCalled, isTrue);
      },
    );

    testWidgets('ProjectTeamSection renders team member card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectTeamSection(
              members: dummyDetail.members,
              canManage: true,
              onAdd: () {},
              onRemove: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('3 open'), findsOneWidget);
      expect(find.text('Staff Engineer'), findsOneWidget);
    });

    testWidgets('ProjectScopeSection renders scope and deliverables', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProjectScopeSection(detail: dummyDetail)),
        ),
      );

      expect(find.text('Scope & Deliverables'), findsOneWidget);
      expect(
        find.text('Complete revamp of UI/UX design tokens.'),
        findsOneWidget,
      );
      expect(
        find.text('Figma file, design system, component catalog.'),
        findsOneWidget,
      );
    });

    testWidgets('ProjectActivityTimeline renders and expands audit trail', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectActivityTimeline(
              activities: dummyDetail.recentActivity,
            ),
          ),
        ),
      );

      expect(find.text('Recent Activity'), findsOneWidget);
      // Tap to expand
      await tester.tap(find.text('Recent Activity'));
      await tester.pumpAndSettle();

      expect(
        find.text('Updated milestone status to completed'),
        findsOneWidget,
      );
    });
  });
}
