# Recruiting Application (App 121)

Oracle APEX application for managing the Greenville County Schools recruiting pipeline. Authenticates via OAuth with Oracle Fusion Cloud and provides role-based access to applicant data, ranking, phase/state management, reference correction workflows, and notes tracking.

## Application Details

| Property | Value |
|---|---|
| App ID | 121 (alias: `FA_INTEG_IBZSJB_TEST`) |
| Name | Recruiting Application |
| Home Page | 24 (Management Report) |
| APEX Compatibility | 24.2 |
| Theme | Universal Theme |
| Auth | OAuth 2.0 (Fusion Cloud federation) |
| Post-auth | `pkg_app_security.login_role_check` |

## Pages

### Page 24 -- Management Report (Home)

The main applicant management page. Interactive report driven by `RECRUITING_REPORT_V` with three slide-out drawers and an attachment modal.

**Drawers:**
- **Move Applicant** -- Calls `GET_APP_DETAILS` to load current phase/state, submits to `MOVE_APPLICANT` (calls `pkg_rec_move` to POST to Fusion REST). Phase/state LOVs sourced from `rec_routing_phase` / `rec_routing_state`.
- **Rank Applicant** -- Calls `GET_RANKING_DETAILS`, submits score + recommendation + note to `SAVE_RANKING`.
- **Reference Correction Link** -- Calls `GENERATE_REF_LINK` (creates token in `ref_correction_token`), provides copy-to-clipboard and `SEND_REF_LINK_EMAIL` options.

**Attachment Modal** -- Calls `LIST_ATTACHMENTS` to fetch candidate attachments via Fusion REST, renders a file table with download links.

**Refresh** -- `REFRESH_RECRUITING` Ajax callback with Full/Incremental modes. Calls `pkg_rest_recruiting.refresh_all` (requisitions + candidates + applications).

**Questionnaire Data** -- Questionnaire scores rendered from `FBX_QSTNR_APPLICANT_V`. Gallup assessment scores displayed with color-coded bands (HP/MP/LP) and gradient scoring (green/amber/red).

**JS files:** `app_notes_js.js`, `person_notes_js.js`, `candidate_phones_js.js`
**CSS files:** `app_notes_css.css`, `person_notes_css.css`, `candidate_phones_css.css`

### Page 35 -- Notes Hub

Timeline view of all applicant and person notes from `NOTES_TIMELINE_V`. Displays note type, text, candidate info, requisition context, and application phase/state.

**JS files:** `notes_hub_js.js` (v1 + v2)
**CSS files:** `notes_hub_css.css` (v1 + v2)

### Page 56 -- Teacher Report

Filtered variant of the Management Report for teacher positions. Same drawer/modal/refresh patterns as page 24 (Move, Rank, Attachments, Ref Link) with `P56_` item prefix. Uses `RECRUITING_REPORT_V` and `FBX_QSTNR_APPLICANT_V`.

### Page 100 -- Reference Correction (Public)

Public-facing form where candidates correct their reference contact information. No authentication required.

**Flow:**
1. Token passed via URL, validated by `pkg_ref_correction.validate_token`
2. Pre-populates 3 references from `FBX_QSTNR_V` (question codes `GCS_REF_EXT_*` / `GCS_EXT_REF_*`)
3. Overlays any existing corrections from `ref_correction` table
4. Locks fields where the reference has already completed a survey (`CANDIDATE_REFERENCES` / `CANDIDATE_REFERENCE_ANSWERS`)
5. Submit branches to page 101 (confirmation modal)

**Client-side:** Phone formatting `(xxx) xxx-xxxx` and email normalization with validation highlighting.

### Page 101 -- Reference Change Confirmation (Public Modal)

Modal dialog comparing original vs. edited values. Changed fields highlighted with green left border and checkmark. Confirm button calls `pkg_ref_correction.save_corrections`, then redirects parent to page 100 which shows the "Thank You" region.

### Page 4004 -- Reference Answers (Modal)

