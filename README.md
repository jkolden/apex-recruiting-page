# Management Report (Page 24) — Oracle APEX Recruiting Dashboard

**App**: 121 — Fusion Integrated Sample App
**APEX Version**: 24.2.17
**Database**: Oracle Autonomous Transaction Processing (ATP)
**Schema**: WKSP_FREEDEMO

## Recent Changes

**2026-09-03 — dev2 migration (v2 view)**
- `RECRUITING_REPORT_V` updated for Fusion dev2 environment
- EFF context renamed: "Additional GCS Person Data" + "GCS Job Application References" → merged into "GCS Recruiting Details" (`ext_flex_recruiting_v`)
- Questionnaire reference codes renamed: `GCS_TEACH_REF_*` → `GCS_REF_EXT_*` / `GCS_EXT_REF_*` (view output aliases kept as `GCS_TEACH_REF_*` for APEX backward compatibility)
- Retirement context: added `subject_to_earnings_limit`, `teri_begin_date`, `teri_end_date`
- New recruiting detail columns: `pay_grade`, `pay_step`, `processing_owner`, `contract_type`, `teacher_years_of_experience`, `educator_id`, `cate_experience`, `fte`
- View DDL files added to `views/` folder

## Overview

Page 24 is the primary recruiting management page — a faceted search interactive report built on `RECRUITING_REPORT_V` that provides recruiters and hiring managers with a comprehensive view of all job applicants. The page integrates data from Oracle Fusion Cloud HCM via REST APIs and BICC extracts, and adds locally-managed features like applicant ranking, notes, and reference correction.

## Features

### 1. Move Applicant Between Phases/States
Slide-out drawer that moves a job application through the recruiting workflow (e.g., Screen → Interview → Offer) by calling the Fusion REST API.

| Component | File |
|-----------|------|
| JavaScript | [`js/move-applicant.js`](js/move-applicant.js) |
| CSS | [`css/move-drawer.css`](css/move-drawer.css) |
| Ajax: GET_APP_DETAILS | [`plsql/get_app_details.sql`](plsql/get_app_details.sql) |
| Ajax: MOVE_APPLICANT | [`plsql/move_applicant.sql`](plsql/move_applicant.sql) |
| Package | `pkg_rec_move.move_application` (REST POST to Fusion) |

### 2. Applicant Ranking by Recruiter
Slide-out drawer for scoring applicants 1-5 and adding a recommendation (Highly Recommended / Recommended / Consider / Not Recommended).

| Component | File |
|-----------|------|
| JavaScript | [`js/ranking-drawer.js`](js/ranking-drawer.js) |
| CSS | [`css/ranking-drawer.css`](css/ranking-drawer.css) |
| Ajax: GET_RANKING_DETAILS | [`plsql/get_ranking_details.sql`](plsql/get_ranking_details.sql) |
| Ajax: SAVE_RANKING | [`plsql/save_ranking.sql`](plsql/save_ranking.sql) |
| Table | `applicant_ranking` (MERGE on job_application_id) |

### 3. Reference Correction Link (Email to Applicant)
Generates a secure one-time URL and emails it to applicants so they can correct their reference contact information (name, phone, email for up to 3 references).

| Component | File |
|-----------|------|
| JavaScript | [`js/ref-correction-link.js`](js/ref-correction-link.js) |
| CSS | [`css/ref-link-drawer.css`](css/ref-link-drawer.css) |
| Ajax: GENERATE_REF_LINK | [`plsql/generate_ref_link.sql`](plsql/generate_ref_link.sql) |
| Ajax: SEND_REF_LINK_EMAIL | [`plsql/send_ref_link_email.sql`](plsql/send_ref_link_email.sql) |
| Package | `pkg_ref_correction` (token generation + email) |
| Public page | Page 100 (alias `REF-CORRECT`) — applicant-facing correction form |

### 4. Attachment Viewer (Download from Fusion)
Centered modal that lists attachments for a job application, fetched from Fusion via REST, with file type icons and download links.

| Component | File |
|-----------|------|
| JavaScript | [`js/attachment-modal.js`](js/attachment-modal.js) |
| CSS | [`css/attachment-modal.css`](css/attachment-modal.css) |
| Ajax: LIST_ATTACHMENTS | [`plsql/list_attachments.sql`](plsql/list_attachments.sql) |
| Package | `pkg_app_attachments.list_attachments` |

