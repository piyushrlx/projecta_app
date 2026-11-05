import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projecta_app/core/app_date_utils.dart';
import 'package:projecta_app/models/project_model.dart';
import 'package:projecta_app/screens/projects/project_form_screen.dart';
import 'package:projecta_app/screens/projects/projects_list_screen.dart';
import 'package:projecta_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _MockHttpRequest(url);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpRequest implements HttpClientRequest {
  final Uri url;
  _MockHttpRequest(this.url);

  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool bufferOutput = true;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    final path = url.path;
    Map<String, dynamic> responseData;

    if (path.contains('/projects')) {
      responseData = {
        'ok': true,
        'projects': [
          {
            'id': 101,
            'project_code': 'P-0101',
            'name': 'ERP Platform Overhaul',
            'client_name': 'Acme Corp',
            'start_date': '2026-11-01',
            'deadline': '2026-12-31',
            'status': 'active',
            'priority': 'high',
            'overdue_tasks': 1,
            'completion_percent': 65.0,
            'total_tasks': 10,
            'done_tasks': 6,
          },
        ],
        'total': 1,
        'page': 1,
        'pages': 1,
      };
    } else if (path.contains('/departments')) {
      responseData = {
        'ok': true,
        'departments': [
          {'id': 1, 'name': 'Engineering'},
        ],
      };
    } else if (path.contains('/employees')) {
      responseData = {
        'ok': true,
        'employees': [
          {'id': 1, 'full_name': 'Admin User', 'role': 'admin'},
        ],
      };
    } else {
      responseData = {'ok': true};
    }

    final bytes = utf8.encode(jsonEncode(responseData));
    return _MockHttpResponse(bytes);
  }

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  Future<HttpClientResponse> get done => close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name, () => []).add(value.toString());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  List<String>? operator [](String name) => _headers[name];

  @override
  String? value(String name) {
    final values = _headers[name];
    if (values == null || values.isEmpty) return null;
    return values.first;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final List<int> _bytes;
  _MockHttpResponse(this.bytes) : _bytes = bytes;
  final List<int> bytes;

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => true;

  @override
  String get reasonPhrase => 'OK';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  List<Cookie> get cookies => const [];

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(_bytes).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_token',
      'auth_user': jsonEncode({
        'id': 1,
        'name': 'Test Admin',
        'email': 'admin@test.com',
        'role': 'admin',
        'admin_scope': 'all',
        'must_change_password': false,
      }),
    });
    await AuthService().getCurrentUser();
  });

  group('Module 3: Project & Milestone Models Deserialization Tests', () {
    test(
      'ProjectMilestoneModel parses taskCount, projectId, and calculates overdue',
      () {
        final jsonPendingOverdue = {
          'id': 10,
          'project_id': 1,
          'title': 'Milestone Alpha',
          'due_date': '2020-01-01',
          'status': 'pending',
          'task_count': 3,
        };

        final m1 = ProjectMilestoneModel.fromJson(jsonPendingOverdue);
        expect(m1.id, 10);
        expect(m1.projectId, 1);
        expect(m1.taskCount, 3);
        expect(m1.isCompleted, false);
        expect(m1.isOverdue, true);

        final jsonCompleted = {
          'id': 11,
          'project_id': 1,
          'title': 'Milestone Beta',
          'due_date': '2020-01-01',
          'status': 'completed',
          'task_count': 0,
        };

        final m2 = ProjectMilestoneModel.fromJson(jsonCompleted);
        expect(m2.isCompleted, true);
        expect(m2.isOverdue, false);

        final mCopied = m1.copyWith(status: 'completed', taskCount: 4);
        expect(mCopied.isCompleted, true);
        expect(mCopied.taskCount, 4);
        expect(mCopied.projectId, 1);
      },
    );

    test('ProjectMemberModel parses openTasks and user info', () {
      final jsonMember = {
        'id': 5,
        'user_id': 7,
        'member_role': 'member',
        'full_name': 'Gautam',
        'designation': 'Lead Engineer',
        'open_tasks': 2,
      };

      final mem = ProjectMemberModel.fromJson(jsonMember);
      expect(mem.id, 5);
      expect(mem.userId, 7);
      expect(mem.fullName, 'Gautam');
      expect(mem.openTasks, 2);
    });

    test(
      'ProjectModel parses pendingTasks, archivedAt, teamMembers and isArchived',
      () {
        final jsonActive = {
          'id': 101,
          'project_code': 'P-0101',
          'name': 'Active Web App',
          'client_name': 'Global Retailers',
          'department_name': 'Development',
          'status': 'active',
          'priority': 'high',
          'pending_tasks': 4,
          'done_tasks': 8,
          'overdue_tasks': 1,
          'progress_method': 'weighted',
          'archived_at': null,
          'team_members': [
            {
              'user_id': 1,
              'full_name': 'Aman Bhatia',
              'profile_photo_url': null,
            },
            {
              'user_id': 2,
              'full_name': 'Piyush Sharma',
              'profile_photo_url': 'https://example.com/avatar.png',
            },
          ],
        };

        final pActive = ProjectModel.fromJson(jsonActive);
        expect(pActive.id, 101);
        expect(pActive.pendingTasks, 4);
        expect(pActive.doneTasks, 8);
        expect(pActive.overdueTasks, 1);
        expect(pActive.isWeighted, true);
        expect(pActive.isArchived, false);
        expect(pActive.teamMembers.length, 2);
        expect(pActive.teamMembers[0]['full_name'], 'Aman Bhatia');
        expect(pActive.teamMembers[1]['profile_photo_url'], isNotNull);

        final jsonArchived = {
          'id': 102,
          'project_code': 'P-0102',
          'name': 'Archived Legacy System',
          'status': 'completed',
          'archived_at': '2026-11-01 10:00:00',
        };

        final pArchived = ProjectModel.fromJson(jsonArchived);
        expect(pArchived.isArchived, true);
        expect(pArchived.archivedAt, '2026-11-01 10:00:00');
      },
    );

    test(
      'AppDateUtils matches web fmt_date, fmt_datetime, and time_ago formatting',
      () {
        expect(AppDateUtils.fmtDate('2026-11-10'), '10 Nov 2026');
        expect(AppDateUtils.fmtDate(null), '—');
        expect(AppDateUtils.fmtDate(''), '—');

        expect(
          AppDateUtils.fmtDateTime('2026-11-10 14:30:00'),
          '10 Nov 2026, 14:30',
        );
        expect(AppDateUtils.fmtDateTime(null), '—');

        final nowUtc = DateTime.now().toUtc();
        final justNow = nowUtc
            .subtract(const Duration(seconds: 15))
            .toIso8601String();
        expect(AppDateUtils.timeAgo(justNow), 'just now');

        final tenMinsAgo = nowUtc
            .subtract(const Duration(minutes: 10))
            .toIso8601String();
        expect(AppDateUtils.timeAgo(tenMinsAgo), '10 min ago');

        final twoHoursAgo = nowUtc
            .subtract(const Duration(hours: 2))
            .toIso8601String();
        expect(AppDateUtils.timeAgo(twoHoursAgo), '2 hr ago');

        final threeDaysAgo = nowUtc
            .subtract(const Duration(days: 3))
            .toIso8601String();
        expect(AppDateUtils.timeAgo(threeDaysAgo), '3 days ago');
      },
    );

    test(
      'ProjectModel calculates isOverdue, daysOverdue, and deadlineDaysLabel matching web',
      () {
        const pOverdue = ProjectModel(
          id: 1,
          projectCode: 'P-0001',
          name: 'Overdue Project',
          priority: 'high',
          status: 'active',
          startDate: '2020-01-01',
          deadline: '2020-01-10',
        );

        expect(pOverdue.isOverdue, true);
        expect(pOverdue.daysOverdue, greaterThan(100));
        expect(pOverdue.deadlineDaysLabel, contains('overdue'));

        const pFuture = ProjectModel(
          id: 2,
          projectCode: 'P-0002',
          name: 'Future Project',
          priority: 'medium',
          status: 'active',
          startDate: '2026-10-01',
          deadline: '2035-12-31',
        );

        expect(pFuture.isOverdue, false);
        expect(pFuture.daysOverdue, 0);
        expect(pFuture.deadlineDaysLabel, contains('remaining'));
      },
    );
  });

  group('Module 3: ProjectsListScreen Widget Tests', () {
    testWidgets(
      'Renders search bar, 7 filter pills, and opens advanced filter sheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ProjectsListScreen()));

        await tester.pump();

        // Search Bar hint text
        expect(find.byType(TextField), findsOneWidget);
        expect(
          find.text('Search by project name, code, or client...'),
          findsOneWidget,
        );

        // Filter pills (all 7)
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Planned'), findsOneWidget);
        expect(find.text('At Risk'), findsWidgets);
        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('On Hold'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);

        // Scroll to and tap filter pill 'Archived'
        await tester.ensureVisible(find.text('Archived'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Archived'), warnIfMissed: false);
        await tester.pump();

        // Tap Filter button to open Filter Sheet
        expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
        await tester.tap(find.byIcon(Icons.filter_list_rounded));
        await tester.pumpAndSettle();

        // Filter Sheet is visible
        expect(find.text('Filter Projects'), findsOneWidget);
        expect(find.text('Department'), findsOneWidget);
        expect(find.text('Project Manager'), findsOneWidget);
        expect(find.text('Priority'), findsOneWidget);
        expect(find.text('Overdue projects only'), findsOneWidget);
        expect(find.text('Apply Filters'), findsOneWidget);

        // Close sheet
        await tester.tap(find.text('Apply Filters'));
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Displays project start date above due date on project card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: ProjectsListScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('ERP Platform Overhaul'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);

      // Find Start Date and Due Date widgets
      final startFinder = find.text('Start 1 Nov 2026');
      final dueFinder = find.text('Due   31 Dec 2026');

      expect(startFinder, findsOneWidget);
      expect(dueFinder, findsOneWidget);

      // Verify that Start Date is positioned vertically ABOVE Due Date
      final startY = tester.getTopLeft(startFinder).dy;
      final dueY = tester.getTopLeft(dueFinder).dy;
      expect(
        startY,
        lessThan(dueY),
        reason: 'Start date must be located above due date',
      );

      // Zero exceptions / zero render overflows
      expect(tester.takeException(), isNull);
    });
  });

  group('Module 3: ProjectFormScreen Widget Tests', () {
    testWidgets('Renders all project form fields and validates name', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: ProjectFormScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('New Project'), findsOneWidget);
      expect(find.text('Project Name *'), findsOneWidget);
      expect(find.text('Client Name'), findsOneWidget);
      expect(find.text('Create Project'), findsOneWidget);

      // Verify Team Section components
      expect(find.text('TEAM'), findsOneWidget);
      expect(find.text('Project manager *'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);
      expect(find.text('(can be assigned tasks)'), findsOneWidget);
      expect(find.text('Viewers'), findsOneWidget);
      expect(find.text('(read-only access)'), findsOneWidget);
      expect(find.text('Type to filter...'), findsNWidgets(2));

      // Scroll to and tap submit with empty name to verify required validator
      await tester.ensureVisible(find.text('Create Project'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Project'));
      await tester.pumpAndSettle();

      expect(find.text('Project name is required'), findsOneWidget);
    });

    testWidgets('Edit mode pre-fills existing project data and team members', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const existingProject = ProjectModel(
        id: 42,
        projectCode: 'P-0042',
        name: 'Enterprise Data Lake',
        clientName: 'BigData Corp',
        priority: 'high',
        status: 'active',
      );

      const existingDetail = ProjectDetailModel(
        project: existingProject,
        members: [
          ProjectMemberModel(
            id: 1,
            userId: 1,
            memberRole: 'member',
            fullName: 'Admin User',
          ),
          ProjectMemberModel(
            id: 2,
            userId: 2,
            memberRole: 'viewer',
            fullName: 'Viewer User',
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(home: ProjectFormScreen(detail: existingDetail)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Project'), findsOneWidget);
      expect(find.text('Enterprise Data Lake'), findsOneWidget);
      expect(find.text('BigData Corp'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('TEAM'), findsOneWidget);
    });
  });
}
