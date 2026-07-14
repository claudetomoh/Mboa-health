# Evidence Matrix

Maps every official scoring criterion to what actually exists in this repository. This is
the master reference for writing the Project Document — every claim made there should trace
back to a row here, and every row here should trace back to `MBOA_HEALTH_CURRENT_SYSTEM_SPEC.md`
or a specific file. Last synchronized: 2026-07-14. Criteria and points are verbatim from
`docs/competition/official/Reglement2026_en_Concours.pdf`.

Legend: **Repository Evidence** = what exists and where. **Screens** = what a judge/demo
viewer would see. **Documentation** = which internal doc describes it. **Remaining Gap** =
what's missing before this criterion is maximally strong.

Note on citations: only ADRs that actually exist in `DECISIONS.md` (currently ADR-001 through
ADR-006) are cited below. Any "Team Onboarding Guide" reference is marked external, since no
such file is committed to this repository (see the note at each occurrence).

---

## Pre-selection criteria (100 points)

### 1. Relevance of the project (20 pts)

| | |
|---|---|
| Repository Evidence | Patient and provider interview research, documented recurring problems (fragmented records, repeated history-taking, poor continuity of care) |
| Screens | N/A (narrative, not a screen) |
| Documentation | External reference — `Mboa_Health_Team_Onboarding_Playbook`, not currently committed to this repository (only a local `.docx` exists); until it is committed, this evidence is not independently verifiable from repo contents alone |
| Remaining Gap | Commit the Onboarding Playbook (or extract its §3–4 research narrative into a committed markdown file) so this evidence is verifiable from the repo; otherwise carry the narrative into the Project Document unchanged |

### 2. Innovative Nature of the Solution (15 pts)

| | |
|---|---|
| Repository Evidence | Digital Health Passport concept; QR-code emergency data sharing, offline-capable in principle; hybrid architecture (deterministic rule engine + planned narrow AI mapping layer) |
| Screens | Emergency Portal → Digital Health Passport section (`passport_section.dart`): status, Show QR, View as Text, Regenerate, Disable/Enable |
| Documentation | CSS §3.12, §6.8; DECISIONS.md ADR-001 |
| Remaining Gap | QR scanning (Task 6) not built — generation exists, the reciprocal "scan and view" flow doesn't. Live device verification not performed. |

### 3. Technical feasibility (15 pts)

| | |
|---|---|
| Repository Evidence | Working Android app; real PHP/MySQL backend; parameterized queries throughout; JWT auth with bcrypt; CSS generated directly from source, not assumption |
| Screens | Every implemented screen (auth, dashboard, health records, reminders, clinics, symptom checker, emergency/passport) |
| Documentation | CSS (all sections); ARCHITECTURE.md |
| Remaining Gap | Consistency sweep across judge-facing documents (Epic A remainder) not complete; passport work verified by static analysis only, not a live run |

### 4. Socio-Economic Impact (15 pts)

