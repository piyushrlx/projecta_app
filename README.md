# Projecta — Enterprise Project Management Mobile Client

A Flutter mobile application that connects to the **Projecta PHP backend** (`d:\XAMP\htdocs\projecta\api\v1`) to provide enterprise-grade project, task, and report management for both **admin** and **staff** roles.

---

## 🏗️ Project Structure

```
projecta_app/
├── lib/
│   ├── main.dart                        # App entry point, loads saved API base URL
│   ├── core/
│   │   ├── api_client.dart              # Singleton HTTP client (GET/POST/PUT/PATCH/DELETE + auth headers)
│   │   └── theme.dart                   # Neo-Brutalist global theme (Space Grotesk + Inter + JetBrains Mono)
│   ├── models/
│   │   ├── user_model.dart              # Authenticated user profile data model
│   │   ├── project_model.dart           # Project + milestone data model
│   │   ├── task_model.dart              # Task + subtask + extension request model
│   │   ├── report_model.dart            # Daily work report data model
│   │   └── notification_model.dart      # Notification data model
│   ├── services/
│   │   ├── auth_service.dart            # Login, session, logout, password change
│   │   ├── dashboard_service.dart       # KPI, compliance, priority task fetch
│   │   ├── project_service.dart         # Projects list, detail, milestone toggle
│   │   ├── task_service.dart            # Tasks CRUD, status state-machine, extensions
│   │   ├── report_service.dart          # Daily report submit/review/history
│   │   └── notification_service.dart    # Notifications fetch + mark-read
│   └── screens/
│       ├── splash_screen.dart           # App entry splash with session check
│       ├── auth/
│       │   ├── login_screen.dart        # Login form screen
│       │   └── must_change_password_screen.dart  # Forced password change
│       ├── dashboard/
│       │   ├── dashboard_screen.dart    # Bottom nav shell (4 tabs + notification bell + FAB)
│       │   ├── admin_dashboard_view.dart  # Admin KPI + compliance overview
│       │   ├── staff_dashboard_view.dart  # Staff daily summary + priority tasks
│       │   └── widgets/
│       │       ├── kpi_card.dart        # Animated KPI metric card widget
│       │       └── compliance_card.dart # Team compliance/submission rate card
│       ├── projects/
│       │   ├── projects_list_screen.dart  # Projects list with filter chips
│       │   └── project_detail_screen.dart # Project scope, milestones, team
│       ├── tasks/
│       │   ├── tasks_screen.dart         # List + Kanban board view with filters
│       │   ├── task_detail_screen.dart   # Status transitions, subtasks, extensions
│       │   └── create_task_screen.dart   # Admin: assign new task form
│       ├── reports/
│       │   ├── reports_list_screen.dart  # Staff history / Admin review inbox
│       │   └── report_submission_screen.dart # Staff 30-second daily report wizard
│       └── notifications/
│           └── notifications_screen.dart # Notification feed + mark-all-read
├── android/
│   └── app/src/main/AndroidManifest.xml # Android permissions & app config
├── pubspec.yaml                          # Flutter dependencies & metadata
├── analysis_options.yaml                 # Dart static analysis rules
├── PROJECTA_COMPLETION_PLAN.md           # Phase 3 & 4 feature completion plan
└── README.md                             # This file
```

---

## 🎨 Design System — Neo-Brutalism

| Token | Value | Purpose |
|-------|-------|---------|
| `pitchBlack` | `#0A0A0A` | Background, borders |
| `pureWhite` | `#FFFFFF` | Cards, text on dark |
| `violentRed` | `#FF0033` | Primary action, alerts, FAB |
| `neutralGrey` | `#737373` | Muted labels |
| Border | `2px solid #0A0A0A` | All containers |
| Shadow | `Offset(4, 4) blur 0` | Hard neo-brutalist shadow |
| Heading font | Space Grotesk | Headings & app bar |
| Body font | Inter | Body text |
| Mono font | JetBrains Mono | Codes, IDs, numbers |

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.2 | REST API calls |
| `shared_preferences` | ^2.5.6 | Local token & user storage |
| `google_fonts` | ^6.2.1 | Space Grotesk, Inter, JetBrains Mono |
| `provider` | ^6.1.2 | State management |
| `intl` | ^0.20.3 | Date/time formatting |

---

## ⚙️ Setup & Running

### Prerequisites
- Flutter SDK `^3.12.2`
- XAMPP running with PHP backend at `d:\XAMP\htdocs\projecta\api\v1`
- Android device or emulator on the same LAN

### Backend API Base URL
| Environment | Default URL |
|-------------|-------------|
| Android (LAN) | `http://192.168.1.3/projecta/api/v1` |
| Desktop/Web | `http://localhost/projecta/api/v1` |

> The user can override the base URL from within the app settings. It is persisted via `SharedPreferences`.

### Run the App
```bash
flutter pub get
flutter run
```

---

## 🔐 Authentication Flow

1. `SplashScreen` → checks saved session via `AuthService.checkSession()`
2. If no valid session → `LoginScreen` (POST `/login.php`)
3. If `must_change_password == true` → `MustChangePasswordScreen`
4. On success → `DashboardScreen` (persistent bottom nav shell)

---

## 👤 Role-Based Features

| Feature | Staff | Admin / Super Admin |
|---------|-------|---------------------|
| Submit daily work report | ✅ (FAB) | — |
| Assign new task | — | ✅ (FAB) |
| Approve/reject reports | — | ✅ |
| Toggle milestone status | — | ✅ |
| View own tasks | ✅ | ✅ (all) |
| View projects | ✅ (assigned) | ✅ (all) |

---

## 🌿 Git Branches

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready code |
| `piyush-work` | Piyush's active development branch |

---

## 📋 Development Roadmap

See [`PROJECTA_COMPLETION_PLAN.md`](PROJECTA_COMPLETION_PLAN.md) for the full Phase 3 & 4 completion plan covering Projects, Tasks, Reports, and Notifications modules.

---

*Built by Piyush Bhatt — Projecta Enterprise Mobile Client v1.0.0*
