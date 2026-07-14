# Competition Engineering Guide

Authoritative synthesis of `docs/competition/official/` into engineering-actionable terms.
Where this document and the official PDFs disagree, the official PDFs win — this document
exists to translate them, not replace them. Last synchronized: 2026-07-14.

---

## 1. Competition objectives

**Competition:** National Competition for the Best ICT Project, part of the 5th ICT
Innovation Week (SIN 2026), organized by the Ministry of Posts and Telecommunications
(MINPOSTEL), Cameroon, under the theme *"Protecting Cyberspace from the Misuse of Artificial
Intelligence and Promoting Digital Patriotism."*

**Overall objective:** mobilize the national digital ecosystem around cyberspace protection,
responsible AI use, and digital patriotism, while identifying and rewarding the best
youth-led ICT projects.

**Specific objectives:** identify/reward digital innovations protecting cyberspace and
fighting disinformation; build project-leader capacity (training, coaching, pitch prep);
foster digital entrepreneurship; increase visibility of Cameroonian digital innovation;
promote ethical, patriotic cyberspace use.

**Eligibility (hard gate, not scored):** Cameroonian nationality, an innovative ICT project,
Cameroonian residency. **Startups already operational and generating revenue are not
eligible.** One project per person, one project per startup, one startup per person.
Applications from women are strongly encouraged. MINPOSTEL staff and jury members cannot
enter. *(Source: TDR Section IV.1, Rules Articles 5(1), 6, 7.)*

**Priority area:** Mboa Health fits Priority Area E, Health (telemedicine, digital medical
record management, medical assistance applications, improved access to care), with a
credible secondary claim on Priority Area A, Cybersecurity (personal data protection).

---

## 2. Judging criteria and scoring rubric (verbatim from the official Rules)

### Pre-selection (100 points — scores the submitted Project Document)

| # | Criterion | Points |
|---|---|---|
| 1 | Relevance of the project | 20 |
| 2 | Innovative Nature of the Solution | 15 |
| 3 | Technical feasibility | 15 |
| 4 | Socio-Economic Impact | 15 |
| 5 | Business Model and Sustainability | 10 |
| 6 | Use of AI in the Proposed Solution | 10 |
| 7 | Contribution to Digital Patriotism and Cybersecurity | 15 |

### Grand Jury / final pitch (100 points — for the 15 shortlisted finalists only)

| # | Criterion | Points |
|---|---|---|
| 1 | Quality of the pitch and command of the project | 10 |
| 2 | Innovative nature and differentiation | 20 |
| 3 | Demonstration of the product or prototype | 20 |
| 4 | Socio-economic impact and value for Cameroon | 20 |
| 5 | Economic viability and business model | 10 |
| 6 | Scalability and deployment strategy | 10 |
| 7 | Contribution to digital sovereignty, AI and cybersecurity | 10 |

The Grand Jury also reviews: the updated project document, the project marketing video, the
business model, the go-to-market strategy, the oral pitch with a digital presentation (pitch
deck), and a live demonstration of the product/prototype. *(Source: Rules Articles 5(2), 5(3).)*

---

## 3. The corrected timeline — read this before scheduling anything

| Date | Event | Gate |
|---|---|---|
| 22 June 2026 | Competition launch | — |
| 22 June – **22 July 2026, 3:30 PM** | Online registration | **Gate 1** |
| 2–23 July 2026 | Pre-selection committee review | — |
| **24 July 2026, 12:00 PM** | Shortlist (top 15) published | — |
| 25–26 July | Arrival in Yaoundé (shortlisted only) | — |
| 27–29 July | Bootcamp | — |
| **30 July 2026** | Final pitch | **Gate 2** |
| 31 July 2026 | Awards ceremony | — |

**Gate 1 (Registration, due 22 July) requires only:** the online form (name, address, email,
phone) and a project document PDF, ticking acceptance of the Rules. **No video, pitch deck,
or working demo is required to register.** *(Rules Article 9.)*

**Gate 2 (Grand Jury, for the 15 shortlisted finalists only, ~30 July) requires:** the
updated project document, the marketing video, business model and go-to-market strategy, an
oral pitch with slides, and a live product demonstration. *(Rules Article 5(3).)*

