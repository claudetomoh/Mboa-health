# Mboa Health
## Current System Specification (CSS)
### Competition Build Baseline, Version 1.1
### Prepared for the ICT Innovation Challenge, Ministry of Posts and Telecommunications of Cameroon
### Date: 2026-07-14 (updated; original baseline 2026-07-06)

This document describes only functionality that is verifiably present in the Mboa Health source tree at `c:\Users\tomoh.ikfingeh\Downloads\mboa_health` as of the date above. Every claim below was checked against the Flutter client (`lib/`), the PHP backend (`backend/`), the database schema (`backend/schema.sql`), and the Android manifest. Where a UI element displays text that is not backed by real data or a real computation, that is stated explicitly rather than omitted. No roadmap or planned functionality is described as built.

**Revision note (2026-07-12):** this update incorporates six completed engineering tasks (internally tracked as CC-01 through CC-05B) that landed since the 2026-07-06 baseline: the Symptom Checker/Dashboard AI-claim correction, the Emergency Portal's Medical ID card being wired to real profile data, consolidation of Emergency Portal data access onto a single provider, a backend foundation for a Digital Health Passport (authenticated lifecycle + a separate public, token-only read endpoint), and a Flutter Digital Health Passport experience (status, QR generation, text view, regenerate/disable/enable) that supersedes the old Medical ID card. Every section below reflects the codebase as of this revision, not the 2026-07-06 baseline.

**Revision note (2026-07-14):** the Digital Health Passport work described in the 2026-07-12 revision has now been committed to git as a standalone, self-contained commit (`feat(passport): implement Digital Health Passport foundation`) covering the backend schema/endpoints, `helpers.php`'s `generate_secure_token()`, `PassportProvider`, `PassportSection`, provider registration in `app.dart`, `ApiConfig` entries, and the `qr_flutter` dependency. This revision re-verified every Passport claim below directly against that committed code (not merely the working tree) and found it accurate as written, with one unrelated correction: Section 9's endpoint count ("thirteen") was stale and has been corrected to fifteen, matching Section 2.4. No Passport-related statement required a factual change. Unrelated in-flight work still uncommitted at this revision (clinic-locator proximity UI, sign-up country picker, reminders reliability fixes, the Apache Authorization-header workaround in `lib/core/network/api_client.dart`, etc.) is intentionally out of scope for this note and remains accurately described elsewhere in this document as present in the source tree, regardless of its commit status.

---

## 1. Executive Summary

Mboa Health is a Flutter mobile application backed by a plain PHP/MySQL API, targeting patients in Cameroon. The application currently implements: account registration and login with OTP-based password reset, a profile with editable blood type and allergies, a health records log, a medication reminder system with local push notifications, an in-app notification center, an emergency contact directory with call and SMS shortcuts, a clinic locator with map search, and a symptom triage tool.

**Maturity assessment.** The system is a functioning single-developer MVP, not a production-hardened platform. The backend demonstrates several genuinely sound engineering practices for its size: every SQL statement uses parameterized PDO prepared statements, passwords are hashed client-side with SHA-256 and then server-side with bcrypt, JWT tokens are verified with constant-time signature comparison, and file uploads are validated by content-sniffed MIME type rather than client-supplied headers or filenames. At the same time, the deployment configuration transmits all traffic over plain HTTP with `usesCleartextTraffic` explicitly enabled, the live database password is stored in plaintext in a server-side config file, and a deployment script containing a plaintext SSH password is committed to version control. Test coverage is effectively zero (the only test file present is the unmodified Flutter project template).

**What is production-ready.** The authentication flow (registration, login, forgot/reset password), the health records CRUD flow, the reminders CRUD flow with working local notification scheduling, the notifications center, and the clinics search/locator are functionally complete end to end, client to database, with server-side validation and ownership checks on every record. The Emergency Portal's Digital Health Passport section (blood type, allergies, primary contact, QR generation, lifecycle actions) is also implemented end to end, client to database, though it has been verified by code trace and static analysis rather than a live device/emulator run — see 3.12 for the exact scope of that caveat.

**What is MVP quality or contains placeholder content.** Several screens present computed-looking information that is in fact static or hardcoded: the Clinic Details screen's opening hours and "About" paragraph and specialization list when a clinic has no services on file, and the Symptom Checker's "Recommended Clinic" card on the results screen. The Role Selection screen is entirely decorative: all three role cards navigate to the same login screen without recording a role. These are identified individually in Section 3 and summarized in Section 10. (As of this revision, the Emergency Portal's Medical ID card and the Symptom Checker's "AI" framing, both previously listed here, have been corrected — see 3.12 and 3.15.)

---

## 2. System Overview

### 2.1 Component summary

| Layer | Technology | Notes |
|---|---|---|
| Mobile client | Flutter (Dart SDK `^3.10.7`) | Single codebase, Android is the primary verified target |
| State management | `provider` package, `ChangeNotifier` | 8 provider classes, registered via `MultiProvider` |
| Networking | `http` package | Singleton `ApiClient`, JSON over HTTP |
| Local secure storage | `flutter_secure_storage` | JWT, email, role only |
| Local notifications | `flutter_local_notifications` + `timezone` | No push/FCM integration |
| Backend | Plain PHP, no framework | One `.php` file per endpoint, file-path-based routing |
| Database | MySQL (PDO driver) | 7 tables in `schema.sql`; an 8th (`password_resets`) is used by the auth code but absent from the schema file |
| Auth | Hand-rolled JWT (HMAC-SHA256) | No third-party JWT library |
| Hosting | Shared Apache hosting (cPanel-style) | Confirmed via `deploy.py` and `.htaccess` |

### 2.2 Architecture diagram

```
┌───────────────────────────────┐
│        Flutter Client          │
│                                │
│  Screens (lib/features/*)      │
│        │                       │
│        ▼                       │
│  ChangeNotifier Providers       │
│  (8 classes, MultiProvider)     │
│        │                       │
│        ▼                       │
│  ApiClient (lib/core/network)   │
│  - injects Bearer + X-Token     │
│  - 20s timeout, JSON envelope   │
│        │                       │
│        ▼                       │
│  flutter_secure_storage         │
│  (JWT / email / role at rest)   │
└───────────┬────────────────────┘
            │  HTTP (cleartext, not TLS)
            ▼
┌───────────────────────────────┐
│      PHP Backend (Apache)      │
│                                │
│  backend/api/<resource>/*.php   │
│  - require_auth() gate          │
│  - request_body() JSON parse    │
│  - json_ok() / json_error()     │
│        │                       │
│        ▼                       │
│  backend/helpers.php            │
│  (JWT encode/decode, CORS)      │
│        │                       │
│        ▼                       │
│  backend/db.php (PDO singleton) │
│        │                       │
│        ▼                       │
│  MySQL: mboa_health database    │
│  users, health_records,         │
│  reminders, clinics,            │
│  notifications,                 │
│  emergency_contacts,            │
│  emergency_passports            │
└───────────────────────────────┘
```

A separate, unauthenticated public endpoint (`backend/api/passport/view.php`) reads from `emergency_passports` and `users`/`emergency_contacts` without going through the `require_auth()` gate shown above — it is deliberately not part of the authenticated request path in this diagram. See 6.8 and `DECISIONS.md` ADR-001.

### 2.3 Mobile application

The Flutter app follows a feature-first layout. Each feature under `lib/features/<name>/` bundles its own screen widgets and, where the feature has mutable state, a `providers/` subfolder holding a single `ChangeNotifier` class. Cross-cutting code lives in `lib/core/`: `network/` (the HTTP client), `security/` (validators, session guard, rate limiter), `storage/` (secure storage wrapper), `services/` (notifications), `routing/` (named routes), `models/` (data classes), `config/` (API base URL and endpoint constants), `constants/` and `theme/` (design tokens). Shared presentational widgets live in `lib/shared/widgets/`.

### 2.4 Backend

The backend has no framework and no central dispatcher. `backend/index.php` is a static JSON information page, not a router. Each concrete endpoint is its own file under `backend/api/<resource>/`, and within that file the code branches on `$_SERVER['REQUEST_METHOD']`. Fifteen endpoint files exist in total across eight resources: auth (6 files), profile (2 files), clinics (1), emergency contacts (1), health records (1), reminders (1), notifications (1), passport (2 files — `index.php` authenticated lifecycle, `view.php` public read).

### 2.5 Database

