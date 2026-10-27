# College Bus Attendance Tracking System 🚌

A production-ready College Bus Attendance Tracking System built with **Flutter** (Conductor Mobile App & Admin Web Dashboard) and **Supabase** (PostgreSQL, Row-Level Security, Edge Functions, and Realtime).

---

## 🌟 Key Features

### 1. Conductor Mobile App (`lib/main.dart`)
- **Fast Barcode Scanner**: Powered by `mobile_scanner` with live camera preview, torch toggle, pause/resume, and instant roll number validation.
- **Idempotent Real-time Scanning**: Prevents double scans; duplicate scans within the same session display a clear amber alert with the original scan time.
- **Session Intelligence**: Conductors see today's morning and evening trips, open/closed status, and student scan counts.
- **Conductor Authentication**: Username + Bus Number login with secure token exchange.
- **Session Summary**: Live list of scanned students for the current trip.

### 2. Admin Dashboard (`lib/main_admin.dart`)
- **Real-Time Live Attendance Monitoring**: Realtime WebSocket subscription pushes scan events instantly to KPI cards and the live table without manual reload.
- **Fleet & Bus Management**: Manage buses, route descriptions, and assign conductors.
- **Trip Session Controls**: Create, open, and close morning and evening sessions per calendar date.
- **Student Database & CSV Import**:
  - Searchable student directory with active/bus-eligible toggles.
  - CSV bulk importer with header validation, duplicate checking, preview list, and upsert logic.
  - Standard CSV template included in `assets/csv_template.csv`.
- **Analytics & Reporting**:
  - Filter by date range, morning/evening trips, bus number, or department.
  - KPI summaries (Total Scans, Morning, Evening, Active Fleet).
  - Department breakdown analytics.
  - One-click **Export to CSV**.

### 3. Enterprise Security & Backend
- **PostgreSQL Database**: Complete schema with foreign keys, constraints, and audit logs.
- **Row-Level Security (RLS)**: Enforces access controls so conductors can only query their assigned bus/sessions.
- **Edge Functions**:
  - `record-attendance`: Validates student eligibility, session state, and conductor assignment with idempotency.
  - `conductor-login`: Authenticates conductor credentials and verifies active bus assignment.
  - `admin-bootstrap`: One-time administrative bootstrap.

---

## 📁 Project Architecture

```
college_bus_attendance/
├── lib/
│   ├── main.dart                      # Conductor mobile entry point
│   ├── main_admin.dart                # Admin dashboard web entry point
│   ├── app/
│   │   ├── router.dart                # go_router with role-based routing guards
│   │   └── theme.dart                 # Material 3 ColorScheme & typography
│   ├── core/
│   │   ├── config/supabase_config.dart # Preconfigured Supabase URL & publishable key
│   │   ├── constants/app_constants.dart# System-wide constants & regexes
│   │   ├── errors/app_exception.dart  # Type-safe application exceptions
│   │   └── utils/                     # Date and roll number normalization utilities
│   └── features/
│       ├── admin_dashboard/           # Live KPI cards and Realtime attendance table
│       ├── attendance/                # Attendance repository and models
│       ├── auth/                      # Conductor & Admin login pages and providers
│       ├── barcode_scanner/           # Camera preview, debouncing, and result UI
│       ├── buses/                     # Fleet CRUD & conductor assignment
│       ├── conductor/                 # Conductor home and session summary UI
│       ├── reports/                   # Date range analytics, KPIs, CSV export
│       ├── sessions/                  # Attendance trip session lifecycle management
│       └── students/                  # Student CRUD table and CSV bulk import
├── supabase/
│   ├── migrations/
│   │   ├── 001_schema.sql             # Full database schema and indexes
│   │   ├── 002_rls.sql                # Row-Level Security policies
│   │   └── 003_seed_dev.sql           # Development seed data
│   └── functions/
│       ├── record-attendance/index.ts # Core attendance edge function
│       ├── conductor-login/index.ts   # Conductor auth edge function
│       └── admin-bootstrap/index.ts   # Admin initialization
├── test/
│   ├── unit/domain_models_test.dart   # Unit tests (models, regex, utils)
│   └── widget_test.dart               # Theme and widget smoke tests
└── assets/
    └── csv_template.csv               # Student import template
```

---

## 🚀 Getting Started

### 1. Prerequisites
- **Flutter SDK**: 3.27+ / 3.41+ stable
- **Dart SDK**: 3.6+ / 3.11+
- **Chrome** (for Admin Dashboard) or **Android Device / Emulator** (for Conductor App)

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Code Quality & Run Tests
```bash
# Verify analyzer passes with zero issues
flutter analyze

# Run unit and widget test suite
flutter test
```

### 4. Supabase Setup
The app comes preconfigured with your Supabase credentials in `lib/core/config/supabase_config.dart`:
- **Project URL**: `https://bunbenbtebciohrpcbyv.supabase.co`

In your Supabase project SQL Editor, run:
1. `supabase/migrations/001_schema.sql` (Creates tables, indexes, triggers, and enables Realtime)
2. `supabase/migrations/002_rls.sql` (Enables and configures RLS policies)
3. `supabase/migrations/003_seed_dev.sql` (Inserts initial test students, buses, and sessions)

### 5. Running the Apps

#### Conductor Mobile App
```bash
flutter run -t lib/main.dart
```

#### Admin Dashboard (Web)
```bash
flutter run -d chrome -t lib/main_admin.dart
```

---

## 📊 CSV Import Format
When uploading student rosters in **Admin Dashboard > Students > Import CSV**, use standard UTF-8 CSV:

```csv
roll_number,name,department,academic_year,bus_eligible
21CS001,John Doe,Computer Science,3rd Year,true
21ME045,Jane Smith,Mechanical,2nd Year,true
21EC012,Alex Kumar,Electronics,4th Year,false
```
A template is available in `assets/csv_template.csv`.

---

## 🧪 Testing Summary
All 9 test suites pass cleanly:
- ✅ Roll number regex and normalization validation
- ✅ Student JSON parsing and serialization
- ✅ Bus and fleet models
- ✅ Attendance session status lifecycle (scheduled / open / closed)
- ✅ Date formatting utilities
- ✅ Material 3 AppTheme initialization
