# Mboa Health - Decisions Log

Architectural and process decisions, with reasoning. Append, don't rewrite history.

---

## ADR-001: Public QR passport endpoint stays in its own file

**Decision:** The public-facing emergency passport endpoint lives in a separate file from
authenticated passport endpoints, never a shared router with conditional authentication.

**Reasoning:** Reduces the chance that a future change to authenticated routes accidentally
removes protection from something that should never have been public. Cheap to enforce now,
expensive to retrofit later.

**Status:** Standing rule for Task 4 and any future passport work.

---

## ADR-002: AI free-text mapping layer never touches the rule engine's decision logic

**Decision:** The Symptom Checker's AI mapping layer (Task 7/8) only maps free text to
structured symptoms from the existing catalogue. The rule engine in
`symptom_checker_provider.dart` (`_runRuleEngine`) must have zero diff as a result of this work.

**Reasoning:** Keeps the triage decision deterministic, auditable, and reviewable by a
clinician independent of whatever the AI layer does. Also the cleanest "responsible AI"
story for the competition's digital sovereignty theme.

**Status:** Standing rule, enforced by code review, not just documentation.

---

## ADR-003: Corrected file path for the Emergency Portal screen

**Decision:** All references to `lib/features/emergency_portal/` are corrected to
`lib/features/emergency/emergency_portal_screen.dart`.

**Reasoning:** The Implementation Master Plan v1.0/v1.1 assumed a path that doesn't exist in
the repo. Confirmed against the actual tree. Affects Master Plan Tasks 3, 5, and 6.

**Status:** Applied going forward. Master Plan document itself not regenerated for this,
too small to warrant a new revision; this log is the correction of record.

---

## ADR-004: Implementation Master Plan v1.1 supersedes v1.0

**Decision:** v1.1 (video-inclusive strategy: QR Passport and Medical ID promoted to
Must Build Before Video Submission, rather than postponed to the pitch phase) is the
authoritative plan. v1.0, currently the only version checked into the repo, is stale.

**Reasoning:** The submission requirement changed to include a recorded video demonstration
in addition to the Project Document, which invalidated v1.0's "documents first, engineering
postponed" sequencing.

**Status:** v1.1 needs to be committed to the repo. Until it is, v1.0 in the repo does not
reflect current priorities and should not be executed against.

---

## ADR-005: Client-side rate limiting is not sufficient on its own

**Decision:** `lib/core/security/rate_limiter.dart`, already implemented and wired into
`login_screen.dart`, is retained, but does not satisfy the security hardening requirement
(Task 9) on its own.

**Reasoning:** It's in-memory and client-side. Any request made directly against
`backend/api/auth/login.php`, bypassing the Flutter app entirely, is not throttled.
Task 9 adds server-side rate limiting to close that gap.

**Status:** Task 9 remains open (Phase 3, Nice to Have).

---

## ADR-006: Emergency Contacts update is not exposed, by omission not by design

**Decision:** No change made yet. Logged so it isn't mistaken for an intentional CRD-only
design.

**Reasoning:** The backend (`backend/api/emergency_contacts/index.php`) supports `PUT`.
`ProfileProvider` only calls `POST` (add) and `DELETE`. Contacts cannot be edited in place
from the app today, only removed and re-added.

**Status:** Out of scope for this cycle. Tracked in TODO.md, not blocking.
