# PROJECTA MOBILE — MASTER UI/UX & MODULE LAYOUT SPECIFICATION

## 1. Core Philosophy: Mobile-First vs. Web
Do NOT design screens like shrunken web tables. Every screen in `d:\projecta_app\lib\screens\` must follow **Swiss Grid Neo-Brutalism** with **Zero-Search Ergonomics**:
- **85% Pure White (`#FFFFFF`) / Off-White (`#F5F5F5`)** canvas for maximum daylight readability and generous whitespace.
- **10% Pitch Black (`#0A0A0A`)** for `2.0px` sharp borders (`BorderRadius.zero`), hard offset shadows (`Offset(4, 4)`, `blurRadius: 0`), and primary text.
- **5% Violent Red (`#FF0033`)** strictly for: Primary CTA buttons, the Floating Action Button (FAB), `OVERDUE`/`BLOCKED`/`CRITICAL`/`LATE` badges, and active tab indicators.

---

## 2. Global Navigation & Screen Anatomy

### A. Top App Bar (`PreferredSizeWidget`, height `64px`)
- Bottom border: `2px` solid `#0A0A0A`.
- Left: Bold uppercase screen title in `Space Grotesk` (`20px`, weight `800`, letterSpacing `-0.5`) + role pill (`ADMIN` in black or `STAFF` in white with black border).
- Right:
  1. **Notification Bell IconButton** with a Violent Red square counter badge (`JetBrains Mono`, `11px`) when `unreadCount > 0`.
  2. **Profile / Logout Quick Button**.

### B. Persistent 4-Tab Bottom Navigation Bar
- Top border: `2px` solid `#0A0A0A`, background `#FFFFFF`, height `68px`.
- Selected tab shows a `4px` Violent Red (`#FF0033`) top indicator bar and bold `Space Grotesk` label:
  - **Tab 0: `PULSE`** (`AdminDashboardView` or `StaffDashboardView`)
  - **Tab 1: `TASKS`** (`TasksScreen` with 1-tap List / Kanban toggle)
  - **Tab 2: `PROJECTS`** (`ProjectsListScreen`)
  - **Tab 3: `REPORTS`** (`ReportsListScreen`)

### C. Context-Aware Violent Red FAB (`#FF0033`)
- Square Neo-Brutalist button (`56x56`, `2px` black border, `Offset(4, 4)` black shadow, white `+` icon).
- **If `staff`:** Opens `ReportSubmissionScreen` (30-Second Daily Report Wizard).
- **If `admin` / `super_admin`:** Opens `CreateTaskScreen` (Fast Task Assignment).

---

## 3. Module-by-Module UI Layout & Interaction Specs

### Module 1: Auth & Forced Password Reset (`lib/screens/auth/`)
- **Layout:** Centered single-column card on a clean grid background with bold `PROJECTA // WORKDESK` header, `2px` black-bordered inputs with focus highlight (`2.5px` `#FF0033` border when focused), and a full-width Violent Red submit button with mechanical press animation.

### Module 2: Role Dashboards (`lib/screens/dashboard/`)
- **Admin View (`admin_dashboard_view.dart`):**
  1. **Urgent Action Strip (Top):** High-contrast Black card highlighting `Overdue Tasks` and `Reports Pending Today` with Violent Red counters. Tapping navigates directly to the filtered tab.
  2. **2-Column KPI Bento Grid:** 8 compact Neo-Brutalist cards (`Open Tasks`, `In Progress`, `Completed`, `Active Projects`, `Active Staff`, etc.) with `JetBrains Mono` numbers (`26px`, weight `700`).
  3. **Project Health List:** Top active projects showing `P-XXXX` tag, Client Name, animated `8px`-tall progress bar, and overdue badge.
  4. **Risk & Bottleneck Feed:** Compact cards for dependency-blocked or stale tasks.
- **Staff View (`staff_dashboard_view.dart`):**
  1. **Today's Compliance Banner (Top):** Full-width status card. If today's report is unsubmitted, show a Violent Red border + `[LOG TODAY'S REPORT NOW]` button. If submitted, show a Pitch Black `[SUBMITTED — ON TIME]` badge and latest manager review note.
  2. **"WORK ON THIS NEXT" Hero Card:** Highlights the #1 top-ranked task from the priority queue with a prominent violent red `NEXT UP` tag, deadline countdown, and 1-tap `[UPDATE STATUS]` action.
  3. **Personal KPI Row (2x2 Grid):** `Due Today`, `Overdue`, `In Progress`, `Awaiting Review`.
  4. **Remaining Priority Queue:** Clean vertical stack of upcoming assigned tasks.

### Module 3: Projects & Milestones (`lib/screens/projects/`)
- **Projects List (`projects_list_screen.dart`):**
  - Sticky horizontal filter pill bar: `ALL`, `ACTIVE`, `COMPLETED`, `AT RISK` (no typing required).
  - Project Card Layout:
    - Top Row: `[P-XXXX]` monospace black badge + Priority tag (`CRITICAL` in Violent Red).
    - Middle: Project Title (`Space Grotesk`, `18px`, bold) + `CLIENT: <Client Name>` subtitle in uppercase grey monospace.
    - Bottom: Animated progress bar (`TweenAnimationBuilder`, `400ms`) with percentage in `JetBrains Mono`, plus footer stats (`12/18 TASKS • 2 OVERDUE`).
