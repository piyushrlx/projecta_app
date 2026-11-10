import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/app_date_utils.dart';
import 'package:projecta_app/models/project_model.dart';
import 'package:projecta_app/screens/projects/widgets/project_attachments_section.dart';
import 'package:projecta_app/screens/projects/widgets/project_comments_section.dart';

void main() {
  group('Module 3: Date & Time Synchronization Tests', () {
    test('AppDateUtils.timeAgo parses MySQL UTC timestamp and returns "just now" for new comments', () {
      final nowUtc = DateTime.now().toUtc();
      // Format as MySQL UTC string: YYYY-MM-DD HH:MM:SS
      final mysqlUtc = '${nowUtc.year.toString().padLeft(4, '0')}-'
          '${nowUtc.month.toString().padLeft(2, '0')}-'
          '${nowUtc.day.toString().padLeft(2, '0')} '
          '${nowUtc.hour.toString().padLeft(2, '0')}:'
          '${nowUtc.minute.toString().padLeft(2, '0')}:'
          '${nowUtc.second.toString().padLeft(2, '0')}';

      final result = AppDateUtils.timeAgo(mysqlUtc);
      expect(result, 'just now',
          reason: 'Brand new MySQL UTC comment timestamp must display "just now", never "5 hr ago"');
    });

    test('AppDateUtils.timeAgo accurately measures minutes and hours ago', () {
      final nowUtc = DateTime.now().toUtc();
      final tenMinutesAgo = nowUtc.subtract(const Duration(minutes: 10));
      final tenMinStr = '${tenMinutesAgo.year.toString().padLeft(4, '0')}-'
          '${tenMinutesAgo.month.toString().padLeft(2, '0')}-'
          '${tenMinutesAgo.day.toString().padLeft(2, '0')} '
          '${tenMinutesAgo.hour.toString().padLeft(2, '0')}:'
          '${tenMinutesAgo.minute.toString().padLeft(2, '0')}:'
          '${tenMinutesAgo.second.toString().padLeft(2, '0')}';
      expect(AppDateUtils.timeAgo(tenMinStr), '10 min ago');

      final twoHoursAgo = nowUtc.subtract(const Duration(hours: 2));
      final twoHourStr = '${twoHoursAgo.year.toString().padLeft(4, '0')}-'
          '${twoHoursAgo.month.toString().padLeft(2, '0')}-'
          '${twoHoursAgo.day.toString().padLeft(2, '0')} '
          '${twoHoursAgo.hour.toString().padLeft(2, '0')}:'
          '${twoHoursAgo.minute.toString().padLeft(2, '0')}:'
          '${twoHoursAgo.second.toString().padLeft(2, '0')}';
      expect(AppDateUtils.timeAgo(twoHourStr), '2 hr ago');
    });
  });

  group('Module 3: Collaboration Models Test', () {
    test('AttachmentModel parses JSON and calculates formattedSize accurately', () {
      final jsonSmall = {
        'id': 1,
        'original_name': 'specs.pdf',
        'size_bytes': 850,
        'mime_type': 'application/pdf',
        'download_url': 'http://localhost/projecta/download.php?id=1',
        'uploader_name': 'Alice Manager',
        'created_at': '2026-11-08 10:00:00',
      };
      final attSmall = AttachmentModel.fromJson(jsonSmall);
      expect(attSmall.id, 1);
      expect(attSmall.originalName, 'specs.pdf');
      expect(attSmall.formattedSize, '850 B');

      final jsonKb = {
        'id': 2,
        'original_name': 'diagram.png',
        'size_bytes': 204800, // 200 KB
        'mime_type': 'image/png',
        'download_url': 'http://localhost/projecta/download.php?id=2',
      };
      final attKb = AttachmentModel.fromJson(jsonKb);
      expect(attKb.formattedSize, '200.0 KB');

      final jsonMb = {
        'id': 3,
        'original_name': 'bundle.zip',
        'size_bytes': 15728640, // 15 MB
        'mime_type': 'application/zip',
        'download_url': 'http://localhost/projecta/download.php?id=3',
      };
      final attMb = AttachmentModel.fromJson(jsonMb);
      expect(attMb.formattedSize, '15.0 MB');
    });

    test('CommentModel parses JSON and preserves identity', () {
      final json = {
        'id': 42,
        'entity_type': 'project',
        'entity_id': 10,
        'user_id': 5,
        'user_name': 'Piyush Bhatt',
        'user_role': 'admin',
        'body': 'Production deployment planned for Friday.',
        'created_at': '2026-11-08 14:00:00',
        'is_my_comment': true,
      };
      final comment = CommentModel.fromJson(json);
      expect(comment.id, 42);
      expect(comment.entityType, 'project');
      expect(comment.entityId, 10);
      expect(comment.userName, 'Piyush Bhatt');
      expect(comment.userRole, 'admin');
      expect(comment.body, 'Production deployment planned for Friday.');
      expect(comment.isMyComment, isTrue);
    });

    test('ProjectDetailModel deserializes attachments and commentsCount', () {
      final json = {
        'project': {
          'id': 1,
          'project_code': 'P-0001',
          'name': 'Alpha Portal',
          'priority': 'high',
          'status': 'active',
        },
        'comments_count': 3,
        'attachments': [
          {
            'id': 101,
            'original_name': 'architecture.pdf',
            'size_bytes': 1048576,
            'mime_type': 'application/pdf',
            'download_url': 'http://localhost/projecta/download.php?id=101',
          }
        ],
      };
      final detail = ProjectDetailModel.fromJson(json);
      expect(detail.commentsCount, 3);
      expect(detail.attachments.length, 1);
      expect(detail.attachments.first.originalName, 'architecture.pdf');
    });
  });

  group('Module 3: ProjectAttachmentsSection Widget Tests', () {
    testWidgets('Renders empty state when attachments list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectAttachmentsSection(attachments: []),
          ),
        ),
      );

      expect(find.text('Files & Attachments'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No files attached to this project.'), findsOneWidget);
    });

    testWidgets('Renders attachment files and handles download tap', (tester) async {
      AttachmentModel? downloadedAtt;

      final testAttachments = [
        const AttachmentModel(
          id: 1,
          originalName: 'requirements.pdf',
          sizeBytes: 1536000,
          mimeType: 'application/pdf',
          downloadUrl: 'http://localhost/download/1',
          uploaderName: 'Alice',
          createdAt: '2026-11-08',
        ),
        const AttachmentModel(
          id: 2,
          originalName: 'mockup.png',
          sizeBytes: 512000,
          mimeType: 'image/png',
          downloadUrl: 'http://localhost/download/2',
          uploaderName: 'Bob',
          createdAt: '2026-11-08',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectAttachmentsSection(
              attachments: testAttachments,
              onDownload: (att) {
                downloadedAtt = att;
              },
            ),
          ),
        ),
      );

      expect(find.text('Files & Attachments'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('requirements.pdf'), findsOneWidget);
      expect(find.text('mockup.png'), findsOneWidget);

      // Verify download callback triggers
      final downloadButtons = find.byIcon(Icons.download_rounded);
      expect(downloadButtons, findsNWidgets(2));
      await tester.tap(downloadButtons.first);
      await tester.pump();

      expect(downloadedAtt, isNotNull);
      expect(downloadedAtt!.id, 1);
      expect(downloadedAtt!.originalName, 'requirements.pdf');
    });

    testWidgets('Displays "+ Attach File" and uploads new attachment via custom callback', (tester) async {
      bool uploadedCallbackInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectAttachmentsSection(
              projectId: 1,
              canUpload: true,
              attachments: const [],
              onUploaded: () {
                uploadedCallbackInvoked = true;
              },
              onCustomUpload: () async {
                return const AttachmentModel(
                  id: 999,
                  originalName: 'quarterly_report.pdf',
                  sizeBytes: 2048000,
                  mimeType: 'application/pdf',
                  downloadUrl: 'http://localhost/download/999',
                  uploaderName: 'Piyush Bhatt',
                  createdAt: '2026-11-10 14:00:00',
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Attach File'), findsOneWidget);
      await tester.tap(find.text('Attach File'));
      await tester.pumpAndSettle();

      expect(uploadedCallbackInvoked, isTrue);
      expect(find.text('quarterly_report.pdf'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // Counter updated
    });
  });

  group('Module 3: ProjectCommentsSection Widget Tests', () {
    testWidgets('Renders empty state and allows posting a new comment', (tester) async {
      final initialList = <CommentModel>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Roboto'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectCommentsSection(
                projectId: 1,
                initialComments: initialList,
                onAddComment: (body) async {
                  return CommentModel(
                    id: 99,
                    entityType: 'project',
                    entityId: 1,
                    userId: 1,
                    userName: 'Piyush Bhatt',
                    userRole: 'admin',
                    body: body,
                    createdAt: '2026-11-08 17:00:00',
                    isMyComment: true,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Discussion & Comments'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No comments yet. Start the conversation.'), findsOneWidget);

      // Type comment into composer
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'Reviewed milestones, everything on track.');
      await tester.pump();

      // Tap send button
      final sendFinder = find.byIcon(Icons.send_rounded);
      expect(sendFinder, findsOneWidget);
      await tester.tap(sendFinder);
      await tester.pumpAndSettle();

      // Comment should now be displayed
      expect(find.text('Reviewed milestones, everything on track.'), findsOneWidget);
      expect(find.text('Piyush Bhatt'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // badge count updated
    });
  });
}