Modal dialog displaying survey responses from `HRD2_SURVEY_PIVOT_V`. Shows up to 3 references as dynamic columns (header = ref name). Numeric ratings rendered as star ratings (1-5).

### Page 9994 -- My Departments (Drawer)

Drawer showing the current user's departments from two sources:
- **Assignment** -- `APEX_COLLECTIONS.FUSION_USER_ASSIGNMENTS` (populated at login)
- **Override** -- `rec_dept_grant` table (admin-configured)

Displays scope detail (All reqs, Recruiter-scoped, Hiring Mgr-scoped).

### Page 9995 -- Override Grants (IR)

Interactive report listing all department override grants from `rec_dept_grant`. Joins to `FBX_HCM_EMPLOYEE` for recruiter/hiring manager display names. Edit link opens page 9996.

### Page 9996 -- Override Grants (Form Drawer)

Form drawer for creating/editing `rec_dept_grant` records. Cascading LOVs:
- **Department** -- Active departments from `DEPARTMENTS_R` joined to `JOB_REQUISITIONS_R`
- **Recruiter** -- Recruiters with reqs in the selected department
- **Hiring Manager** -- Hiring managers with reqs in the selected department

App User LOV sourced from `FBX_HCM_EMPLOYEE`.

### Page 9997 -- Locations and Departments

IR displaying the logged-in user's assignment positions, locations, departments, and jobs from `APEX_COLLECTIONS.FUSION_USER_ASSIGNMENTS`.

### Page 9998 -- My Roles (Drawer)

Drawer showing the current user's Fusion security roles. Dual-source with priority:
1. **REST (Real-Time)** -- `APEX_COLLECTIONS.FUSION_USER_ROLES` (if populated at login)
2. **BIP (Daily Snapshot)** -- `fa_user_accounts` / `fa_user_roles` (fallback if REST failed)

## Security Model

### Authentication

Three OAuth schemes for different Fusion instances (dev2, dev4, test) plus a `SESSION_VERIFY_ONLY` fallback. Active scheme: `APEX_FA_IBZSJB-DEV2_OAUTH`. Post-authentication calls `pkg_app_security.login_role_check` which populates APEX collections (`FUSION_USER_ROLES`, `FUSION_USER_ASSIGNMENTS`).

### Authorization Schemes

| Scheme | Function | Scope |
|---|---|---|
| `IS_ADMIN` | `pkg_app_security.is_admin(:APP_USER)` | Per session |
| `IS_HIRING_MANAGER` | `pkg_app_security.is_hiring_manager` | Per session |
| `IS_RECRUITING_MGR` | `pkg_app_security.is_recruiting_mgr` | Per session |
| `Administration Rights` | `return true` (placeholder) | -- |

### Department-Level Access

`rec_dept_grant` table controls which departments a user can see. Grants can be scoped to a specific recruiter and/or hiring manager. The `G_DEPARTMENT_COUNT` app computation shows the badge count in the nav bar.

## Database Dependencies

### Tables (queried directly by pages)

| Table | Used By | Source |
|---|---|---|
| `JOB_APPLICANTS_R` | Pages 24, 35, 56, 100, 4004 | `pkg_rest_recruiting.load_applications` |
| `JOB_REQUISITIONS_R` | Pages 35, 9996 | `pkg_rest_recruiting.load_requisitions` |
| `RECRUITING_CANDIDATES_R` | Pages 24, 35, 56 | `pkg_rest_recruiting.load_candidates` |
| `DEPARTMENTS_R` | Page 9996 | `pkg_rest_sync.sync_all` |
| `FBX_HCM_EMPLOYEE` | Pages 9995, 9996 | BICC pipeline |
| `rec_dept_grant` | Pages 9994, 9995, 9996 | App-managed |
| `ref_correction` | Page 100 | App-managed |
| `ref_correction_token` | Page 100 | App-managed |
| `rec_routing_phase` | Page 24 | BICC (RoutingStepPhasePVO) |
| `rec_routing_state` | Page 24 | BICC (RoutingStepStatePVO) |
| `fa_user_accounts` / `fa_user_roles` | Page 9998 | BIP report |
| `CANDIDATE_REFERENCES` / `CANDIDATE_REFERENCE_ANSWERS` | Page 100 | App-managed |