- **Project Detail (`project_detail_screen.dart`):**
  - Summary header card (Client, Start/Deadline dates, Weighted Progress %, Scope of Work expandable box).
  - **Vertical Milestone Stepper:** Connected by a `2px` vertical black line. Completed milestones show a solid black square `[✓]`; pending milestones show a hollow square `[ ]` with due date and deliverables pill.
  - Horizontal avatar/name strip of assigned team members (`MEMBER` vs `VIEWER`).
  - Full-width black button: `[VIEW ALL PROJECT TASKS ->]`.

### Module 4: Tasks, Mobile Kanban & Extensions (`lib/screens/tasks/`)
- **Tasks Screen (`tasks_screen.dart`):**
  - **Top Bar Switcher:** Segmented Neo-Brutalist toggle: `[ ≡ LIST VIEW ]` | `[ ▤ KANBAN BOARD ]`.
  - **1-Tap Filter Pills:** `ALL`, `MY PRIORITY`, `OVERDUE`, `IN PROGRESS`, `BLOCKED`, `PENDING REVIEW`.
  - **Mobile Kanban Mode:** Horizontal `PageView` with `viewportFraction: 0.88` so users can see the edge of the next column and swipe smoothly between `NOT STARTED`, `IN PROGRESS`, `BLOCKED`, `PENDING REVIEW`, and `COMPLETED`. Each column header shows the task count in `JetBrains Mono`.
- **Task Detail (`task_detail_screen.dart`):**
  - **Dependency Lock Alert:** If `openDependenciesCount > 0`, display a high-visibility Violent Red banner at the very top: `LOCKED: COMPLETE PREDECESSOR TASKS FIRST`.
  - **1-Tap Status Controller:** Renders `allowedStatuses` as bold tactile buttons. Tapping `BLOCKED` or `COMPLETED` opens a crisp modal asking for the mandatory completion/blocker note.
  - **Interactive Progress Slider:** Drag from `0%` to `100%` with a `[SAVE %]` button.
  - **Subtasks Checklist & Dependencies List.**
  - **Deadline Extension Box:** Staff gets a `[REQUEST DEADLINE EXTENSION]` button opening a date picker + reason modal. Admins see pending extension requests right at the top with 1-tap `[APPROVE]` (Black) and `[REJECT]` (Violent Red) buttons.

### Module 5: 30-Second Daily Reports & Manager Review (`lib/screens/reports/`)
- **Staff Submission Wizard (`report_submission_screen.dart`):**
  - Designed for zero-typing speed:
    1. **Project & Task Selector:** Pre-populated cards/dropdowns from `today-context`.
    2. **Quick Time Logger:** 5 tactile chips (`[15m]`, `[30m]`, `[1h]`, `[2h]`, `[4h]`) that set or increment minutes with haptic feedback, paired with a manual `JetBrains Mono` minute input.
    3. **Task Progress Slider:** `0%` to `100%`.
    4. **Structured Inputs:** `Work Completed Today` (required), `Blockers / Delays` (optional), and `Next Plan` (optional).
    5. **Dual Sticky Footer Buttons:** `[SAVE DRAFT]` (White with Black border) and `[SUBMIT REPORT]` (Violent Red `#FF0033` with Black border).
- **Reports Feed & Admin Review Inbox (`reports_list_screen.dart`):**
  - Filter Pills: `ALL`, `PENDING REVIEW`, `APPROVED`, `RETURNED / REJECTED`, `LATE`.
  - Report Card shows Employee Name, Date, `1h 30m` badge, `LATE` red tag (if `isLate == true`), project/task code, and work summary preview.
  - **Admin 1-Tap Review Sheet:** Tapping any pending report opens a bottom sheet with a manager comment input and 3 buttons: `[APPROVE]`, `[REQUEST CLARIFICATION]`, and `[REJECT]`.
  - **Staff Revision Loop:** If a report is `rejected` or `clarification_requested`, tapping it displays the manager's feedback box in Violent Red at the top and opens the form pre-filled for immediate revision.

### Module 6: Reusable Tactile Micro-Interaction Widget (`lib/core/widgets/brutalist_Pressable.dart`)
Ensure interactive cards and primary buttons use a shared press wrapper:
- `AnimatedContainer` (`duration: Duration(milliseconds: 100)`, `curve: Curves.easeOut`).
- Default state: `transform: Matrix4.translationValues(0, 0, 0)` with `BoxShadow(color: Color(0xFF0A0A0A), offset: Offset(4, 4), blurRadius: 0)`.
- Pressed state (`onTapDown`): `transform: Matrix4.translationValues(2, 2, 0)` with `BoxShadow(color: Color(0xFF0A0A0A), offset: Offset(2, 2), blurRadius: 0)` and `HapticFeedback.lightImpact()`.