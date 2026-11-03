# PROJECTA MOBILE (`d:\projecta_app`) — PHASE 3 & 4 COMPLETION PLAN

## 1. Current Verified Baseline (DO NOT REWRITE)
- **Active Flutter Project Root:** `d:\projecta_app\` (IGNORE `d:\XAMP\htdocs\project_app\`).
- **Active PHP Backend Root:** `d:\XAMP\htdocs\projecta\api\v1\` (100% complete via `index.php` router and `controllers/`).
- **Already Completed in Flutter (Keep & Wire Into Navigation):**
  - `lib/core/api_client.dart` & `lib/core/theme.dart` (Swiss Grid Neo-Brutalism: `#FFFFFF`, `#0A0A0A`, `#FF0033`, `BorderRadius.zero`, `2px` borders, `Offset(4,4)` hard shadow, `Space Grotesk` + `Inter` + `JetBrains Mono`).
  - `lib/models/user_model.dart` & `lib/services/auth_service.dart`
  - `lib/screens/auth/login_screen.dart` & `lib/screens/auth/must_change_password_screen.dart`
  - `lib/screens/dashboard/dashboard_screen.dart`, `admin_dashboard_view.dart`, `staff_dashboard_view.dart`, `compliance_card.dart`, `kpi_card.dart`, and `lib/services/dashboard_service.dart`.

---

## 2. Strict Architectural & UX Rules for Remaining Modules
1. **Read PHP Controllers First:** Before writing any Dart `model` or `service`, read the corresponding PHP file inside `d:\XAMP\htdocs\projecta\api\v1\index.php` and `d:\XAMP\htdocs\projecta\api\v1\controllers\` (`ProjectsController.php`, `TasksController.php`, `ReportsController.php`, `NotificationsController.php`, `DirectoryController.php`) so every endpoint URL, HTTP method, query param, and JSON key matches the PHP backend 100%.
2. **State & Architecture:** Keep using standard `StatefulWidget`, `Provider`, and `ApiClient`. Zero `BLoC`, `Riverpod`, `Isar`, or `Dio`.
3. **Zero-Search UX & Layout:**
   - Upgrade `dashboard_screen.dart` into the main persistent **Bottom Navigation Shell** (4 Tabs: `0: Dashboard`, `1: Tasks`, `2: Projects`, `3: Reports`) + top-right **Notifications Bell** with unread badge + **Violent Red (`#FF0033`) Floating Action Button**:
     - For `staff`: Red FAB opens **"SUBMIT DAILY REPORT"** directly from any tab.
     - For `admin` / `super_admin`: Red FAB opens **"ASSIGN NEW TASK"** directly from any tab.
   - Use 1-tap horizontal filter chips (`ALL`, `DUE TODAY`, `OVERDUE`, `IN PROGRESS`, `BLOCKED`) instead of typing searches.
4. **Micro-Animations:**
   - Use `AnimatedContainer` (`120ms`, `Curves.easeOut`) on cards and buttons so tapping compresses the `Offset(4, 4)` hard shadow down to `Offset(1, 1)` with `HapticFeedback.lightImpact()`.
   - Use `TweenAnimationBuilder<double>` (`400ms`) on project progress bars.

---

## 3. The 4 Remaining Modules to Build in `d:\projecta_app\lib\`

### Batch 1: Projects & Milestones (Module 3)
*Inspect `api/v1/controllers/ProjectsController.php` and `DirectoryController.php` first.*
1. **`lib/models/project_model.dart`**: Parse project details (`id`, `code` e.g. `P-XXXX`, `name`, `client_name`, `status`, `deadline`, weighted `progress`, `members`, `milestones`).
2. **`lib/services/project_service.dart`**: Methods to fetch projects list, fetch single project details + milestones, and toggle milestone status (for Admins).
3. **`lib/screens/projects/projects_list_screen.dart`**:
   - Filter pills (`ACTIVE`, `COMPLETED`, `AT RISK`).
   - Neo-Brutalist cards showing `P-XXXX` badge in `JetBrains Mono`, Client Name, animated progress bar, overdue task count in Violent Red, and team member count.
4. **`lib/screens/projects/project_detail_screen.dart`**:
   - Project scope, client details, deliverables, Milestone timeline with completion checkboxes (for Admins), and quick jump to the project's tasks.