### Views

| View | Used By | Purpose |
|---|---|---|
| `RECRUITING_REPORT_V` | Pages 24, 56 | Main applicant report (joins applicants + requisitions + candidates + corrections) |
| `FBX_QSTNR_V` | Pages 100, 101 | Questionnaire answers for reference pre-population |
| `FBX_QSTNR_APPLICANT_V` | Pages 24, 56 | Questionnaire scores per applicant |
| `NOTES_TIMELINE_V` | Page 35 | Unified notes timeline |
| `HRD2_SURVEY_PIVOT_V` | Page 4004 | Pivoted reference survey answers |

### PL/SQL Packages

| Package | Called From | Purpose |
|---|---|---|
| `pkg_app_security` | Auth + authorization schemes | Role checks, login processing |
| `pkg_rec_move` | Page 24 `MOVE_APPLICANT` | Move applicant between phases/states via REST |
| `pkg_ref_correction` | Pages 100, 101 | Token validation, save corrections |
| `pkg_rest_recruiting` | Page 24 `REFRESH_RECRUITING` | Load requisitions, candidates, applications from REST |
| `fmt_phone` | Pages 100, 101 | Phone number formatting function |

## Navigation

**Side Menu:**
- Applicant Reports > Notes Hub (page 35)
- Mashup Views > Extensible Flexfields / Financials / Human Resources (empty parent entries -- leftover from pipeline app)
- Administration > Override Grants (page 9995)

**Nav Bar:**
- Fusion Cloud Applications (external link to Fusion UI)
- User menu: Department Overrides (page 9994), Sign Out

## Static Files

**Page 24/56:** `app_notes_js.js`, `person_notes_js.js`, `candidate_phones_js.js` + matching CSS
**Page 35:** `notes_hub_js.js` (v1/v2) + matching CSS
**Fonts:** OracleBrandVF, OracleSans
**Theme:** `apex-modern-ui.css`
**Leftover (unused):** `bpm_task_detail_js.js`/`.css`, `applicant_notes_js.js`/`.css`, `candidate_notes_css.css`

## App Items

| Item | Purpose |
|---|---|
| `G_DEPARTMENT_COUNT` | Badge count in nav bar (computed from `rec_dept_grant`) |
| `G_ASSIGNMENT_COUNT` | Assignment count (set at login) |
| `G_LOCATION_COUNT` | Location count (set at login) |
| `G_ROLE_COUNT` | Role count (set at login) |

## Credentials

| Credential | Purpose |
|---|---|
| `APEX_FA_IBZSJB_DEV2_DBMS_CRED` | OAuth token exchange (dev2 -- active) |
| `APEX_FA_IBZSJB_DEV4_DBMS_CRED` | OAuth token exchange (dev4) |
| `APEX_FA_IBZSJB_TEST_DBMS_CRED` | OAuth token exchange (test) |

## Remaining Cleanup Candidates

These items appear to be leftovers from the pipeline app copy:

- **Navigation menu entries:** "Mashup Views" parent and its children (Extensible Flexfields, Financials, Human Resources) -- no pages linked
- **Lists:** `quick-actions` (ticket management actions like Assign to Me, Change Priority), `menu-popup` / `menu-popup-content-row` (task refresh/filter)
- **Static files:** `bpm_task_detail_js.js`/`.css`, `applicant_notes_js.js`/`.css`, `candidate_notes_css.css` -- not referenced by any page
- **App setting:** `BICC_FUSION_PASSWORD` / `BICC_FUSION_USERNAME` -- not used by this app (BICC loading runs from the pipeline app)
- **Supporting objects install script** -- references BICC pipeline tables/packages not relevant to this app
