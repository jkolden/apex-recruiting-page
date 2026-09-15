# Recruiting Application — Oracle APEX + Fusion Cloud HCM

Oracle APEX application for managing the Greenville County Schools recruiting pipeline. Authenticates via OAuth with Oracle Fusion Cloud HCM and provides role-based access to applicant data, ranking, phase/state management, reference correction workflows, and notes tracking.

| Property | Value |
|---|---|
| App ID | 121 (alias: `FA_INTEG_IBZSJB_TEST`) |
| APEX Version | 24.2 |
| Export Format | APEX LANG (26.1 modular export) |
| Database | Oracle Autonomous Transaction Processing (ATP) |
| Schema | WKSP_FREEDEMO |
| Auth | OAuth 2.0 (Fusion Cloud federation) |

## Repository Structure

```
├── app/                          # Full APEX LANG modular export
│   ├── application.apx           # Application definition
│   ├── pages/                    # Individual page exports (.apx)
│   ├── shared-components/        # Auth, authorization, lists, themes
│   ├── static-files/             # JS, CSS, fonts, icons
│   ├── supporting-objects/       # Install scripts (DB object DDL)
│   ├── workspace-components/     # Credentials
│   └── README.md                 # Detailed page-by-page documentation
├── db/                           # Database objects (outside APEX export)
│   ├── bicc/                     # BICC 3-tier pipeline (questionnaire entities)
│   ├── rest/                     # REST-based data loading (pkg_rest_recruiting)
│   ├── views/                    # Report and mashup view DDL
│   ├── tables/                   # Application table DDL
│   ├── functions/                # Standalone functions
│   └── security/                 # VPD policies, RLS packages, role management
│       ├── rls/                  # Row-level security (VPD predicates, grants)
│       └── roles/                # Fusion role sync utilities
```

## Pages

| Page | Name | Description |
|---|---|---|
| 24 | Management Report | Primary applicant IR with faceted search, move/rank/attachment drawers |
| 35 | Notes Hub | Timeline view of all applicant and person notes |
| 56 | Teacher Report | Filtered variant of page 24 for teacher positions |
| 100 | Reference Correction | Public-facing form for candidates to correct reference info |
| 101 | Reference Confirmation | Modal comparing original vs. edited reference values |
| 4004 | Reference Answers | Modal showing pivoted survey responses with star ratings |
| 9994 | My Departments | Drawer showing user's department assignments + overrides |
| 9995 | Override Grants (IR) | Admin IR for department-level access overrides |
| 9996 | Override Grants (Form) | Form drawer for creating/editing override grants |
| 9997 | Locations & Departments | User's Fusion assignment positions and locations |
| 9998 | My Roles | User's Fusion security roles (REST real-time + BIP fallback) |
| 9999 | Login | Login page |

See [`app/README.md`](app/README.md) for detailed page-level documentation including Ajax callbacks, drawers, modals, and data sources.

## Key Features

### Move Applicant Between Phases/States
Slide-out drawer that moves a job application through the recruiting workflow (Screen, Interview, Offer, etc.) by calling the Fusion REST API via `pkg_rec_move`. Phase/state LOVs sourced from `rec_routing_phase` / `rec_routing_state`.

### Applicant Ranking
Score applicants 1-5 with a recommendation level (Highly Recommended / Recommended / Consider / Not Recommended). Stored locally in `applicant_ranking`.

### Reference Correction Workflow
Generates a secure one-time URL and emails it to candidates so they can correct their reference contact information. Public-facing pages 100/101 require no authentication. Powered by `pkg_ref_correction`.

### Attachment Viewer
Modal that lists candidate attachments fetched from Fusion via REST with file type icons and download links.

### Notes (Two Levels)
- **Candidate Notes** -- tied to a specific job application
- **Applicant Notes** -- tied to a person across all applications

### Gallup Assessment Scores
Color-coded badges for Gallup assessment results: band (HP/MP/LP) and numeric score with gradient coloring.

### Questionnaire Data
Questionnaire scores from `FBX_QSTNR_APPLICANT_V` showing structured answers, free-text responses, and answer modes.

## Security Model

### Authentication
OAuth 2.0 with Oracle Fusion Cloud federation. Post-authentication calls `pkg_app_security.login_role_check` to populate APEX collections (`FUSION_USER_ROLES`, `FUSION_USER_ASSIGNMENTS`).

### Authorization
| Scheme | Controls |
|---|---|
| `IS_ADMIN` | Full access, VPD bypass |
| `IS_RECRUITING_MGR` | Page 24/56 access |
| `IS_HIRING_MANAGER` | Hiring manager features |