**Correction record:** Implementation Master Plan v1.1's original "Implementation Strategy
Update" assumed the video was required at Gate 1. It is not. This correction is not tracked
as a separate ADR in `DECISIONS.md` (no ADR-010 exists there — see `DECISIONS.md`'s current
ADR-001 through ADR-006); it is recorded here and in the Rules citation above (Article 9) as
the source of record. This guide and the Master Plan itself have both been corrected as of
2026-07-12.

**Video length/format:** not specified anywhere in the three official documents. Confirmed
absent, not merely undocumented internally — raise with the organizer, or proceed on
reasonable defaults closer to the Gate 2 date.

---

## 4. Engineering priorities (ordered by what actually gates what)

### Priority 1 — Gate 1, due 22 July (10 days out as of this writing)
1. **Project Document assembly (Epic D).** The only literal registration requirement. Not
   started. This is the single highest-priority item in the repository right now.
2. **Confirm competition eligibility** (Rules Article 7) before registering — a hard gate,
   cheap to check now.

### Priority 2 — strengthens the Project Document, doesn't gate it
3. **Security and privacy architecture document (Epic B)** — 15 of 100 pre-selection points,
   with real, already-implemented evidence (JWT, bcrypt, parameterized queries, the isolated
   `passport/view.php` design) and nothing written up yet. Low effort, high payoff.
4. **Business model reframe (Epic C)** — 10 of 100 pre-selection points, already scoped as
   low-effort in the Master Plan.
5. **Truth-in-UI document sweep (Epic A remainder)** — code-level fixes are done; the pitch
   deck / Product Vision Blueprint / onboarding-materials sweep is not.

### Priority 3 — Gate 2, only if shortlisted (~30 July)
6. **QR code scanning (Task 6)** — the one remaining Must-Build engineering item. The Digital
   Health Passport foundation — backend lifecycle and QR **generation** (CC-04, CC-05A,
   CC-05B) — is complete and committed (Commit `dd2a275`); scanning is not built. Not
   registration-blocking.
7. **Live device/offline verification** of the Digital Health Passport work — everything
   shipped so far has been verified by code trace and static analysis only, not a live run.
8. **Video demonstration production (Epic M)** — depends on #6 and #7 being stable.
9. **Clinical review of the rule engine (Epic E outreach → Epic I execution)** — long lead
   time, should already be running in the background regardless of Gate 1/2 status.

---

## 5. Frozen scope

Unchanged from the Master Plan's Section 1 scope freeze — nothing outside these buckets gets
built this cycle:

- **Must build:** Truth-in-UI correction, security/privacy doc, business model reframe,
  Digital Health Passport (backend, generation, scanning), Project Document, video, clinical
  reviewer outreach.
- **Must build only if shortlisted:** AI free-text mapping layer, clinical review execution,
  full offline demo rehearsal.
- **Nice to have:** server-side rate limiting, passport access log, consent/sharing toggle,
  video polish, passport expiry/revocation, passport access analytics, general UX polish.
- **Explicitly out of scope:** iOS build, chronic conditions field, telemedicine, pharmacy/lab
  integration, predictive analytics, full clinical validation study, a finalized specific
  business model, provider portal/sync engine/dedicated AI inference service, multi-country
  expansion.

## 6. Current competition strategy

Register by 22 July with an honest, evidence-backed Project Document that claims exactly what
`MBOA_HEALTH_CURRENT_SYSTEM_SPEC.md` and `docs/competition/EVIDENCE_MATRIX.md` can support —
no more, no less. Use the 10 days before registration to close the two cheap, high-value
documentation gaps (security/privacy doc, business model reframe) rather than racing to
finish QR scanning or a video that isn't due yet. If shortlisted on 24 July, pivot hard to
Gate 2: finish QR scanning, verify everything on a live device and offline, then produce the
video and rehearse the pitch in the ~6 days before 30 July, 3 of which are the structured
Bootcamp.

---

**Status summary (as of this revision):** Digital Health Passport foundation (backend
lifecycle + QR generation) is complete (Commit `dd2a275`); QR scanning is pending (Task 6).
The Symptom Checker's prior AI overclaim is corrected in-app; AI use is accurately described
as planned, not built. Governance tracking (`TODO.md`, `Mboa_Health_Engineering_Backlog_v3.md`,
`RISK_REGISTER.md`) is synchronized with this state as of Commit `1b3bc41`.

Last verified against repository commit `1b3bc41`.
