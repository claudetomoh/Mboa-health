# Mboa Health - Risk Register

Severity: Critical / High / Medium / Low. Update the same day a risk is found or resolved.

| Risk | Severity | Status | Owner | Notes |
|---|---|---|---|---|
| Implementation Master Plan v1.1 not committed to repo; repo has stale v1.0 | Critical | Resolved | Product | v1.1 (`Mboa_Health_Implementation_Master_Plan_v1.1.docx`) is now committed to the repo. |
| TODO.md, DECISIONS.md, RISK_REGISTER.md, Engineering Backlog didn't exist | Critical | Resolved this session | Technical Lead | Created and ready to commit. Keep synchronized per Development Rules. |
| Symptom Checker false AI claim present in two locations, not one | High | Resolved | Frontend | `symptom_checker_screen.dart:492` and `dashboard_screen.dart:423` both corrected; see CSS §3.15. |
| Clinic seed data: two non-overlapping datasets (`schema.sql` vs `seed_clinics.php`), unknown which is live | Medium | Open | Backend | Affects the Recommended Clinic card shown after a Symptom Checker result. Must resolve before Epic M records any footage that includes a clinic recommendation. |
| Client-side-only rate limiting on login does not protect the API endpoint directly | Medium | Open | Backend | Task 9, Phase 3. Not blocking Phase 1 or 2. |
| Symptom Checker documented as twelve conditions, actually implements eleven | Low | Open | Product / Clinical Validation | Correct before Epic I scopes the reviewer's task, so the reviewer isn't asked to review a condition that doesn't exist. |
| Emergency Contacts cannot be edited in place, only added/deleted, despite backend supporting update | Low | Logged, not scheduled | Frontend | Out of scope this cycle. See DECISIONS.md ADR-006. |
| Video length/format requirements not yet confirmed against competition rules | Low | Open | Product | Must resolve before Epic M's acceptance criteria can be treated as final. |