### 5. Candidate & Applicant Notes
Inline expandable panels for adding/viewing notes. Two levels:
- **Candidate Notes** — tied to a specific job application (job_application_id)
- **Applicant Notes** — tied to a person across all applications (person_id)

| Component | File |
|-----------|------|
| JS (external) | `candidate_notes_js.js`, `applicant_notes_js.js` (APEX Static Files) |
| CSS (external) | `candidate_notes_css.css`, `applicant_notes_css.css` (APEX Static Files) |
| Ajax: GET_NOTES | [`plsql/get_notes.sql`](plsql/get_notes.sql) |
| Ajax: ADD_NOTE | [`plsql/add_note.sql`](plsql/add_note.sql) |
| Ajax: GET_APPLICANT_NOTES | [`plsql/get_applicant_notes.sql`](plsql/get_applicant_notes.sql) |
| Ajax: ADD_APPLICANT_NOTE | [`plsql/add_applicant_note.sql`](plsql/add_applicant_note.sql) |

### 6. Candidate Phone Numbers
Inline expandable panel showing phone numbers from Fusion (fetched via REST child resource expansion).

| Component | File |
|-----------|------|
| JS (external) | `candidate_phones_js.js` (APEX Static Files) |
| CSS (external) | `candidate_phones_css.css` (APEX Static Files) |
| Ajax: GET_PHONES | [`plsql/get_phones.sql`](plsql/get_phones.sql) |
| Table | `candidate_phones_r` (loaded by `pkg_rest_recruiting`) |

### 7. Deep Links to Fusion
IR columns include direct links to Oracle Fusion Cloud pages for:
- Job Requisitions (open in Fusion Recruiting)
- Job Applications (open applicant profile in Fusion)

### 8. Gallup Assessment Scores
IR columns display Gallup assessment results with color-coded badges:
- Band: High Performer (green), Mid Performer (blue), Low Performer (amber)
- Score: gradient coloring (green >= 50, amber 30-49, red < 30)

| Component | File |
|-----------|------|
| CSS | [`css/gallup-ranking-badges.css`](css/gallup-ranking-badges.css) |

## Security

### Function Security (Page-Level Authorization)
- **Authorization scheme**: `IS_RECRUITING_MGR` — requires `ADMIN` or `RECRUITING_MGR` role in `app_user_roles`
- **Package**: `pkg_app_security` — role check functions