Seven tables are defined in `backend/schema.sql`: `users`, `health_records`, `reminders`, `clinics`, `notifications`, `emergency_contacts`, `emergency_passports`. All foreign keys reference `users.id` with `ON DELETE CASCADE`, except `clinics`, which is a standalone reference table with no foreign key relationships. An eighth table, `password_resets`, is read from and written to by the password-reset endpoints but does not appear in `schema.sql`; it must exist in the live database by some means not captured in the checked-in schema file. This is a documentation gap, not a runtime bug, since the live deployment evidently works. The new `emergency_passports` table (added for the Digital Health Passport) has not yet been applied to the live database — see 7's `emergency_passports` entry and RISK_REGISTER.md.

### 2.6 Authentication

Authentication is JWT-based, hand-implemented in `backend/helpers.php` with HMAC-SHA256 signing, no third-party library. Passwords are hashed twice: client-side with SHA-256 salted with a per-user random salt, then server-side with bcrypt (cost factor 12) on top of the client hash. Session state on the client is held in two places: an in-memory static `AuthGuard` (8-hour duration, used for fast route-guard checks) and `flutter_secure_storage` (used to persist the JWT, email, and role across app restarts and to restore the session on launch).

### 2.7 APIs

All endpoints exchange JSON. Every response follows one of two shapes: `{"success": true, "data": {...}}` or `{"success": false, "message": "...", ...extra}`. All protected endpoints require an `Authorization: Bearer <token>` header; a parallel `X-Token` header is also sent and accepted on both client and server as a workaround for the hosting environment stripping the standard `Authorization` header on some request types.

### 2.8 Local storage

Only `flutter_secure_storage` is used for persistence in application code. `shared_preferences` is declared as a dependency in `pubspec.yaml` but is not imported anywhere in `lib/`; it is unused. There is no local database (no `sqflite`, no `hive`) — the app has no offline data cache. All record lists (health records, reminders, notifications, clinics) are fetched fresh from the API on each screen load and held only in provider memory for the session.

### 2.9 Notifications

The app uses `flutter_local_notifications` exclusively for on-device scheduled medication reminders. There is no push notification service (no Firebase Cloud Messaging, no APNs integration); the in-app "Notifications" feature (Section 3.9) is a separate, server-backed list of messages and is unrelated to the local notification scheduler. On web builds, the notification service is a no-op by design, since the underlying plugin does not support web.

### 2.10 External packages

See Section 8 for the complete package inventory with usage evidence for each.

### 2.11 State management

State management is the `provider` package using `ChangeNotifier`. Eight provider classes exist, one per stateful feature: `AuthProvider`, `ProfileProvider`, `HealthRecordsProvider`, `RemindersProvider`, `NotificationsProvider`, `ClinicLocatorProvider`, `SymptomCheckerProvider`, `PassportProvider`. All eight are registered in a single `MultiProvider` in `lib/app.dart`. There is no `riverpod`, `bloc`, or `get_it` dependency injection anywhere in the codebase.

### 2.12 Folder structure

```
lib/
├── main.dart               bootstrap: orientation lock, notification init, runApp
├── app.dart                MultiProvider + MaterialApp + theme + routing
├── core/
│   ├── config/             API base URL and endpoint path constants
│   ├── constants/          colors, spacing, typography tokens
│   ├── models/              5 data model classes
│   ├── network/             ApiClient singleton
│   ├── routing/             AppRoutes: named routes, route guard, onGenerateRoute
│   ├── security/            validators, sanitizer, password hasher, auth guard, rate limiter
│   ├── services/            NotificationService
│   ├── storage/             SecureStorage wrapper
│   └── theme/               AppTheme
├── features/                one folder per feature, screens + providers/
└── shared/widgets/          AppCard, AppInputField, GradientButton, AmbientBlob

backend/
├── index.php               static JSON info page, not a router
├── helpers.php              JWT, CORS, response helpers, require_auth()
├── db.php                   PDO singleton connection
├── config.php / config.example.php
├── schema.sql
├── seed_admin.php, seed_clinics.php    one-off provisioning scripts
└── api/
    ├── auth/                6 files: get_salt, register, login, me, forgot_password, reset_password
    ├── profile/              index (GET/PUT), upload_avatar
    ├── clinics/              index (GET only, public)
    ├── emergency_contacts/   index (full CRUD)
    ├── health_records/       index (full CRUD, soft delete)
    ├── reminders/            index (full CRUD, hard delete)
    ├── notifications/        index (GET, mark-read actions)
    └── passport/              index.php (authenticated: status/create/enable/regenerate/disable),
                                view.php (public, unauthenticated, token-only lookup)
```

The Emergency feature folder (`lib/features/emergency/`) now also contains `providers/passport_provider.dart` (a `ChangeNotifier`, one of the eight providers listed in 2.11) and `passport_section.dart` (the Digital Health Passport widget, described in 3.12), alongside the pre-existing `emergency_portal_screen.dart`.

---

## 3. Current Features

For each feature: purpose, status, mechanism, backend surface, database surface, dependencies, and known limitations. A screenshot checklist entry is included per screen; see Section 11 for the consolidated capture list.

### 3.1 Authentication — Registration

**Status:** Implemented.

**Description:** `lib/features/auth/sign_up/sign_up_screen.dart`. A form collects full name, email, a country selector (36 hardcoded countries, default Cameroon) used only to prefix the phone field with a dial code, phone number, password, password confirmation, and a mandatory terms checkbox.

**How it works:** Full name is validated against a regex that permits only letters, spaces, hyphens, and apostrophes (`AppValidators.validateFullName`), 2 to 100 characters. Email is checked with `AppValidators.validateEmail`. Password must be 8 to 128 characters and contain uppercase, lowercase, a digit, and a special character (`AppValidators.validateNewPassword`); a live strength bar reflects this. On submit, the name is passed through `InputSanitizer.sanitize`, a random salt is generated client-side (`PasswordHasher.generateSalt`), the password is hashed client-side with SHA-256 over `salt:password`, and the result is sent to the server. The role sent to the server is always the literal string `patient`, regardless of anything selected on the earlier Role Selection screen (see 3.14).

**Backend endpoint:** `POST /api/auth/register.php`. Validates name length, email format, password-hash length (≥32 chars, i.e. a hex SHA-256 string), salt presence, and an optional phone regex. Forces `role` to `patient` or `doctor` only; any other value including `admin` is silently downgraded to `patient`, so admin accounts cannot be created through this endpoint. Re-hashes the incoming client hash with bcrypt (cost 12) before storing it. Returns `409` on duplicate email with a generic message that does not confirm or deny which field collided.

**Database:** Inserts into `users` (`full_name`, `email`, `phone`, `password_hash`, `salt`, `role`). Also inserts a welcome row into `notifications`.

**Dependencies:** `crypto` (client hashing), `google_fonts`, `provider`.

**Limitations:** No email verification step exists; an account is usable immediately after registration. No CAPTCHA or bot mitigation beyond the client-side rate limiter described in 3.16.

**Screenshot needed:** Sign Up screen, empty state and with validation errors showing.

### 3.2 Authentication — Login

**Status:** Implemented.

**Description:** `lib/features/auth/login/login_screen.dart`. Email and password fields, a "Forgot?" link, a link to Sign Up, and two social-login buttons.

**How it works:** Before submission, `RateLimiter.isLockedOut(email)` is checked client-side (in-memory only, resets on app restart): 5 failed attempts within a 15-minute window trigger a 30-minute lockout. On submit, the client requests the user's salt via `fetchSalt`, hashes the password client-side, then posts the hash to the login endpoint. The two "Google" and "Apple" buttons only display a "coming soon" SnackBar; they perform no OAuth flow and are non-functional placeholders.

**Backend endpoint:** `POST /api/auth/login.php`. Runs a single combined query for the user row rather than separate existence/password checks, and always calls `password_verify()` even when no matching user is found (comparing against a dummy bcrypt hash) so that response timing does not reveal whether an email is registered. Returns a generic `401` on any failure.

**Database:** Reads from `users`; no writes.

**Limitations:** The client-side rate limiter is in-memory and per-app-instance; it does not survive an app restart and provides no protection against distributed or scripted attacks, since there is no server-side rate limiting on the login endpoint itself.

**Screenshot needed:** Login screen, default state and lockout-error state.

### 3.3 Authentication — Password Reset

**Status:** Implemented.

**Description:** Two screens: `forgot_password_screen.dart` (email entry) and `reset_password_screen.dart` (6-digit OTP entry plus new password).

**How it works:** Forgot Password posts the email; the server always returns the same generic success message regardless of whether the email exists, and rate-limits code generation to 3 codes per 15 minutes per email. A 6-digit numeric code is emailed via PHP's `mail()` function with a 15-minute expiry. Reset Password collects the 6 digits into individual auto-advancing boxes, validates the new password against the same complexity policy as registration, and posts the code with a freshly generated salt and hash.

