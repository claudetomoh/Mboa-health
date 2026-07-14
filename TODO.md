# Mboa Health - TODO

Source of truth for task status. Update the same day a task lands. Cross-references
Implementation Master Plan v1.1 (Section 2, epics A through M) and Section 7 (Claude Code tasks).

## Phase 1: Video and Submission Gate

- [ ] Epic E - Clinical reviewer outreach (contact only)
- [x] Task 1 (Epic A) - landed in both locations (`symptom_checker_screen.dart`, `dashboard_screen.dart`); see CSS §3.15
- [ ] Epic A remainder - pitch deck / Product Vision Blueprint / Onboarding Guide narrative sweep (OWASP claim, freemium/B2B claims)
- [ ] Epic B - Security and privacy architecture document
- [ ] Epic C - Business model reframe
- [x] Epic G - Medical ID card wired to real profile data (blood-type consolidation sub-task cut, no dual entry point exists) - superseded by the Digital Health Passport section; see CSS §3.12
- [x] Task 4 - Backend, QR Passport public endpoint
- [x] Task 5 - Frontend, QR code generation screen
- [ ] Task 6 - Frontend, QR code scanning screen
- [ ] Epic D - Project Document assembly and submission
- [ ] Epic M - Video demonstration production
  - [ ] Confirm video length/format requirements from competition rules before recording
- [ ] New: resolve clinic seed data conflict (schema.sql vs seed_clinics.php) before Epic M records anything using clinic recommendations

## Phase 2: Pitch Gate (only if shortlisted)

- [ ] Task 7 - Backend, AI free-text symptom mapping endpoint
- [ ] Task 8 - Frontend, hook free-text input into Symptom Checker
- [ ] Epic I - Clinical review execution (scope: eleven conditions, not twelve, correct before reviewer engagement)
- [ ] Epic K - Demo rehearsal and offline QA

## Phase 3: Nice to Have

- [ ] Task 9 - Server-side rate limiting on auth endpoints (client-side RateLimiter already exists in `lib/core/security/rate_limiter.dart`, wired into `login_screen.dart`, but does not protect the API directly)
- [ ] Task 10 - QR passport access log
- [ ] Epic L - Consent and sharing toggle
- [ ] Add `updateEmergencyContact()` to `ProfileProvider` (backend already supports PUT on `emergency_contacts/index.php`, frontend never calls it, contacts can be added/deleted but not edited)

## Process

- [x] Commit Implementation Master Plan v1.1 to the repo, replacing v1.0 as the checked-in reference