| | |
|---|---|
| Repository Evidence | Research-backed problem statements; target beneficiaries (patients in Cameroon, fragmented-record pain point) |
| Screens | N/A (narrative) |
| Documentation | External reference — `Mboa_Health_Team_Onboarding_Playbook`, not currently committed to this repository (see criterion 1's note) |
| Remaining Gap | Same as criterion 1 — commit the source document; otherwise carry forward existing narrative |

### 5. Business Model and Sustainability (10 pts)

| | |
|---|---|
| Repository Evidence | Existing pitch deck go-to-market slide (unvalidated hospitals-as-customer assumption, flagged as such) |
| Screens | N/A |
| Documentation | TODO.md, `Mboa_Health_Engineering_Backlog_v3.md` Epic C; External reference — `Mboa_Health_Team_Onboarding_Playbook` §8.2, not currently committed to this repository (see criterion 1's note) |
| Remaining Gap | Business model reframe (Epic C) not started — replace unvalidated claims with an honest "under review" framing |

### 6. Use of AI in the Proposed Solution (10 pts)

| | |
|---|---|
| Repository Evidence | Deterministic, on-device rule engine (`_runRuleEngine`, eleven conditions) exists and is real; a narrow AI free-text-mapping layer is specified (Epic H / Tasks 7–8) but not built |
| Screens | Symptom Checker flow, results screen (now honestly labeled "Rule-Based Guidance," not AI — CC-01) |
| Documentation | CSS §3.15; DECISIONS.md ADR-002 |
| Remaining Gap | AI layer itself is Gate-2 scope (only if shortlisted) — describe accurately as planned, not built, in the Project Document |

### 7. Contribution to Digital Patriotism and Cybersecurity (15 pts)

| | |
|---|---|
| Repository Evidence | JWT auth (HMAC-SHA256, constant-time verification), bcrypt password storage, client-side pre-hash, parameterized queries everywhere, content-sniffed file upload validation, isolated public passport endpoint (`passport/view.php`, no auth, own file per ADR-001), CSPRNG token generation (`generate_secure_token()`, never derived from user id/email/phone/timestamp) |
| Screens | Not directly visible in UI — this is backend/architecture evidence |
| Documentation | CSS §6.8, §9; ARCHITECTURE.md security module section; DECISIONS.md ADR-001 |
| Remaining Gap | **No written security and privacy architecture document exists (Epic B).** This is the single highest-value, lowest-effort gap against this criterion — the evidence already exists, it just isn't written up. |

**Pre-selection subtotal readiness:** strong on Relevance, Socio-Economic Impact, and (once Epic B lands) Cybersecurity. Weakest on Business Model and Use of AI, both by honest design — neither is fabricated, both are accurately labeled as in-progress.

---

## Grand Jury criteria (100 points, 15 shortlisted finalists only)

### 1. Quality of the pitch and command of the project (10 pts)
Not yet applicable — depends on rehearsal (Epic K), which only starts if shortlisted.

### 2. Innovative nature and differentiation (20 pts)
Same evidence as pre-selection criterion 2, at higher weight. QR scanning and a live-device demo are the gap.

### 3. Demonstration of the product or prototype (20 pts)
| | |
|---|---|
| Repository Evidence | Every Implemented screen is demoable today (auth, health records, reminders, clinics, symptom checker, Digital Health Passport generation/status/lifecycle — foundation complete, Commit `dd2a275`) |
| Remaining Gap | QR scanning; live device/offline verification of the passport flow; a rehearsed demo script (Epic M/K) |

### 4. Socio-economic impact and value for Cameroon (20 pts)
Same evidence as pre-selection criterion 4, at higher weight. No new gap.

### 5. Economic viability and business model (10 pts)
Same gap as pre-selection criterion 5 — Epic C.

### 6. Scalability and deployment strategy (10 pts)
| | |
|---|---|
| Repository Evidence | Offline-first-leaning architecture (no server dependency for the rule engine or QR generation once a token is known); simple PHP/MySQL backend, no heavyweight framework, low hosting cost |
| Remaining Gap | No explicit scalability narrative exists yet in any pitch material — low effort to draft, not started |

### 7. Contribution to digital sovereignty, AI and cybersecurity (10 pts)
| | |
|---|---|
| Repository Evidence | Same as pre-selection criterion 7, plus: shared Cameroonian hosting (not a foreign cloud dependency), which incidentally aligns with this criterion's "local hosting, reduced technological dependence" language |
| Remaining Gap | Security/privacy document (Epic B); clinical review record (Epic I) for the AI-adjacent trust story |

---

## Cross-cutting gaps (affect multiple criteria)

| Gap | Affects | Owner |
|---|---|---|
| Security and privacy architecture document doesn't exist | Pre-selection #7 (15 pts), Grand Jury #7 (10 pts) | Epic B |
| Business model reframe not done | Pre-selection #5 (10 pts), Grand Jury #5 (10 pts) | Epic C |
| QR scanning not built | Pre-selection #2/#3, Grand Jury #2/#3 | Task 6 |
| Passport work unverified on a live device | Pre-selection #3, Grand Jury #3 | Full team, before any demo |
| Clinic seed data conflict unresolved | Any demo showing a clinic recommendation | Backend |
| `emergency_passports` table not confirmed live | Grand Jury #3 (demonstration) | Backend |

---

## How to use this document when writing the Project Document

For every section of the Project Document, pull the "Repository Evidence" column directly —
don't reconstruct it from memory or from older pitch materials. Where "Remaining Gap" lists
something not yet done, either close it first or label it explicitly as planned/Competition
Build, matching the discipline already established in `MBOA_HEALTH_CURRENT_SYSTEM_SPEC.md`.
Nothing in the Project Document should claim more than what's in the corresponding row here.

---

**Status summary (as of this revision):** Digital Health Passport foundation — authenticated
lifecycle, public view endpoint, and QR **generation** — is complete (Commit `dd2a275`). QR
**scanning** remains pending (Task 6, not built). The Symptom Checker's prior AI overclaim has
been corrected in-app; "Use of AI" is accurately described above as planned, not built.
Governance tracking (`TODO.md`, `Mboa_Health_Engineering_Backlog_v3.md`, `RISK_REGISTER.md`)
is synchronized with this state as of Commit `1b3bc41`.

Last verified against repository commit `1b3bc41`.
