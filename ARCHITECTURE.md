# \# Mboa Health - Architecture

# 

# Reference document. Update whenever implementation changes the structure described here.

# Complements the Current System Specification (what exists) with how it's organized (why it's

# structured this way).

# 

# \## Stack

# 

# Flutter/Dart frontend (feature-first structure), Provider (`ChangeNotifier` + `MultiProvider`)

# for state, PHP backend under `backend/api/`, one folder per resource, JWT-based auth.

# 

# \## Frontend structure

# lib/

# +-- core/

# |   +-- config/       - api\_config.dart (single source of endpoint URLs)

# |   +-- constants/     - AppColors, AppSpacing, AppTypography ("Clinical Sanctuary" design system)

# |   +-- models/         - domain models (AppUser, HealthRecord, Reminder, Notification, Clinic)

# |   +-- network/        - api\_client.dart (single HTTP client, JWT attached per request)

# |   +-- routing/        - app\_routes.dart (named routes, AuthGuard-protected route list)

# |   +-- security/        - security.dart (barrel export), auth\_guard.dart, rate\_limiter.dart, security\_utils.dart

# |   +-- services/        - notification\_service.dart (local push, on-device)

# |   +-- storage/          - secure\_storage.dart (JWT only, encrypted)

# |   +-- theme/            - app\_theme.dart

# +-- features/

# |   +-- <feature>/

# |       +-- <screen>\_screen.dart

# |       +-- providers/     - ChangeNotifier per feature, where the feature has server state

# |       +-- <sub>/          - sub-screens (e.g. health\_records/add\_record/, health\_records/analysis\_result/)

# +-- shared/widgets/          - GradientButton, AppInputField, AppCard, AmbientBlob

# 

# Not every feature has a `providers/` folder. `emergency/emergency\_portal\_screen.dart` calls

# `ApiClient` directly for its Alert Contacts action rather than going through a provider; this

# is the one screen that departs from the provider convention, worth keeping in mind since the

# QR Passport work (Tasks 4 through 6) extends this same screen.

# 

# \## State management

# 

# `MultiProvider` in `app.dart` registers one `ChangeNotifier` per feature with server state:

# `AuthProvider`, `ProfileProvider`, `HealthRecordsProvider`, `RemindersProvider`,

# `NotificationsProvider`, `ClinicLocatorProvider`, `SymptomCheckerProvider`. `ProfileProvider`

# is the source for blood type, allergies, and emergency contacts, all three come back together

# in one `fetchProfile()` call.

# 

# \## Security module (already implemented, not previously documented outside code comments)

# 

# `lib/core/security/security.dart` maps directly to OWASP Top 10 categories:

# 

# \- \*\*A01, Broken Access Control\*\* -> `AuthGuard`, route-level, enforced in `app\_routes.dart`

# \- \*\*A02, Cryptographic Failures\*\* -> `SecureStorage` (JWT via `flutter\_secure\_storage`,

# &#x20; encrypted Android prefs, never `SharedPreferences`), plus client-side password pre-hash

# &#x20; before transmission, bcrypt server-side

# \- \*\*A03, Injection\*\* -> `InputSanitizer` in `security\_utils.dart`, XSS/SQL pattern detection

# &#x20; on form inputs

# \- \*\*A07, Auth Failures\*\* -> `AppValidators` (password policy, email/phone validation),

# &#x20; `RateLimiter` (client-side, in-memory, wired into `login\_screen.dart`, does not protect

# &#x20; the API endpoint directly, see DECISIONS.md ADR-005)

# 

# No local database or file-based cache exists for health records. Data is fetched from the

# API per view, not persisted unencrypted on-device. The only persistent local secret is the

# JWT, which is encrypted.

# 

# \## Backend structure

# backend/

# +-- api/

# |   +-- auth/                - get\_salt, login, register, me, forgot\_password, reset\_password

# |   +-- profile/              - index (GET/PUT, includes stats + emergency\_contacts), upload\_avatar

# |   +-- clinics/                - index (GET, no auth required)

# |   +-- emergency\_contacts/      - index (GET, POST, PUT, DELETE - PUT not yet called by the frontend)

# |   +-- health\_records/           - index (full CRUD)

# |   +-- reminders/                  - index (full CRUD)

# |   +-- notifications/               - index (GET, mark\_read, mark\_all\_read)

# +-- db.php, helpers.php, index.php, config.example.php

# +-- schema.sql

# 

# No QR passport endpoint exists yet. When added (Task 4), it must be a separate file, not a

# shared router with the authenticated passport routes, per DECISIONS.md ADR-001.

# 

# \## Known data risk, not yet resolved

# 

# `backend/schema.sql` and `backend/seed\_clinics.php` contain two different, non-overlapping

# clinic datasets (10 rows vs. 11 rows, zero shared names). Which one is actually live has not

# been confirmed. See RISK\_REGISTER.md.