### Row-Level Security (VPD)
`REC_DEPT_READ_POLICY` on `RECRUITING_REPORT_V` with five OR'd access paths: recruiter on req, hiring manager on req, wide department grant, recruiter+department grant, hiring manager+department grant. Override table `rec_dept_grant` for admin-managed access.

See [`db/security/`](db/security/) for VPD policy, RLS package, and role management scripts.

## Database Dependencies

### Views ([`db/views/`](db/views/))

| View | Purpose |
|---|---|
| `RECRUITING_REPORT_V` | Main applicant report (joins applicants + requisitions + candidates + corrections) |
| `FBX_QSTNR_V` | Questionnaire answers for reference pre-population |
| `FBX_QSTNR_APPLICANT_V` | Questionnaire scores per applicant |
| `EXT_FLEX_RECRUITING_V` | Extensible flex fields (recruiting) |
| `EXT_FLEX_RETIREMENT_V` | Extensible flex fields (retirement) |

### BICC Questionnaire Pipeline ([`db/bicc/`](db/bicc/))

Questionnaire data flows through the standard BICC 3-tier pipeline: Landing (all VARCHAR2) → Staging (typed, with JOB_ID) → Final (published, PK enforced). Three entities feed the questionnaire views:

| Entity | Landing | Staging | Final | PK |
|---|---|---|---|---|
| Answer lookup | `LANDING_QSTNR_ANSWER` | `STG_FBX_QSTNR_ANSWER` | `FBX_QSTNR_ANSWER` | `QSTN_ANSWER_ID` |
| Questions | `LANDING_QSTNR_QUESTION` | `STG_FBX_QSTNR_QUESTION` | `FBX_QSTNR_QUESTION` | `(QSTNR_PARTICIPANT_ID, QSTNR_QUESTION_ID)` |
| Responses | `LANDING_QSTNR_RESPONSE` | `STG_FBX_QSTNR_RESPONSE` | `FBX_QSTNR_RESPONSE` | `QSTN_RESPONSE_ID` |

Each entity has a PL/SQL package (`pkg_bicc_qstnr_*`) implementing `load_and_preview()` + `merge()`. The packages use `pkg_bicc_common` utilities for ZIP extraction, safe type conversion, and dedup merge.

The view chain: `FBX_QSTNR_QUESTION` → `FBX_QSTNR_RESPONSE` → `FBX_QSTNR_ANSWER` → joined with REST applicant/requisition tables = `FBX_QSTNR_V` → aggregated per applicant = `FBX_QSTNR_APPLICANT_V`.

### REST Recruiting Pipeline ([`db/rest/`](db/rest/))

`pkg_rest_recruiting` loads three core tables from the Fusion Cloud REST API, replacing the original APEX declarative sync:

| Procedure | Target Table | API Endpoint | Notes |
|---|---|---|---|
| `load_requisitions` | `JOB_REQUISITIONS_R` | `recruitingJobRequisitions?expand=requisitionDFF,publishedJobs` | Also loads `REQ_DFF_R`, `REQ_PUBLISHED_JOBS_R` |
| `load_candidates` | `RECRUITING_CANDIDATES_R` | `recruitingCandidates?expand=candidatePhones` | Cursor-based pagination (10K offset cap workaround), also loads `CANDIDATE_PHONES_R` |
| `load_applications` | `JOB_APPLICANTS_R` | `recruitingJobApplications` | Incremental with 4-hour overlap |

`refresh_all` calls all three procedures and runs daily at 14:00 UTC via `JOB_REST_RECRUITING_DAILY`.

### Other PL/SQL Packages (not in this repo)

| Package | Purpose |
|---|---|
| `pkg_rec_move` | Move applicant between phases/states via REST POST |
| `pkg_ref_correction` | Token generation, validation, and save corrections |
| `pkg_app_security` | Role checks, login processing, APEX collection population |
| `pkg_app_attachments` | Fetch attachments from Fusion via REST |
| `rec_rls_pkg` | VPD predicate for row-level security |
| `pkg_bicc_common` | Shared BICC utilities (ZIP extraction, safe type conversion) |

## Importing the Application

The `app/` directory is a standard APEX LANG 26.1 modular export. To import:

1. In APEX SQL Workshop or via `apex export` CLI, use the modular import pointing at the `app/` directory
2. Run the supporting objects install script (`app/supporting-objects/install-scripts/db-objects.sql`) to create required database objects
3. Create the required Web Credentials for your Fusion instance (see `app/workspace-components/credentials/`)
4. Deploy the view and security DDL from `db/`

## License

This project is provided as a reference implementation for Oracle APEX + Fusion Cloud HCM integration patterns.
