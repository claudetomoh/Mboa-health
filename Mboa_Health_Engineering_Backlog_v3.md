# Mboa Health - Engineering Backlog v3.0

The authoritative backlog. Cross-references Implementation Master Plan v1.1. Status updates
happen the same day a task lands, alongside TODO.md and the Current System Specification.

Corrected against a direct codebase review on this date: file paths, condition count, and
security-module status reflect what's actually in the repo, not what earlier documents assumed.

## Phase 1: Video and Submission Gate

| Epic | Scope | Status |
|---|---|---|
| E - Clinical Reviewer Outreach | Contact only, scheduling, not the review itself | Not started |
| A - Truth-in-UI Correction | Remove false AI/clinical-validation claims: `symptom_checker_screen.dart` (`_ValidatedCard`) and `dashboard_screen.dart:423` ("AI-powered health assessment"). Sweep pitch deck, Product Vision Blueprint, Onboarding Guide for the same category of claim. | Not started, corrected task issued |
| B - Security and Privacy Architecture Document | Can draw directly from `lib/core/security/security.dart`'s existing OWASP mapping (AuthGuard, SecureStorage, RateLimiter, InputSanitizer/AppValidators), not written from scratch | Not started |
| C - Business Model Reframe | Remove hospitals-as-primary-customer and freemium claims, replace with honest "under review" framing | Not started |
| G - Medical ID Card | Wire the hardcoded string in `emergency_portal_screen.dart:453` to real `ProfileProvider` data. Blood-type consolidation sub-task cut, no dual entry point exists in the actual code. | Not started |
| F, Task 4 - QR Passport Public Endpoint | New isolated backend file, no shared router with authenticated passport routes | Not started |
| F, Task 5 - QR Code Generation Screen | Frontend, Emergency Portal feature folder | Not started |
| F, Task 6 - QR Code Scanning Screen | Frontend, calls Task 4's endpoint | Not started |
| D - Project Document Assembly | Depends on A, B, C, F | Not started |
| M - Video Demonstration Production | Depends on A, G, F being stable. Confirm length/format requirements before recording. | Not started |

## Phase 2: Pitch Gate (only if shortlisted)

| Epic | Scope | Status |
|---|---|---|
| H, Task 7/8 - AI Free-Text Mapping Layer | Isolated endpoint plus minimal UI hook, zero diff to `_runRuleEngine` | Not started |
| I - Clinical Review Execution | Scope: eleven named conditions (not twelve, corrected count), see `symptom_checker_provider.dart` | Not started |
| K - Demo Rehearsal and Offline QA | Physical device, airplane mode, live Grand Jury context | Not started |

## Phase 3: Nice to Have

| Epic | Scope | Status |
|---|---|---|
| Task 9 - Server-Side Rate Limiting | Auth endpoints only. Client-side `RateLimiter` already exists and is wired into `login_screen.dart`, but does not protect the API directly. | Not started |
| Task 10 - QR Passport Access Log | Depends on Task 4 | Not started |
| L - Consent and Sharing Toggle | Depends on Task 4 | Not started |
| Emergency Contacts update | Backend already supports `PUT`, `ProfileProvider` doesn't call it | Not started, not scheduled |

## Known-good, already implemented (verified against source, not assumed)

- Auth: JWT, bcrypt, client-side pre-hash (`backend/api/auth/`)
- Route protection via `AuthGuard` (`lib/core/security/auth_guard.dart`)
- JWT stored via `flutter_secure_storage`, encrypted Android prefs, not `SharedPreferences`
- Input validation and injection pattern detection (`lib/core/security/security_utils.dart`)
- Symptom Checker rule engine, on-device, zero network calls, eleven named conditions
- Emergency Contacts: create, read, delete (not update) on both frontend and backend
- No local database or file cache for health records, reduces at-rest exposure surface to the JWT token only

## Open, unresolved before Phase 1 can fully close

- Clinic seed data conflict: `backend/schema.sql` (10 rows) and `backend/seed_clinics.php` (11 different rows) do not overlap. Must confirm which is live before Epic M records anything involving a clinic recommendation.
