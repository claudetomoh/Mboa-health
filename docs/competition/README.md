# ICT Innovation Challenge — Competition Documentation

This folder is the **single source of truth** for everything related to the
ICT Innovation Challenge, organized by the Ministry of Posts and
Telecommunications of Cameroon. If a question comes up about competition
rules, scoring, submission requirements, or where our own competition
materials live, it gets answered here — not from memory, not from an older
pitch deck, and not from an assumption.

**Future engineers, and anyone else joining this project, must read the
relevant documents in this folder before making implementation decisions
that touch competition scope, scoring, or submission requirements.**
Official competition documents always take precedence over assumptions,
prior conversations, or anything written before those documents were
reviewed. If something in `official/` conflicts with anything elsewhere in
this repository — the Team Onboarding Playbook, the Engineering Backlog,
a pitch deck, this document — `official/` wins, and the conflicting
document should be corrected.

Engineering decisions made in support of this competition should aim to
maximize our score against the official rubric while maintaining the
technical quality, honesty, and scope discipline already established
elsewhere in this repository (see `DECISIONS.md` and
`MBOA_HEALTH_CURRENT_SYSTEM_SPEC.md`). A feature or claim that scores
points but isn't real, isn't built, or misrepresents the system is not
a net win — it is exactly the kind of risk this repository's other
documentation already exists to prevent.

## Folder structure

```
docs/competition/
├── README.md                          — this file
├── COMPETITION_ENGINEERING_GUIDE.md    — official rubric translated into engineering priorities
├── EVIDENCE_MATRIX.md                  — every rubric criterion mapped to repo evidence, screens, gaps
├── official/       — documents provided by the organizers
├── application/    — our submitted application materials
├── submissions/     — final, submission-ready deliverables
├── reviews/          — internal audits and readiness assessments
└── assets/            — branding, screenshots, diagrams, media
```

`COMPETITION_ENGINEERING_GUIDE.md` and `EVIDENCE_MATRIX.md` sit at the root of this folder
rather than in a subfolder, since they're synthesis documents this team wrote (not official
source material, not a final submission artifact) — read them first, then go to `official/`
for the primary source whenever a claim needs verifying.

### `official/`

Documents **provided by the competition organizers** — not written by this
team. This is the authoritative source for anything the Ministry defines,
including:

- Competition Guidelines
- Judging Rubric
- Rules
- FAQs
- Submission Instructions
- Video Requirements

If a document belongs here, it should be stored as close to its original,
unedited form as possible. Do not paraphrase or summarize official rules
into another document instead of keeping the source here — link to it.

### `application/`

Our own submitted application materials: the completed application form,
proposal, pitch deck, business model writeup, and any other document we
prepared and submitted (or intend to submit) as part of entering the
competition.

### `submissions/`

Final versions of what actually gets delivered to the competition,
distinct from drafts or working copies kept elsewhere in the repo:

- Project document
- Video script
- Demo script
- Presentation
- Submission checklist

### `reviews/`

Internal assessments of where we stand against the competition
requirements:

- Competition Readiness Audit
- Gap Analysis
- Engineering Review
- Judge Preparation Notes

### `assets/`

Competition branding, logos, screenshots, diagrams, and any other media
used across application, submission, or review materials.

## How this relates to the rest of the repository

This folder is about the *competition* — what the Ministry requires, what
we're submitting, and how we're tracking readiness against it. It does not
replace or duplicate the repository's existing engineering documentation:

- `MBOA_HEALTH_CURRENT_SYSTEM_SPEC.md` remains the source of truth for what
  is actually built.
- `DECISIONS.md`, `RISK_REGISTER.md`, and `TODO.md` remain the source of
  truth for engineering decisions, risks, and task status.
- This folder is the source of truth for competition rules, scoring, and
  submission state.

If a fact belongs in more than one place, it should be written once and
referenced from the others, not duplicated.

---

Last verified against repository commit `1b3bc41`.