### Batch 2: Tasks, Status State-Machine, Assign Task & Extensions (Module 4)
*Inspect `api/v1/controllers/TasksController.php` first.*
1. **`lib/models/task_model.dart`**: Parse tasks, subtasks (`parent_task_id`), assignees (`owner` vs `contributor`), dependencies (predecessor locks), status history, and extension requests.
2. **`lib/services/task_service.dart`**:
   - Fetch tasks with filters (`project_id`, `status`, `overdue`).
   - Fetch single task details.
   - Update task status (`not_started`, `in_progress`, `blocked`, `pending_review`, `completed`) with `completion_notes`.
   - Submit deadline extension request (Staff) and approve/reject extension request (Admin).
   - Create & assign new task (Admin) using employee/project lookup from `DirectoryController.php`.
3. **`lib/screens/tasks/tasks_screen.dart`**:
   - Toggle between **List View** and **Mobile Kanban Board View** (horizontal status columns or 1-tap status tabs).
   - 1-tap filter bar (`ALL`, `MY PRIORITY`, `OVERDUE`, `BLOCKED`, `PENDING REVIEW`).
4. **`lib/screens/tasks/task_detail_screen.dart`**:
   - Shows violent red dependency lock banner if predecessor tasks are unfinished.
   - One-tap status transition bar obeying role rules (Staff: `In Progress`, `Blocked`, `Pending Review`; Admin: adds `Completed`, `Cancelled`). Prompts for completion notes if required.
   - Subtasks checklist & **Request Deadline Extension** modal sheet (Staff) / **Approve or Reject Extension** banner (Admin).
5. **`lib/screens/tasks/create_task_screen.dart`** (Admin / Super Admin):
   - Select Project, enter Title/Description, select Priority (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`), pick Deadline, Estimated Hours, and assign `Owner` + `Contributors`.

### Batch 3: Daily Work Reports & Manager Review Workflow (Module 5)
*Inspect `api/v1/controllers/ReportsController.php` first.*
1. **`lib/models/report_model.dart`**: Parse daily report entries, `actual_minutes`, `is_late` flag, review status (`pending`, `approved`, `rejected`, `clarification_requested`), manager review comments, and compliance summary.
2. **`lib/services/report_service.dart`**:
   - Fetch today's reporting context (active assigned projects & tasks).
   - Submit or revise daily work report.
   - Fetch report history (Staff own reports / Admin team reports).
   - Manager review action (`approve`, `reject`, `clarification_requested` with feedback note).
3. **`lib/screens/reports/report_submission_screen.dart`** (30-Second Staff Wizard):
   - Auto-populated project/task selector from today's active assignments.
   - Quick-tap time chips (`15m`, `30m`, `1h`, `2h`, `4h`) + custom minutes input in `JetBrains Mono`.
   - Quick progress slider (`0%` to `100%`).
   - Clean inputs for Completed Work, Pending Work, Blockers, and Next Actions.
4. **`lib/screens/reports/reports_list_screen.dart`**:
   - **Staff View:** History of submitted reports with `SUBMITTED`, `LATE`, or `RETURNED FOR CORRECTION` badges; tapping a returned report opens it for revision.
   - **Admin View:** Daily Report Review Inbox with 1-tap filter (`PENDING REVIEW`, `SUBMITTED TODAY`, `LATE`) and a bottom sheet to **Approve**, **Request Clarification**, or **Reject** with manager comments.

### Batch 4: Notifications Center, Navigation Wiring & Final `flutter analyze` (Module 6)
*Inspect `api/v1/controllers/NotificationsController.php` first.*
1. **`lib/models/notification_model.dart` & `lib/services/notification_service.dart`**: Fetch notifications list, unread count, and mark-as-read endpoints.
2. **`lib/screens/notifications/notifications_screen.dart`**: Clean feed of deadline alerts, task assignments, and report review notifications with 1-tap "Mark All Read".
3. **Wire Everything into `dashboard_screen.dart`, `admin_dashboard_view.dart`, and `staff_dashboard_view.dart`**:
   - Connect the bottom navigation bar, top notification bell, dashboard KPI cards, priority task cards, and compliance card buttons so every tap navigates to the real screens.
4. **Verification**: Run `flutter analyze` on `d:\projecta_app` and fix any warnings until output is `No issues found!`.