**Backend endpoints:** `POST /api/auth/forgot_password.php`, `POST /api/auth/reset_password.php`. The reset endpoint verifies the code against `password_resets` (`email`, `token`, `used=0`, `expires_at > NOW()`), marks it used, and updates the user's `password_hash` and `salt`.

**Database:** `password_resets` table (used by code, not present in `schema.sql`; see Section 7), `users`.

**Limitations:** Email delivery uses PHP `mail()` with errors suppressed; there is no delivery-failure observability, so a misconfigured mail server would fail silently from the operator's perspective while the user sees a generic success message either way.

**Screenshot needed:** Forgot Password screen; Reset Password screen with OTP boxes.

### 3.4 Onboarding

**Status:** Implemented (static content).

**Description:** `lib/features/onboarding/onboarding_screen.dart`. A three-page `PageView` with fixed marketing copy ("Find the Right Care Faster", "Emergency Help in Seconds", "Your Health, Anywhere") illustrated with native Flutter widget compositions, no images or network calls. Skip and Next controls lead to Role Selection, and a "Already have an account? Log In" link on the final page leads directly to Login.

**Limitations:** None functionally; this is intentionally static content and behaves as such.

**Screenshot needed:** All three onboarding pages.

### 3.5 Splash Screen

**Status:** Implemented.

**Description:** `lib/features/splash/splash_screen.dart`. Displays an animated brand mark for a fixed 2.8-second delay, then calls `AuthProvider.tryRestoreSession()`, which calls `GET /api/auth/me.php` using any token found in secure storage. On success it routes to Dashboard; on failure it routes to Onboarding. There is no visible error state if session restoration fails; the app falls through silently to Onboarding.

**Screenshot needed:** Splash screen during the loading animation.

### 3.6 Role Selection

**Status:** Placeholder / non-functional.

**Description:** `lib/features/role_selection/role_selection_screen.dart`. Presents three cards: Patient, Health Worker, Clinic Admin.

**How it actually works:** All three cards navigate to the identical Login route. No role value is captured, stored, or transmitted anywhere as a result of this screen. Registration always submits `role: 'patient'` regardless of what was tapped here (see 3.1). This screen currently has no effect on application behavior beyond acting as a second onboarding-style splash before Login.

**Limitations:** This is the clearest example in the codebase of UI that visually implies a capability, role-based account creation, that is not wired to any backend logic.

**Screenshot needed:** Role Selection screen.

### 3.7 Dashboard

**Status:** Implemented.

**Description:** `lib/features/dashboard/dashboard_screen.dart`. The home hub after login. On load it fetches the profile and the reminders list. It shows a greeting with the user's first name, a tappable avatar (opens the image picker and uploads immediately), a "Daily Insight" health tip banner, a 4-item action grid (Check Symptoms, Find Clinic, Emergency, My Records), an "Upcoming" reminders list, and a bottom navigation bar.

**How it works:** The Daily Insight banner selects from a fixed list of 7 tips indexed by the current day of the week (`DateTime.now().weekday`); it is not personalized and not sourced from any API. The action grid links to Symptom Checker, Clinic Locator, Emergency Portal, and Health Records respectively. The upcoming-reminders section shows a loading spinner while `RemindersProvider` is fetching and an empty-state card with a "Set a reminder" shortcut when there are none.

**Backend endpoints called:** `GET /api/profile/index.php`, `GET /api/reminders/index.php`, and (on avatar tap) `POST /api/profile/upload_avatar.php`.

**Limitations:** As of 2026-07-12, the "Check Symptoms" card subtitle reads "Quick rule-based symptom guidance," correctly describing the underlying feature (3.15), a deterministic rule engine, not an AI model. Provider-level errors from the profile or reminders fetch are not surfaced on this screen.

**Screenshot needed:** Dashboard, both with reminders present and in the empty-reminders state.

### 3.8 User Profile

**Status:** Implemented, with two non-functional settings entries.

**Description:** `lib/features/profile/profile_screen.dart` and `providers/profile_provider.dart`. Shows an avatar upload control, two static badge chips ("Premium Member", "Verified Pro") that are not derived from any subscription or verification data, a stats grid (blood type, record count, reminder count, contact count, the latter three sourced live from the API), an emergency contacts section, and an account settings section.

**How it works:** "Personal Information" opens a bottom sheet to edit full name, phone, blood type (a `ChoiceChip` grid of the 8 standard blood types), and allergies (free text), which is sent via `PUT /api/profile/index.php`. "Notification Settings" routes to the real Notifications screen (3.9). "Privacy & Security" and "Language" both only display a "coming soon" SnackBar and do nothing else; the "Language" row's sub-label "English (US)" is a hardcoded string, not a read of any actual locale setting. The footer displays a static string, "Version 2.4.1 (Clinical Build)", which is not sourced from package/build metadata.

**Emergency contacts within Profile:** Listed from `GET /api/profile/index.php` (embedded in the profile response), with call and delete actions and an add-contact bottom sheet (full name and phone required, relationship optional, a "Primary Contact" switch). Add posts to `POST /api/emergency_contacts/index.php`; delete calls `DELETE /api/emergency_contacts/index.php?id=`. Validation on this form is presence-only; there is no phone-format regex enforced client-side here (unlike the phone field in Sign Up), though the server does enforce a phone regex.

**Backend endpoints:** `GET/PUT /api/profile/index.php`, `POST /api/profile/upload_avatar.php`, `POST/DELETE /api/emergency_contacts/index.php`.

**Database:** `users` (blood_type, allergies, avatar_url, full_name, phone columns), `emergency_contacts`.

**Limitations:** "Privacy & Security" and "Language" are visually indistinguishable from working settings rows until tapped. Duplication note: the blood-type option list (`A+, A-, B+, B-, AB+, AB-, O+, O-`) is defined identically in this file and again in the Add Health Record screen (3.10), with two different UI treatments (chips here, a dropdown there) for the same data.

**Screenshot needed:** Profile screen main view; Personal Information bottom sheet; Add Emergency Contact bottom sheet.

### 3.9 Health Records

**Status:** Implemented.

**Description:** `lib/features/health_records/health_records_screen.dart`, `add_record/add_record_screen.dart`, `analysis_result/analysis_result_screen.dart`, `providers/health_records_provider.dart`. A list of a user's medical records with client-side search over title, doctor, and facility, and a "Filters" chip that is present but has no attached action.

