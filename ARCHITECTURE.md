# Mboa Health - Architecture

Reference document. Update whenever implementation changes the structure described here.
Complements the Current System Specification (what exists) with how it's organized (why it's
structured this way).

## Stack

Flutter/Dart frontend (feature-first structure), Provider (`ChangeNotifier` + `MultiProvider`)
for state, PHP backend under `backend/api/`, one folder per resource, JWT-based auth.

## Frontend structure

```
lib/
├── core/
│   ├── config/       - api_config.dart (single source of endpoint URLs)
│   ├── constants/     - AppColors, AppSpacing, AppTypography ("Clinical Sanctuary" design system)
│   ├── models/         - domain models (AppUser, HealthRecord, Reminder, Notification, Clinic)
│   ├── network/        - api_client.dart (single HTTP client, JWT attached per request)
│   ├── routing/        - app_routes.dart (named routes, AuthGuard-protected route list)
│   ├── security/        - security.dart (barrel export), auth_guard.dart, rate_limiter.dart, security_utils.dart
│   ├── services/        - notification_service.dart (local push, on-device)
│   ├── storage/          - secure_storage.dart (JWT only, encrypted)
│   └── theme/            - app_theme.dart
├── features/
│   └── <feature>/
│       ├── <screen>_screen.dart
│       ├── providers/     - ChangeNotifier per feature, where the feature has server state
│       └── <sub>/          - sub-screens (e.g. health_records/add_record/, health_records/analysis_result/)
└── shared/widgets/          - GradientButton, AppInputField, AppCard, AmbientBlob
```

Not every feature has a `providers/` folder. `emergency/emergency_portal_screen.dart` calls
`ApiClient` directly for its Alert Contacts action rather than going through a provider; this
is the one screen that departs from the provider convention, worth keeping in mind since the
QR Passport work (Task 4–6) extends this same screen.

## State management

`MultiProvider` in `app.dart` registers one `ChangeNotifier` per feature with server state:
`AuthProvider`, `ProfileProvider`, `HealthRecordsProvider`, `RemindersProvider`,
`NotificationsProvider`, `ClinicLocatorProvider`, `SymptomCheckerProvider`. `ProfileProvider`
is the source for blood type, allergies, and emergency contacts, all three come back together
in one `fetchProfile()` call.

## Security module (already implemented, not previously documented outside code comments)

`lib/core/security/security.dart` maps directly to OWASP Top 10 categories:

- **A01, Broken Access Control** → `AuthGuard`, route-level, enforced in `app_routes.dart`
- **A02, Cryptographic Failures** → `SecureStorage` (JWT via `flutter_secure_storage`,
  encrypted Android prefs, never `SharedPreferences`), plus client-side password pre-hash
  before transmission, bcrypt server-side
- **A03, Injection** → `InputSanitizer` in `security_utils.dart`, XSS/SQL pattern detection
  on form inputs
- **A07, Auth Failures** → `AppValidators` (password policy, email/phone validation),
  `RateLimiter` (client-side, in-memory, wired into `login_screen.dart`, does not protect
  the API endpoint directly, see DECISIONS.md ADR-005)

No local database or file-based cache exists for health records. Data is fetched from the
API per view, not persisted unencrypted on-device. The only persistent local secret is the
JWT, which is encrypted.

## Backend structure

```
backend/
├── api/
│   ├── auth/                - get_salt, login, register, me, forgot_password, reset_password
│   ├── profile/              - index (GET/PUT, includes stats + emergency_contacts), upload_avatar
│   ├── clinics/                - index (GET, no auth required)
│   ├── emergency_contacts/      - index (GET, POST, PUT, DELETE - PUT not yet called by the frontend)
│   ├── health_records/           - index (full CRUD)
│   ├── reminders/                  - index (full CRUD)
│   └── notifications/               - index (GET, mark_read, mark_all_read)
├── db.php, helpers.php, index.php, config.example.php
└── schema.sql
```

No QR passport endpoint exists yet. When added (Task 4), it must be a separate file, not a
shared router with the authenticated passport routes, per DECISIONS.md ADR-001.

## Known data risk, not yet resolved

`backend/schema.sql` and `backend/seed_clinics.php` contain two different, non-overlapping
clinic datasets (10 rows vs. 11 rows, zero shared names). Which one is actually live has not
been confirmed. See RISK_REGISTER.md.
