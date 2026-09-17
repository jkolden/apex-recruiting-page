# data-refresh

## What it does

Provides on-demand and scheduled REST data refresh for the three core recruiting tables: requisitions, candidates, and applications. A dropdown button on APEX page 24 lets users trigger an incremental sync or a full refresh. The JavaScript shows a confirmation dialog, displays a spinner during execution, and reports row counts on success or an error message on failure. The server-side package (`pkg_rest_recruiting`) calls Oracle Fusion REST APIs with `?expand` to load parent rows and child resources (DFFs, published jobs, phones) in a single API pass per entity. A daily scheduler job runs the same logic automatically at 14:00 UTC.

## Database objects

| Object | Type | Description |
|---|---|---|
| `PKG_REST_RECRUITING` | Package (spec + body) | Consolidated REST loaders. `load_requisitions` expands DFF and published jobs; `load_candidates` uses cursor-based pagination to bypass Fusion's 10K offset cap; `load_applications` does incremental loads with a 4-hour overlap window. `refresh_all` orchestrates all three. |
| `JOB_REQUISITIONS_R` | Table | Parent requisition data (loaded by `load_requisitions`). Pre-existing table -- not created by this folder. |
| `REQ_DFF_R` | Table | Requisition-level descriptive flexfields (transfer coordinated, vacancy term submitted). PK on `REQUISITION_ID`. |
| `REQ_PUBLISHED_JOBS_R` | Table | Published job postings (internal/external visibility, status, dates). Composite PK on `(REQUISITION_ID, PUBLISHED_VISIBILITY)`. |
| `RECRUITING_CANDIDATES_R` | Table | Parent candidate data (loaded by `load_candidates`). Pre-existing table -- not created by this folder. |
| `CANDIDATE_PHONES_R` | Table | Candidate phone numbers (loaded as child expand of candidates). Pre-existing -- not created by this folder. |
| `JOB_APPLICANTS_R` | Table | Job applications (loaded by `load_applications`). Pre-existing table -- not created by this folder. |
| `JOB_REST_RECRUITING_DAILY` | Scheduler job | Runs `refresh_all(p_full_refresh => true)` daily at 14:00 UTC. Creates an APEX session (app 141) before calling the package. |

## Static files

| File | APEX reference | Description |
|---|---|---|
| `refresh_recruiting_js.js` | `#APP_FILES#refresh_recruiting_js#MIN#.js` | Dropdown button handler. Calls Ajax callback `REFRESH_RECRUITING` with mode `INCREMENTAL` or `FULL`. Displays spinner, success message with row counts, or error. Refreshes the `applicant_irr` region on success. |

## How to deploy

1. **Create child tables** (if new environment):
   - Run `req_dff_r.sql` to create `REQ_DFF_R`.
   - Run `req_published_jobs_r.sql` to create `REQ_PUBLISHED_JOBS_R`.

2. **Compile the package**:
   - Run `pkg_rest_recruiting.sql` (spec), then `pkg_rest_recruiting.plb` (body).
   - Prerequisite: `pkg_bicc_common` must exist (provides `gc_fa_base_url`).
   - APEX Web Credential `gcs_reports` must be configured with Fusion service account credentials.

3. **Upload the JS file**:
   - APEX > Shared Components > Static Application Files > upload `refresh_recruiting_js.js`.
   - On page 24, add to JavaScript File URLs: `#APP_FILES#refresh_recruiting_js#MIN#.js`.

4. **Create the Ajax callback**:
   - Page 24 > Processing > Ajax Callback > name: `REFRESH_RECRUITING`.
   - Read `apex_application.g_x01` for mode (`INCREMENTAL` or `FULL`).
   - Call `pkg_rest_recruiting.refresh_all(p_full_refresh => ...)`.
   - Return JSON with `status`, `requisitions`, `candidates`, `applications` counts.

5. **Create the dropdown button**:
   - Two menu entries calling `refreshRecruiting('INCREMENTAL')` and `refreshRecruiting('FULL')`.

6. **Create the scheduler job** (once per environment):
   - Run `job_rest_recruiting_daily.sql`.
   - If the APEX app moves from 141, update `p_app_id` in the job action.

## How to modify

- **Add a new REST entity**: Add a new `load_<entity>` procedure to the package body, add a call in `refresh_all`, and update the JS success message to include the new count.
- **Change the schedule**: `DBMS_SCHEDULER.SET_ATTRIBUTE('JOB_REST_RECRUITING_DAILY', 'repeat_interval', '...')`.
- **Change overlap window**: The 4-hour overlap for candidates/applications and 2-day overlap for requisitions are hardcoded in the package body. Search for `interval` in `pkg_rest_recruiting.plb`.
- **Switch incremental/full defaults**: Each loader's `p_full_refresh` default is set in the spec. Currently requisitions default to full, candidates and applications default to incremental.
- **10K offset cap**: `load_candidates` uses cursor-based pagination (`orderBy=CandLastModifiedDate:asc` + date filter advancing). If Fusion lifts the cap, this can be simplified to standard offset pagination.
- **APEX credential**: The credential static ID `gcs_reports` is a package constant (`gc_fa_credential`). Change it in the spec if the credential name changes.