**How it works:** Adding a record collects a description (sanitized and checked for SQL/script-injection patterns via `InputSanitizer`), optional doctor and facility names, an optional blood type (which, if set, also triggers a profile update), a category (mapped to the backend's type enum: prescription, lab report, vaccination, other), and a required date. A photo/document upload control lets the user pick an image from camera or gallery, but the picked bytes are held only in local widget state and are never included in the save payload or uploaded anywhere; this control currently has no effect on the saved record. A footer disclaimer states records are "encrypted and stored securely following clinical data protection standards"; no client-side encryption of this data actually occurs beyond standard HTTPS/TLS transport, which in the current deployment is not even enabled (Section 9).

**Backend endpoint:** Full CRUD at `POST/GET/PUT/DELETE /api/health_records/index.php`. Delete is a soft delete (`is_active = 0`), not a row removal. Every read and write is scoped to the authenticated user's `id`.

**Database:** `health_records` table (`type`, `title`, `doctor`, `facility`, `date`, `file_url`, `notes`, `is_active`).

**Limitations:** The document/photo attachment UI is decorative; no file is ever transmitted for a health record despite the presence of a `file_url` column and an upload control in the form. The "Filters" chip has no behavior.

**Screenshot needed:** Health Records list (populated and empty states); Add Record form.

### 3.10 Medication Reminders

**Status:** Implemented.

**Description:** `lib/features/reminders/reminders_screen.dart`, `add_reminder/add_reminder_screen.dart`, `providers/reminders_provider.dart`, and `lib/core/services/notification_service.dart`.

**How it works:** Adding a reminder requires a title, a time, and a frequency chip (Once, Daily, Weekly, Custom). "Custom" is not actually implemented as a distinct schedule; it is silently mapped to the same value as "Daily" server-side. On save, the reminder is posted to the backend, and on every fetch the client resynchronizes local device notifications: cancels all previously scheduled local notifications, then reschedules one per active reminder using `flutter_local_notifications`, in the `Africa/Douala` timezone. The scheduler attempts an exact alarm first and falls back to an inexact one if the exact-alarm permission is unavailable. Each reminder row has a bell icon that fires an immediate test notification, and a toggle switch that activates or deactivates the reminder with an optimistic UI update.

**Backend endpoint:** Full CRUD at `POST/GET/PUT/DELETE /api/reminders/index.php`. Delete here is a hard delete, unlike the soft delete used for health records. `frequency` is enum-validated server-side (`daily, twice_daily, thrice_daily, weekly, as_needed`), defaulting to `daily` for any unrecognized value.

**Database:** `reminders` table.

**Limitations:** The Add Reminder screen's own on-screen disclaimer, "You will receive a notification 5 minutes before the scheduled time," is inaccurate; the actual notification fires exactly at the scheduled time, not five minutes early. This is a copy defect, not a functional one, but it sets an incorrect user expectation.

**Screenshot needed:** Reminders list (populated and empty states); Add Reminder form.

### 3.11 Notifications

**Status:** Implemented.

**Description:** `lib/features/notifications/notifications_screen.dart`, `providers/notifications_provider.dart`. A server-backed list of in-app notifications, distinct from the local push notifications described in 3.10.

**How it works:** Fetches up to the 50 most recent notifications with an unread count. Notifications are created as side effects elsewhere in the system (a welcome message on registration, a message when a reminder is created); there is no user-facing endpoint to create arbitrary notifications. Tapping an unread notification marks it read; a "Mark all read" action is also available. Both mark-read calls are fire-and-forget on the client; the result of the network call is not checked.

**Backend endpoint:** `GET /api/notifications/index.php`, `POST /api/notifications/index.php?action=mark_read&id=X`, `POST /api/notifications/index.php?action=mark_all_read`.

**Database:** `notifications` table.

**Limitations:** The unread count returned by the API is computed only over the 50 most recently fetched rows, not a true global unread count, so a user with more than 50 unread notifications would see an undercount.

**Screenshot needed:** Notifications screen, populated and empty states.

### 3.12 Emergency Portal (including the Digital Health Passport)

**Status:** Implemented. The former "Medical ID" card has been replaced by a Digital Health Passport section; QR **generation** exists, QR **scanning** and a public HTML passport page do not.

**Description:** `lib/features/emergency/emergency_portal_screen.dart`. Contains a press-and-hold SOS button that dials the Cameroonian emergency number 15, an "Alert Contacts" action, two static first-aid guide cards (CPR, severe bleeding), and — where the old static "Your Medical ID" card used to be — a Digital Health Passport section (`lib/features/emergency/passport_section.dart`).

**How it works — Alert Contacts and Medical data:** Both "Alert Contacts" and the Digital Health Passport section now read from the same single source, `ProfileProvider.emergencyContacts` (a `ChangeNotifierProvider`, populated by `GET /api/profile/index.php`); the screen no longer makes its own independent, duplicate API call for contacts. Blood type and allergies also come from `ProfileProvider.user` (`AppUser.bloodType`/`.allergies`). All three fields fall back to the literal string `"Not provided"` when unset, rather than showing placeholder-looking text.

**How it works — Digital Health Passport section:** A dedicated `PassportProvider` (`lib/features/emergency/providers/passport_provider.dart`) wraps the passport backend (6.8): fetching status, and issuing `create` / `enable` / `regenerate` / `disable` actions. The section displays an Active/Disabled status pill, blood type, allergies, primary emergency contact, and a "last updated" timestamp sourced from the passport API itself (not reconstructed client-side). Four actions are available: **Show QR** (renders a `qr_flutter` QR code encoding the public passport URL, `{baseUrl}/api/passport/view.php?token=<token>`, purely client-side, no network call), **View as Text** (calls the real public `view.php` endpoint, unauthenticated, and displays the exact whitelist a scan would return — not a client-side reconstruction of it), **Regenerate** (confirmation dialog, then issues a new token; the old token is immediately invalid at the backend), and **Disable/Enable** (confirmation dialog; the label and action swap depending on current status). If no passport exists yet for the account, the section shows a "Create Passport" prompt instead of the four actions.

**Backend endpoints used:** `GET/POST /api/passport/index.php` (authenticated; `?action=create|enable|regenerate|disable`) for lifecycle management, and `GET /api/passport/view.php?token=` (public, unauthenticated) for the "View as Text" action specifically, so that action is guaranteed to show real scan output rather than an approximation.

**Database:** `emergency_passports` (new table — see 7), `users`, `emergency_contacts`.

**What the public passport endpoint exposes:** exactly seven whitelisted fields — `full_name`, `date_of_birth` (always `null`; no source exists anywhere in the schema for this field, a known and deliberately deferred gap, not an oversight — see RISK_REGISTER.md), `blood_type`, `allergies`, `emergency_contact_name`, `emergency_contact_phone`, `last_updated`. No database id, user id, or JWT is ever included in this endpoint's response — enforced by the endpoint hand-building its response object rather than passing through a database row (see 6.8).

**Limitations:** QR **scanning** does not exist (no camera-based scan screen, no scanning package in `pubspec.yaml` — only `qr_flutter`, which is generation-only). There is no public HTML passport page; the public endpoint is a JSON API only, intended to be consumed by a future scanning client, not viewed directly in a browser. `date_of_birth` is always `null` end to end. Neither the Flutter passport UI nor the public endpoint has been exercised on a live device/emulator or against a live database in this revision — verification so far has been by code trace, `flutter analyze`, and (for the backend) manual logic tracing only; no PHP runtime or MySQL instance was available in the environment these changes were built in. The `emergency_passports` table exists in `schema.sql` but, like `password_resets`, has not been confirmed applied to the live deployed database. First-aid guides remain static content with no "View all" action wired up.

**Screenshot needed:** Emergency Portal main view including the Digital Health Passport section (Active and Disabled states); the Show QR sheet; the View as Text sheet; Alert Contacts sheet.

### 3.13 Emergency Contacts

**Status:** Implemented (as part of Profile and Emergency Portal; there is no dedicated Dart model class for a contact, only raw maps).

**Description:** Full CRUD is exposed by the backend (`api/emergency_contacts/index.php`) and consumed from two places in the client: the Profile screen (add, list, delete; 3.8) and the Emergency Portal (list and act on; 3.12). There is no standalone "Emergency Contacts" screen or navigation entry separate from these two; contacts are managed inline within Profile.

**Database:** `emergency_contacts` table (`full_name`, `phone`, `relationship`, `is_primary`), enforcing a single-primary-contact invariant server-side whenever a contact is marked primary.

**Limitations:** Client-side validation on the add-contact form is presence-only (server-side phone-format validation is the only format check actually enforced).

### 3.14 Clinic Locator

**Status:** Implemented.

**Description:** `lib/features/clinic_locator/clinic_locator_screen.dart`, `clinic_details/clinic_details_screen.dart`, `providers/clinic_locator_provider.dart`. A searchable, mappable directory of clinics.

**How it works:** On load, fetches all clinics (public endpoint, no auth required) and attempts to read the device's GPS location; if the location is within roughly 800 km of Yaoundé, the map recenters there and results are re-fetched sorted by proximity (server-side Haversine-distance calculation), otherwise results default to a rating-sorted list centered on Yaoundé. Search is debounced 500ms and re-queries the server. The map uses `flutter_map` with OpenStreetMap tiles. Each clinic card shows open/closed status, rating, address, and service tags, and opens a details screen.

**Clinic Details screen specifics:** "Call Now" and "Navigate" (opens external Google Maps) work against the real clinic phone/coordinates. However, three sections on this screen render fixed content whenever the underlying data is not present or at all: the weekly opening-hours breakdown is always the same static Monday-to-Sunday schedule regardless of which clinic is open, the specialization tags fall back to a fixed list (Cardiology, Pediatrics, Neurology, Eye Care, Dental) when a clinic's `services` field is empty, and the "About" paragraph is a single templated sentence with the clinic's name and type substituted in, identical for every clinic. The "location" card on this screen is a decorative grid pattern, not an embedded map.

**Backend endpoint:** `GET /api/clinics/index.php`, supporting `q` (name/address/services search), `city`, `type` (whitelist-validated), and `lat`/`lng` (for proximity sorting), capped at 50 results.

**Database:** `clinics` table, seeded with 10 to 11 real Cameroonian facilities (two independent seed sources exist, `schema.sql`'s embedded seed and `seed_clinics.php`'s script, which are not identical datasets and are not meant to be run together).

**Limitations:** The generic hours/specializations/about content on the details screen would need to be either sourced from richer clinic data or clearly labeled as indicative rather than clinic-specific, since currently it is presented with no such distinction.

**Screenshot needed:** Clinic Locator map/list view; Clinic Details screen.

### 3.15 Symptom Checker

**Status:** Implemented as a rule-based tool. As of 2026-07-12, in-app copy correctly describes it as rule-based rather than "AI."

**Description:** `lib/features/symptom_checker/symptom_checker_screen.dart`, `providers/symptom_checker_provider.dart`, and the results view `lib/features/health_records/analysis_result/analysis_result_screen.dart`.

**How it works:** The user selects from a fixed catalogue of 25 predefined symptoms or types in a free-text symptom, then taps "Analyze." The provider runs a private method, `_runRuleEngine`, a hand-written cascade of pattern-matching `if` blocks against roughly ten hardcoded condition profiles (cardiac emergency, meningitis, malaria, viral respiratory infection, migraine, gastroenteritis, hypertensive episode, hyperglycemia, musculoskeletal pain, anxiety/stress, typhoid fever), falling back to a generic "unspecified pattern" result if nothing matches. The output includes a condition name, a summary, an urgency level, a recommendations list, and a suggested clinic type, all of which are fixed strings baked into the Dart source for whichever rule matched. No network call is made anywhere in this feature; it runs entirely on-device.

**Result screen specifics:** The "Recommended Clinic" card on the analysis results screen displays a fully fixed clinic name, rating, distance, and hours ("La Paix Medical Center," 4.9 rating, "0.8 km away") regardless of the analysis outcome or the user's actual location; it is not connected to the real Clinic Locator data or the user's position.

**Marketing copy discrepancy (resolved 2026-07-12):** The Symptom Checker screen's `_ValidatedCard` previously read "Clinically Validated" / "Our AI assessment is based on peer-reviewed clinical protocols and diagnostic data," and the Dashboard's entry point read "AI-powered health assessment." Both described this feature as AI-driven and clinically validated when it is deterministic keyword matching against a fixed rule set with no clinical review performed. Copy now reads "Rule-Based Guidance" / "This assessment uses a deterministic, on-device rule engine, not AI, and does not replace professional medical advice" and "Quick rule-based symptom guidance," respectively.

**Backend endpoint:** None. No `backend/api/symptoms/` or equivalent exists.

**Limitations:** Coverage is limited to the roughly ten conditions hardcoded into the rule engine; anything outside those patterns returns a generic, non-actionable result. The recommended-clinic card is misleading in its specificity.

**Screenshot needed:** Symptom Checker selection screen; Analysis Result screen.

### 3.16 Settings

**Status:** Partially implemented; no dedicated feature folder.

**Description:** There is no `lib/features/settings/` folder. All settings UI is inline inside the Profile screen's `_SettingsSection` (see 3.8): Personal Information (functional), Notification Settings (routes to the real Notifications screen), Privacy & Security (non-functional placeholder), Language (non-functional placeholder).

### 3.17 Navigation

**Status:** Implemented.

**Description:** `lib/core/routing/app_routes.dart` defines 18 named routes plus one specially handled route (`clinicDetails`, which requires a typed argument and is not present in the static routes map). Navigation is performed with `Navigator.pushNamed` / `pushReplacementNamed` / `pushNamedAndRemoveUntil` throughout; there is no `go_router` or other declarative router.

**Route guard:** `onGenerateRoute` checks every route except splash, onboarding, role-selection, login, sign-up, forgot-password, and reset-password against `AuthGuard.isAuthenticated` (an in-memory boolean, session length 8 hours matching the JWT expiry) and redirects unauthenticated access attempts to Login. This guard is authentication-only; it does not check role. Any authenticated account, regardless of its `role` value, can reach every protected route.

**Unknown routes:** Render a simple "Route not found" screen.

### 3.18 Admin functionality

**Status:** Not implemented.

**Description:** The `users.role` column supports `admin` as a value, and the registration endpoint explicitly refuses to create accounts with that role (forcing `patient`/`doctor` only), meaning an admin account can currently only be created through the standalone `seed_admin.php` provisioning script (Section 6/9), not through the app. No admin screen, admin route, or role-conditional UI exists anywhere in `lib/`.

### 3.19 Doctor functionality

**Status:** Not implemented.

**Description:** `role: 'doctor'` is an accepted value at registration and is stored, but no part of the client application reads or branches on it. No doctor-specific screen, dashboard, or workflow exists. The word "doctor" elsewhere in the codebase refers only to a form field label (a "Doctor / Physician" text input on the Add Health Record screen), not to a role-based feature.

### 3.20 Hidden or unadvertised features

- **Dead RBAC code:** `AuthGuard.hasRole()` and `AuthGuard.hasAnyRole()` are fully implemented methods that are never called anywhere in the codebase outside their own definitions.
- **Rate limiter:** A client-side, in-memory brute-force guard (`lib/core/security/rate_limiter.dart`) protects the login form (5 attempts / 15-minute window / 30-minute lockout) but is not visible as a distinct "feature" and resets on app restart.
- **Injection detection:** `InputSanitizer.detectInjection` actively screens free-text fields (health record notes, for example) for SQL keywords and script-injection patterns before submission, in addition to standard sanitization.

---

## 4. User Flows

### 4.1 First-time user flow

```
Splash (2.8s, session check)
   │  no session found
   ▼
Onboarding (3 pages, Skip available)
   │
   ▼
Role Selection (cosmetic only, all cards → Login)
   │
   ▼
Login  ── "Sign Up" link ──▶  Sign Up  ── success ──▶  Dashboard
   │  success
   ▼
Dashboard
```

### 4.2 Returning user flow

```
Splash (2.8s, session check)
   │  valid session restored via GET /auth/me.php
   ▼
Dashboard
```

### 4.3 Password reset flow

```
Login ── "Forgot?" ──▶ Forgot Password (email)
                              │  POST /auth/forgot_password.php
                              ▼
                       Reset Password (6-digit OTP + new password)
                              │  POST /auth/reset_password.php
                              ▼
                            Login
```

### 4.4 Medication reminder flow

```
Dashboard ── "Set a reminder" / Reminders tab ──▶ Reminders list
                                                        │  "+" FAB
                                                        ▼
                                                 Add Reminder (title, time, frequency)
                                                        │  POST /reminders
                                                        ▼
                                       RemindersProvider resyncs local notifications
                                                        │
                                                        ▼
                                         flutter_local_notifications fires at scheduled time
```

### 4.5 Emergency flow

```
Dashboard ── "Emergency" card ──▶ Emergency Portal
                                        │
                ┌───────────────┬───────────────────┬─────────────────────┐
                ▼               ▼                   ▼                     ▼
        Hold SOS button   Alert Contacts     Digital Health Passport  Show QR / View
        (dials 15)        (ProfileProvider,   (status, blood type,    as Text / Regen-
                           call/SMS shortcuts) allergies, contact,     erate / Disable
                                                real data via          (see 3.12)
                                                ProfileProvider +
                                                PassportProvider)
```

### 4.6 Symptom checker flow

```
Dashboard ── "Check Symptoms" ──▶ Symptom Checker (select from 25 symptoms)
                                          │  "Analyze"
                                          ▼
                          Client-side rule engine (no network call)
                                          │
                                          ▼
                              Analysis Result screen
                          (urgency, summary, recommendations,
                           and a hardcoded "Recommended Clinic" card)
                                          │  "Find Nearby Clinic"
                                          ▼
                                  Clinic Locator (real data)
```

### 4.7 Clinic search flow

```
Dashboard ── "Find Clinic" ──▶ Clinic Locator
                                     │  GPS check, debounced search
                                     ▼
                        GET /clinics (proximity or rating sorted)
                                     │  tap a result
                                     ▼
                              Clinic Details
                        (real phone/coordinates/rating;
                         generic hours/about/specializations
                         when clinic-specific data is absent)
```

---

## 5. UI Documentation

Screen-by-screen detail (inputs, validation, API calls, states) is documented in full under each feature in Section 3. The table below is a consolidated index.

| Screen | Route | Auth required | API calls | Loading state | Empty state |
|---|---|---|---|---|---|
| Splash | `/` | No | `GET /auth/me` | Animated bar, no spinner | n/a |
| Onboarding | `/onboarding` | No | None | n/a | n/a |
| Role Selection | `/role-selection` | No | None | n/a | n/a |
| Login | `/login` | No | `POST /auth/get_salt`, `POST /auth/login` | Button spinner | n/a |
| Sign Up | `/sign-up` | No | `POST /auth/register` | Button spinner | n/a |
| Forgot Password | `/forgot-password` | No | `POST /auth/forgot_password` | Button spinner | n/a |
| Reset Password | `/reset-password` | No | `POST /auth/reset_password` | Button spinner | n/a |
| Dashboard | `/dashboard` | Yes | `GET /profile`, `GET /reminders` | Section spinner | Empty reminders card |
| Profile | `/profile` | Yes | `GET/PUT /profile`, `POST /profile/upload_avatar`, `POST/DELETE /emergency_contacts` | Section spinner | "No emergency contacts" text |
| Health Records | `/health-records` | Yes | `GET /health_records` | Full-screen spinner | "No medical records yet" |
| Add Record | `/health-records/add` | Yes | `POST /health_records`, optional `PUT /profile` | Button spinner | n/a |
| Analysis Result | `/health-records/analysis-result` | Yes | None (reads provider state) | n/a | "No analysis yet" |
| Reminders | `/reminders` | Yes | `GET/PUT/DELETE /reminders` | Full-screen spinner | "No reminders yet" |
| Add Reminder | `/reminders/add` | Yes | `POST /reminders` | Button spinner | n/a |
| Notifications | `/notifications` | Yes | `GET /notifications`, mark-read actions | Full-screen spinner | "No notifications yet" |
| Emergency Portal | `/emergency` | Yes | `GET /profile` (via `ProfileProvider`, shared with Alert Contacts), `GET/POST /passport` (status + lifecycle), `GET /passport/view.php` (View as Text) | None shown during fetch | "No emergency contacts saved"; Passport section shows a "Create Passport" prompt if none exists |
| Clinic Locator | `/clinic-locator` | No (public data) | `GET /clinics` | Full-screen spinner | "No clinics found" |
| Clinic Details | `/clinic-details` | No | None (uses passed-in object) | n/a | n/a |
| Symptom Checker | `/symptom-checker` | Yes | None (local rule engine) | n/a | n/a |

---

## 6. Backend Documentation

### 6.1 Auth

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `auth/get_salt.php` | POST | No | Returns the user's stored salt, or a deterministic dummy salt for unknown emails, for client-side pre-hashing |
| `auth/register.php` | POST | No | Creates an account; forces role to patient/doctor |
| `auth/login.php` | POST | No | Verifies credentials, issues JWT |
| `auth/me.php` | GET | Yes | Returns the current user's profile for session restore |
| `auth/forgot_password.php` | POST | No | Issues a rate-limited 6-digit OTP by email |
| `auth/reset_password.php` | POST | No | Verifies OTP, updates password hash and salt |

### 6.2 Profile

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `profile/index.php` | GET | Yes | Full profile plus stats (record/reminder/contact counts) and emergency contacts |
| `profile/index.php` | PUT | Yes | Updates full_name, phone, avatar_url, blood_type, allergies (whitelisted columns only) |
| `profile/upload_avatar.php` | POST | Yes | Multipart avatar upload, 2MB limit, content-sniffed MIME whitelist |

### 6.3 Clinics

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `clinics/index.php` | GET | Optional | Search/list/detail; supports name/address/service search, city, type whitelist, and proximity sort |

### 6.4 Emergency Contacts

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `emergency_contacts/index.php` | GET/POST/PUT/DELETE | Yes | Full CRUD, enforces a single-primary-contact invariant |

### 6.5 Health Records

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `health_records/index.php` | GET/POST/PUT/DELETE | Yes | Full CRUD; delete is a soft delete via `is_active` |

### 6.6 Reminders

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `reminders/index.php` | GET/POST/PUT/DELETE | Yes | Full CRUD; delete is a hard delete |

### 6.7 Notifications

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `notifications/index.php` | GET | Yes | List, capped at 50, with unread count |
| `notifications/index.php` | POST | Yes | `?action=mark_read&id=` or `?action=mark_all_read` |

### 6.8 Digital Health Passport

| Endpoint | Method | Auth | Purpose |
|---|---|---|---|
| `passport/index.php` | GET | Yes | Current passport status for the caller (`exists`, `token`, `is_active`, timestamps) |
| `passport/index.php` | POST | Yes | `?action=create` — new passport only; 409 if one already exists (active or disabled) |
| `passport/index.php` | POST | Yes | `?action=enable` — reactivates a disabled passport with a **brand-new** token; the old token is never reused |
| `passport/index.php` | POST | Yes | `?action=regenerate` — new token for an active passport; 409 if the passport is disabled (regeneration cannot silently reactivate a disabled passport) |
| `passport/index.php` | POST | Yes | `?action=disable` — deactivates the current passport; idempotent |
| `passport/view.php` | GET | **No** | Public, token-only lookup (`?token=<64-hex-char>`). Returns a fixed 7-field whitelist. 400 malformed token, 404 unknown token or deactivated owning account (both identical, to avoid leaking which), 410 disabled passport, 200 + whitelist otherwise. `Cache-Control: no-store` and `Pragma: no-cache` set unconditionally. |

Tokens are generated by `generate_secure_token()` in `helpers.php` — `random_bytes(32)`, hex-encoded (64 characters), never derived from user id, email, phone, or timestamps. `emergency_passports.token` carries a `UNIQUE` database constraint as defense-in-depth beyond the CSPRNG's own collision resistance. Retry-on-collision logic distinguishes a genuine token collision (retried, astronomically unlikely) from a `UNIQUE(user_id)` race on `create` (not retried — returns 409 directly), by inspecting the failing constraint's name in the driver error message rather than treating every `23000` integrity-constraint violation identically. Per `DECISIONS.md` ADR-001, `view.php` is a separate file from `index.php` with no shared router or conditional authentication between them.

### 6.9 Cross-cutting conventions

Every endpoint response uses one of two envelopes: `{"success": true, "data": {...}}` on success, or `{"success": false, "message": "..."}` on failure, produced by the shared `json_ok()`/`json_error()` helpers. Every protected endpoint calls `require_auth()`, which extracts a Bearer token from the `Authorization` header (falling back to a custom `X-Token` header when the standard header is stripped by the hosting environment), decodes and verifies the JWT (HMAC-SHA256, constant-time signature comparison, expiry check), and returns the decoded claims (`user_id`, `email`, `role`) for the endpoint to use in scoping its queries. `passport/view.php` (6.8) is the one deliberate exception to this pattern — it is public by design, per ADR-001, not an oversight. Every SQL statement across all fifteen endpoint files uses PDO prepared statements with positional parameters; no string-concatenated SQL was found anywhere in the reviewed code. Dynamic column names in partial-update endpoints (profile, reminders, health records, emergency contacts) are drawn from fixed server-side whitelists, not from user input, so this pattern does not introduce an injection risk.

---

## 7. Database Documentation

### `users`
| Column | Type | Null | Default |
|---|---|---|---|
| id | INT UNSIGNED, PK, AUTO_INCREMENT | No | — |
| full_name | VARCHAR(100) | No | — |
| email | VARCHAR(255), UNIQUE | No | — |
| phone | VARCHAR(20) | Yes | NULL |
| password_hash | VARCHAR(255) | No | — |
| salt | VARCHAR(100) | No | — |
| role | ENUM(patient, doctor, admin) | No | patient |
| blood_type | VARCHAR(5) | Yes | NULL |
| allergies | TEXT | Yes | NULL |
| avatar_url | VARCHAR(500) | Yes | NULL |
| is_active | TINYINT(1) | No | 1 |
| created_at / updated_at | DATETIME | No | CURRENT_TIMESTAMP |

Indexes: `idx_email`, `idx_role`. Referenced by: `health_records.user_id`, `reminders.user_id`, `notifications.user_id`, `emergency_contacts.user_id`, all `ON DELETE CASCADE`.

### `health_records`
`id` PK, `user_id` FK → users, `type` ENUM(prescription, lab_result, x_ray, vaccination, consultation, surgery, other) default `other`, `title` VARCHAR(200) not null, `doctor` VARCHAR(150) nullable, `facility` VARCHAR(200) nullable, `date` DATE not null, `file_url` VARCHAR(500) nullable, `notes` TEXT nullable, `is_active` TINYINT(1) default 1, timestamps. Indexes: `idx_user_id`, `idx_date`.

### `reminders`
`id` PK, `user_id` FK → users, `medication_name` VARCHAR(150) not null, `dosage` VARCHAR(100) nullable, `frequency` ENUM(daily, twice_daily, thrice_daily, weekly, as_needed) default `daily`, `reminder_time` TIME not null, `days_of_week` VARCHAR(50) nullable, `is_active` TINYINT(1) default 1, `start_date`/`end_date` DATE nullable, `notes` TEXT nullable, timestamps. Index: `idx_user_id`.

### `clinics`
`id` PK, `name` VARCHAR(200) not null, `address` VARCHAR(400) not null, `city` VARCHAR(100) default "Yaoundé", `country` VARCHAR(50) default "Cameroon", `latitude`/`longitude` DECIMAL(10,7) nullable, `phone` VARCHAR(30) nullable, `email` VARCHAR(255) nullable, `website` VARCHAR(500) nullable, `type` ENUM(hospital, clinic, pharmacy, laboratory, specialist, dental, eye_care, other) default `clinic`, `rating` DECIMAL(3,1) nullable with a CHECK constraint between 1.0 and 5.0, `is_24h` TINYINT(1) default 0, `hours` VARCHAR(200) nullable, `services` TEXT nullable (comma-separated), `is_active` TINYINT(1) default 1, `created_at` only (no `updated_at`). Indexes: `idx_city`, `idx_type`, and a FULLTEXT index on (name, address, services) that is defined but currently unused, since the search endpoint queries with `LIKE` rather than `MATCH...AGAINST`. No foreign keys; this is a standalone reference table.

### `notifications`
`id` PK, `user_id` FK → users, `type` ENUM(reminder, appointment, system, alert, info) default `info`, `title` VARCHAR(200) not null, `body` TEXT nullable, `is_read` TINYINT(1) default 0, `created_at` only. Indexes: `idx_user_id`, `idx_is_read`.

### `emergency_contacts`
`id` PK, `user_id` FK → users, `full_name` VARCHAR(100) not null, `phone` VARCHAR(30) not null, `relationship` VARCHAR(50) nullable, `is_primary` TINYINT(1) default 0, timestamps. Index: `idx_user_id`.

### `emergency_passports` (new — Digital Health Passport)
`id` PK, `user_id` FK → users (`UNIQUE` — one passport row per user), `token` CHAR(64) not null (`UNIQUE`, 32 random bytes hex-encoded, see 6.8), `is_active` TINYINT(1) default 1, `created_at`/`updated_at` timestamps, `disabled_at` DATETIME nullable. Present in `schema.sql` as of this revision but **not yet confirmed applied to the live deployed database** — same category of gap as `password_resets` below, flagged in RISK_REGISTER.md rather than assumed resolved.

### `password_resets` (used by code, absent from `schema.sql`)
Inferred columns from the auth endpoints: `id`, `email`, `token`, `expires_at`, `used`, `created_at`. This table must exist in the live database for the password-reset flow to function, but it is not present in the checked-in `schema.sql` file. This should be corrected so the schema file is a complete, reproducible source of truth.

### Entity relationship summary

```
users (1) ──< (many) health_records
users (1) ──< (many) reminders
users (1) ──< (many) notifications
users (1) ──< (many) emergency_contacts
users (1) ──< (1)    emergency_passports  [one-to-one; UNIQUE(user_id)]
users (1) ──< (many) password_resets   [table not in schema.sql]

clinics                                  [standalone, no FK relationships]
```

---

## 8. Packages

| Package | Version | Purpose | Where used |
|---|---|---|---|
| `google_fonts` | ^6.2.1 | Typography | Splash, onboarding, auth screens, role selection, typography constants |
| `provider` | ^6.1.2 | State management | App-wide, all 8 providers and their consuming screens |
| `http` | ^1.2.2 | HTTP client | `ApiClient` exclusively |
| `cupertino_icons` | ^1.0.8 | iOS-style icon set | **Declared but not used anywhere in the code** |
| `equatable` | ^2.0.5 | Value equality for model classes | All 5 model classes |
| `shared_preferences` | ^2.3.3 | Key-value local storage | **Declared but not used anywhere in the code**; the app deliberately avoids it for tokens in favor of secure storage |
| `flutter_secure_storage` | ^9.2.4 | Encrypted local storage | `SecureStorage` wrapper (JWT, email, role) |
| `crypto` | ^3.0.3 | SHA-256 hashing | `PasswordHasher` (client-side password prep) |
| `url_launcher` | ^6.3.1 | External URI launching | Emergency Portal (tel/sms), Clinic Details (tel/maps), Profile (tel), Role Selection (mailto) |
| `image_picker` | ^1.1.2 | Camera/gallery image selection | Dashboard and Profile avatar upload, Add Health Record photo control |
| `flutter_map` | ^7.0.2 | Map rendering | Clinic Locator |
| `latlong2` | ^0.9.1 | Coordinate type for map markers | Clinic Locator |
| `geolocator` | ^13.0.4 | Device GPS location | Clinic Locator |
| `flutter_local_notifications` | ^18.0.0 | Local scheduled notifications | `NotificationService` (medication reminders) |
| `timezone` | ^0.10.0 | Timezone-correct scheduling | `NotificationService`, hardcoded to Africa/Douala |
| `qr_flutter` | ^4.1.0 | QR code rendering (generation only, no scanning) | Digital Health Passport section's "Show QR" sheet |
| `flutter_lints` | ^6.0.0 (dev) | Static analysis rules | Project-wide lint configuration |
| `flutter_test` (dev) | sdk | Testing framework | One unmodified template smoke test |

Two dependencies, `cupertino_icons` and `shared_preferences`, are declared in `pubspec.yaml` but have no import anywhere in `lib/` and can be removed without affecting behavior.

---

## 9. Code Quality Review

**Architecture.** The feature-first client structure with a shared `core/` layer is a reasonable, conventional Flutter organization for a project of this size, and the backend's one-file-per-endpoint pattern with shared `helpers.php` conventions is consistent across all fifteen endpoints (see 2.4). Both sides apply their conventions uniformly rather than diverging endpoint to endpoint or screen to screen.

**Naming.** Consistent camelCase in Dart, snake_case in PHP and SQL, matching each language's convention. Route names, provider class names, and model field names map predictably to their backend counterparts.

**Code duplication.** The blood-type option list (`A+, A-, B+, B-, AB+, AB-, O+, O-`) is defined as an identical literal in both `add_record_screen.dart` and `profile_screen.dart`, with two different UI treatments (dropdown versus choice chips) for the same underlying data, and no shared constant. Several screens (Add Record, Add Reminder, the Personal Information sheet, Sign Up, Login, Forgot/Reset Password) independently hand-roll the same "build a payload, call a provider method, toggle a saving flag, catch and display an error string" pattern with no shared form-submission helper or mixin. A `_FormLabel` widget is defined privately inside `add_record_screen.dart` even though the project already has a `lib/shared/widgets/` module used elsewhere for exactly this kind of reusable presentational component.

**Technical debt.** `AuthGuard.hasRole()` and `hasAnyRole()` are implemented but never called, meaning the codebase carries RBAC machinery it does not use. The Role Selection screen is fully decorative. Several screens present hardcoded content styled identically to live data (Section 3 details each instance), which is a maintenance risk since a future developer editing the surrounding code may not immediately recognize which values are real and which are fixed strings.

**Security.** Strengths: parameterized queries throughout, constant-time JWT signature comparison, bcrypt-on-top-of-client-hash password storage, content-sniffed file upload validation, generic error messages on login/registration/forgot-password to avoid user enumeration, and a documented rationale (via inline comments referencing OWASP Top 10 categories) for most of these choices. Weaknesses, all confirmed in the actual deployment configuration rather than merely theoretical: the production API base URL (`lib/core/config/api_config.dart`) is plain `http://`, not `https://`; the Android manifest explicitly sets `android:usesCleartextTraffic="true"`; the live `backend/config.php` stores the database password in plaintext (mitigated only by `.htaccess` blocking direct HTTP access to that file, which is an Apache-level control, not encryption); and the repository-tracked `deploy.py` contains a hardcoded plaintext SSH password for the production host. Additionally, `seed_admin.php` and `seed_clinics.php` remain directly web-accessible (they are not covered by the `.htaccess` file-blocking rule that protects `config.php`, `db.php`, `helpers.php`, and `schema.sql`), and both scripts' own comments instruct that they be deleted from the server after use, which is an operational step rather than a code-level control.

**Performance.** No local caching layer exists; every screen re-fetches its data from the network on each visit, including the clinic list, which is fetched again on every search keystroke (debounced 500ms) rather than filtered from an already-fetched result set for simple text queries. This is acceptable at current data volumes (a few dozen clinics, small per-user record counts) but would not scale to a large clinic directory without pagination or caching.

**Maintainability.** No code generation is used for model serialization; every `fromJson`/`toJson` is hand-written, which is consistent but means any backend field rename requires a manual, easy-to-miss update in the corresponding Dart model. There is no `enum` type for any of the string-typed "enum-like" fields (`role`, health record `type`, reminder `frequency`, notification `type`); all are validated only by comment convention on the client and by server-side whitelist checks, so a typo in a hardcoded string on the client would fail silently into a default value rather than raise a compile-time or client-side validation error.

---

## 10. Current Limitations

### Implemented and working end to end
Registration, login, forgot/reset password, profile view and edit (including blood type and allergies), avatar upload, health records CRUD, medication reminders CRUD with local notification scheduling, in-app notifications list and mark-read, emergency contacts CRUD, clinic search and map view with proximity sorting, symptom checker rule engine and result display, session restore on app relaunch, route-level authentication guard, and — as of this revision — the Digital Health Passport (status display, QR generation, text view via the real public endpoint, regenerate/enable/disable lifecycle). The passport work is implemented and has passed static analysis, but has not been exercised on a live device or against a live database (see 3.12).

### Partially implemented
- **Settings:** Personal Information and Notification Settings work; Privacy & Security and Language are visual stubs only.
- **Symptom Checker:** functions as designed and, as of 2026-07-12, is correctly presented as rule-based rather than "AI"; its result screen's clinic recommendation is still fixed rather than computed.
- **Clinic Details:** phone, coordinates, and rating are real; opening hours, specializations (when absent from the source data), and the About paragraph are generic filler.
- **Add Health Record:** photo/document attachment is collected in the UI but never actually submitted or stored.
- **Digital Health Passport:** generation, status, regenerate/enable/disable, and the public view endpoint all exist; QR **scanning** and a public HTML passport page do not (see 3.12). `date_of_birth` is always `null` in the public whitelist — no source exists anywhere in the schema.

### Placeholder (visually present, not functionally real)
- Analysis Result screen's "Recommended Clinic" card (fixed clinic name, rating, and hours for every analysis).
- Profile's "Premium Member" / "Verified Pro" badges and the "Version 2.4.1 (Clinical Build)" footer string.
- Role Selection screen (all three role cards behave identically).
- Login screen's Google/Apple social buttons.
- Dashboard's "Daily Insight" (rotates by day of week, not personalized or API-driven).

(The Emergency Portal's "Medical ID" card, previously listed here, was replaced by the real, data-backed Digital Health Passport section — see 3.12. It is no longer placeholder content.)

### Not implemented
- QR **scanning** (camera-based scan-and-display flow) and a public HTML passport page — QR **generation** and the underlying public JSON API now exist; scanning does not (see 3.12).
- Medical conditions tracking as a distinct data field (only blood type and free-text allergies exist on the user profile; there is no conditions list, chronic-condition tracker, or structured conditions table).
- Admin dashboard or any admin-specific UI.
- Doctor dashboard or any doctor-specific UI or workflow.
- Role-based access control at the UI or route level (authentication is checked; role is not).
- Push notifications (Firebase or otherwise); only on-device scheduled local notifications exist.
- Offline data caching or a local database.
- Automated tests beyond the default Flutter project template.
- Custom reminder scheduling beyond the four fixed frequency options (the "Custom" option is not actually custom).

---

## 11. Screenshots

Automated screenshot capture from a running instance of the application was not performed as part of this document. The checklist below identifies every screen that should be captured manually, with its purpose, navigation path, and what to verify while capturing it, so the resulting screenshot set matches what is described in Section 3.

| # | Screen | Navigation path | Capture notes |
|---|---|---|---|
| 1 | Splash | App launch | Capture during the loading animation |
| 2 | Onboarding (all 3 pages) | Splash → Onboarding (no session) | Capture each page separately |
| 3 | Role Selection | Onboarding → Skip/Get Started | One capture is sufficient; all three cards behave identically |
| 4 | Login (default) | Role Selection → any card | — |
| 5 | Login (lockout error) | 5 failed login attempts | Shows the rate-limiter banner |
| 6 | Sign Up | Login → "Sign Up" | Capture with validation errors visible on at least one field |
| 7 | Forgot Password | Login → "Forgot?" | — |
| 8 | Reset Password | Forgot Password → submit | Capture with OTP boxes visible |
| 9 | Dashboard (with reminders) | Login success | — |
| 10 | Dashboard (empty reminders) | New account, no reminders added | Shows the empty-state card |
| 11 | Profile (main) | Dashboard → profile icon | — |
| 12 | Profile → Personal Information sheet | Profile → "Personal Information" | Shows blood type chips and allergies field |
| 13 | Profile → Add Emergency Contact sheet | Profile → "+" on contacts section | — |
| 14 | Health Records (populated) | Dashboard → "My Records" | — |
| 15 | Health Records (empty) | New account, no records added | — |
| 16 | Add Health Record | Health Records → FAB | Include the photo-upload control in frame |
| 17 | Reminders (populated) | Dashboard → Reminders | — |
| 18 | Reminders (empty) | New account, no reminders added | — |
| 19 | Add Reminder | Reminders → "+" | — |
| 20 | Notifications (populated) | Dashboard → bell icon | — |
| 21 | Notifications (empty) | New account, no notifications beyond the welcome message | — |
| 22 | Emergency Portal | Dashboard → "Emergency" card | Include the Digital Health Passport section in frame |
| 23 | Emergency Portal → Alert Contacts sheet | Emergency Portal → "Alert Contacts" | — |
| 24 | Clinic Locator (map view) | Dashboard → "Find Clinic" | Capture with at least one search performed |
| 25 | Clinic Details | Clinic Locator → any result | Include the hours/about/specializations sections in frame |
| 26 | Symptom Checker (selection) | Dashboard → "Check Symptoms" | Capture with at least 2 symptoms selected |
| 27 | Analysis Result | Symptom Checker → "Analyze" | Include the "Recommended Clinic" card in frame |

---

## 12. Recommendations

**Strengths to lead with in the competition presentation.** Real parameterized-query discipline across the entire backend, sound password handling (client hash plus server bcrypt), timing-safe JWT verification, content-sniffed file upload validation, and a working end-to-end medication reminder system with real local notification scheduling tuned to Cameroon's timezone. These are legitimate engineering strengths that hold up under direct code inspection, not just claims.

**Weaknesses to fix before judging, roughly in order of severity.**
1. Enable HTTPS on the production API and remove `usesCleartextTraffic="true"` from the Android manifest; credentials and health data currently transit in plaintext.
2. Remove the hardcoded SSH password from `deploy.py` and rotate that credential, since the file is tracked in version control.
3. Delete or token-protect `seed_admin.php` and `seed_clinics.php` on the live server, or add them to the existing `.htaccess` block list.
4. Add `password_resets` to `schema.sql` so the schema file is a complete and reproducible source of truth.
5. ~~Correct the misleading UI copy: relabel the Symptom Checker as rule-based clinical guidance rather than "AI,"~~ **Done 2026-07-12** (Dashboard and Symptom Checker screens). Still open: fix the Add Reminder screen's inaccurate "5 minutes before" disclaimer, and either wire up or remove the Privacy & Security and Language settings rows.

**Quick wins.** ~~Wire the Emergency Portal's Medical ID card to the real, already-available `blood_type`/`allergies`/emergency-contact data~~ **Done 2026-07-12** (now the Digital Health Passport section, 3.12). Remove the two unused packages (`cupertino_icons`, `shared_preferences`) to reduce the dependency surface. Extract the duplicated blood-type list into a single shared constant. Confirm the `emergency_passports` table (schema.sql) has actually been applied to the live database before any demo or judge-facing use.

**High-impact improvements for the competition.** ~~A QR-based emergency medical summary, generated from the real profile data and displayed or scanned from the Emergency Portal~~ — **QR generation and the backing public API are now implemented** (3.12, 6.8); QR **scanning** remains the one meaningful piece of this recommendation still open. A written security and privacy architecture document does not yet exist anywhere in the repository, despite substantial real evidence to describe (JWT, bcrypt, parameterized queries, the isolated public-endpoint design in `passport/view.php`) — this is a genuinely low-effort, high-value gap against the competition's own judging rubric (see `docs/competition/EVIDENCE_MATRIX.md`). Adding automated tests for the provider layer and the security/validation utilities would materially improve confidence during any live judging demo where the app is interacted with unpredictably, and would also be the only way to verify the passport work beyond static analysis, since no live device/emulator run has been performed on it yet. Introducing role-based UI gating (even a minimal doctor or admin view) would give the already-stored `role` field and the unused `AuthGuard.hasRole()` machinery a real purpose, rather than leaving them as inert code.
