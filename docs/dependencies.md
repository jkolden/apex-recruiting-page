# Page 24 — External Dependencies

## PL/SQL Packages

| Package | Procedures Used | Purpose |
|---------|----------------|---------|
| `pkg_rec_move` | `move_application()` | REST POST to Fusion to move applicants between phases/states |
| `pkg_app_attachments` | `list_attachments()` | REST GET from Fusion for job application attachments |
| `pkg_ref_correction` | `generate_token()`, `send_correction_email()` | Secure token URLs for reference correction |
| `pkg_app_security` | `is_admin()`, `is_recruiting_mgr()` | Page authorization checks |
| `rec_rls_pkg` | VPD policy function | Row-level security predicate on RECRUITING_REPORT_V |

## Database Functions

| Function | Purpose |
|----------|---------|
| `fmt_phone()` | Formats raw phone digits into readable format |

## Views

| View | Purpose |
|------|---------|
| `RECRUITING_REPORT_V` | Main data source for the IR (VPD-secured) |
| `FBX_QSTNR_APPLICANT_V` | Applicant + questionnaire data for move drawer |

## Tables

| Table | Purpose | Used By |
|-------|---------|---------|
| `applicant_ranking` | Recruiter scores/recommendations | SAVE_RANKING, GET_RANKING_DETAILS |
| `candidate_note` | Application-level notes | GET_NOTES, ADD_NOTE |
| `applicant_note` | Person-level notes | GET_APPLICANT_NOTES, ADD_APPLICANT_NOTE |
| `candidate_phones_r` | Candidate phone numbers (REST-loaded) | GET_PHONES |
| `rec_routing_phase` | Recruiting phase lookup (20 phases) | GET_APP_DETAILS, P24_PHASE_ID LOV |
| `rec_routing_state` | Recruiting state lookup (~59 states) | P24_STATE_ID LOV |
| `irc_routing_steps_stg` | Phase-to-state mapping | P24_STATE_ID cascading LOV |
| `ref_correction_token` | Secure one-time tokens | GENERATE_REF_LINK |
| `ref_correction` | Submitted corrections | Referenced by RECRUITING_REPORT_V |
| `JOB_APPLICANTS_R` | Job applicant records (REST) | GENERATE_REF_LINK, SEND_REF_LINK_EMAIL |
| `RECRUITING_CANDIDATES_R` | Candidate records (REST) | GENERATE_REF_LINK (email lookup) |
| `app_ticket` | Support tickets | P24_TICKET_COUNT computation |
| `rec_dept_grant` | Department VPD overrides | rec_rls_pkg predicate |
| `app_user_roles` | User role assignments | pkg_app_security checks |

## External JS/CSS Files (APEX Static Files)

| File | Purpose |
|------|---------|
| `candidate_notes_js.js` | Inline notes panel for job applications |
| `candidate_notes_css.css` | Styling for candidate notes panel |
| `candidate_phones_js.js` | Inline phone numbers panel |
| `candidate_phones_css.css` | Styling for phone panel |
| `applicant_notes_js.js` | Inline notes panel for persons (cross-application) |
| `applicant_notes_css.css` | Styling for applicant notes panel |

## Configuration

| Config Key | Purpose |
|-----------|---------|
| `APEX_BASE_URL` | Base URL for generating correction links (email_config table) |