### Row-Level Security (VPD)
- **VPD policy**: `REC_DEPT_READ_POLICY` on `RECRUITING_REPORT_V`
- **Package**: `rec_rls_pkg` — generates WHERE clause predicate
- **5 access paths** (OR'd together):
  1. User is the recruiter on the requisition
  2. User is the hiring manager on the requisition
  3. Wide department grant (all reqs in a department)
  4. Specific recruiter + department grant
  5. Specific hiring manager + department grant
- **Override table**: `rec_dept_grant` — admin-managed department-level access overrides
- **Bypass**: ADMIN role or no APEX session (schema owner)

## Faceted Search Filters

| Facet | Source Column | Type |
|-------|-------------|------|
| Search | 35+ columns | Free text (row search) |
| Published Posting Status | PUBLISHED_POSTING_STATUS | Checkbox |
| Requisition | JOB_REQUISITION_ID | Checkbox (custom LOV with Req# + Job + School + HM + State) |
| Job | JOB | Checkbox |
| School | SCHOOL | Checkbox |
| Department | DEPARTMENT_NAME | Checkbox |
| Hiring Manager | HIRING_MANAGER | Checkbox |
| Application Phase | APPLICATION_PHASE | Checkbox |
| Name | NAME | Checkbox |

## IR Column Groups

The report uses column grouping with color-coded backgrounds:
- **Reference 1** (`ref1`): light blue `#f0f4ff`
- **Reference 2** (`ref2`): light green `#f0fff4`
- **Reference 3** (`ref3`): light orange `#fff8f0`
- **Published Job Postings**: cream `#FFF8DC`

## Page Initialization

[`js/page-init.js`](js/page-init.js) — Injects three backdrop overlays and three inline alert banners (one per drawer) into the DOM on page load.

## Computation

- **P24_TICKET_COUNT** (Before Box Body): Counts open tickets (`status NOT IN ('RESOLVED','CLOSED')`) assigned to or submitted by the current user. Displayed in the "Open Tickets" button.

## File Structure

```
apex-recruiting-page-24/
├── README.md                          # This file
├── apex-export/
│   └── f121_page_24.sql               # Original APEX page export (3,560 lines)
├── js/                                # Extracted JavaScript by feature
│   ├── page-init.js                   # Backdrop/alert injection
│   ├── move-applicant.js              # Move phase/state drawer
│   ├── ranking-drawer.js              # Score/recommend drawer
│   ├── ref-correction-link.js         # Reference correction link drawer
│   └── attachment-modal.js            # Attachment viewer modal
├── css/                               # Extracted CSS by component
│   ├── ir-columns.css                 # Column widths, pills, badges, typography
│   ├── move-drawer.css                # Move drawer + backdrop + alert
│   ├── ranking-drawer.css             # Ranking drawer + backdrop + alert
│   ├── ref-link-drawer.css            # Ref link drawer + backdrop + alert
│   ├── attachment-modal.css           # Attachment modal overlay
│   ├── gallup-ranking-badges.css      # Color-coded assessment/ranking badges
│   └── responsive.css                 # Mobile breakpoints
├── plsql/                             # Extracted Ajax callbacks (ON_DEMAND processes)
│   ├── get_app_details.sql            # Load applicant info for move drawer
│   ├── move_applicant.sql             # REST POST to Fusion via pkg_rec_move
│   ├── list_attachments.sql           # Fetch attachments via pkg_app_attachments
│   ├── get_ranking_details.sql        # Load ranking from applicant_ranking
│   ├── save_ranking.sql               # MERGE into applicant_ranking
│   ├── generate_ref_link.sql          # Generate token via pkg_ref_correction
│   ├── send_ref_link_email.sql        # Email correction link
│   ├── get_notes.sql                  # Fetch candidate notes
│   ├── add_note.sql                   # Add candidate note
│   ├── get_phones.sql                 # Fetch candidate phones
│   ├── get_applicant_notes.sql        # Fetch applicant notes (person-level)
│   └── add_applicant_note.sql         # Add applicant note (person-level)
├── views/                             # Database view DDL (deploy to ATP)
│   ├── recruiting_report_v.sql        # Main report view (v2 — dev2 migration)
│   ├── ext_flex_recruiting_v.sql      # EFF: GCS Recruiting Details context
│   ├── ext_flex_retirement_v.sql      # EFF: GCS Retirement context
│   ├── fbx_qstnr_v.sql               # Questionnaire mashup view
│   └── fbx_qstnr_applicant_v.sql     # Applicant + questionnaire view
└── docs/                              # Supplementary documentation
    ├── regions.md                     # APEX regions
    ├── page-items.md                  # All P24_* items
    ├── dynamic-actions.md             # Button click handlers
    ├── dependencies.md                # External packages, tables, views
    └── computations.md                # Before-box-body computations
```

## External Dependencies

| Type | Name | Purpose |
|------|------|---------|
| **Package** | `pkg_rec_move` | REST POST to Fusion to move applicants |
| **Package** | `pkg_app_attachments` | REST GET from Fusion for attachments |
| **Package** | `pkg_ref_correction` | Token generation + email for ref corrections |
| **Package** | `pkg_app_security` | Role-based authorization checks |
| **Package** | `rec_rls_pkg` | VPD predicate for row-level security |
| **Function** | `fmt_phone` | Phone number formatting |
| **View** | `RECRUITING_REPORT_V` | Main report data source (VPD-secured) |
| **View** | `FBX_QSTNR_APPLICANT_V` | Applicant + questionnaire data |
| **Table** | `applicant_ranking` | Recruiter scores/recommendations |
| **Table** | `candidate_note` | Application-level notes |
| **Table** | `applicant_note` | Person-level notes |
| **Table** | `candidate_phones_r` | Candidate phone numbers (REST) |
| **Table** | `rec_routing_phase` | Recruiting phase lookup (20 phases) |
| **Table** | `rec_routing_state` | Recruiting state lookup (~59 states) |
| **Table** | `ref_correction_token` | Secure one-time correction tokens |
| **Table** | `ref_correction` | Submitted reference corrections |
| **Table** | `app_ticket` | Support ticket system |
| **Table** | `rec_dept_grant` | Department-level VPD overrides |
| **Table** | `app_user_roles` | User role assignments |
