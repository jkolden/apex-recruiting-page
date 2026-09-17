# report-view

## What it does

Provides the main Interactive Report data source for APEX page 24. `RECRUITING_REPORT_V` is a wide view that joins REST-synced recruiting tables (applications, requisitions, candidates) with EFF person flexfields, employee lookups, dimension tables, questionnaire-based teacher references, Gallup assessment scores, applicant rankings, reference corrections, survey responses, candidate notes, and phone counts. Each source table is deduped with `ROW_NUMBER` CTEs to guarantee one row per entity. The VPD policy `REC_DEPT_READ_POLICY` is applied to this view, so row-level security is enforced transparently. The CSS file defines all shared IR styling: column widths, phase/state pills, Gallup band colors, ranking colors, star ratings, sticky first two columns, reference column group tinting, and breadcrumb layout.

## Database objects

| Object | Type | Description |
|---|---|---|
| `RECRUITING_REPORT_V` | View | Main IR data source. Joins 18+ tables/CTEs. One row per job application. Ordered by job function then requisition number. Key output columns described below. |
| `EXT_FLEX_JOB_REFS_V` | View | Decodes the `GCS Job Application References` EFF context from `ext_flex_stg`. Maps `PEI_INFO1`-`PEI_INFO6` to three reference contacts (name + email each). |
| `REC_DEPT_READ_POLICY` | VPD Policy | Applied to the view (defined in `security/`). Filters rows by department based on the user's assignments and grants. |

### Source tables joined by RECRUITING_REPORT_V

| CTE / Alias | Source Table | Join Key | Data |
|---|---|---|---|
| `latest_app` | `JOB_APPLICANTS_R` | Driving table | Application ID, candidate name, phase, state, date |
| `latest_req` | `JOB_REQUISITIONS_R` | `REQUISITIONID` | Req title, category, posting status, recruiter/HM IDs |
| `latest_pos` | `HCM_POSITION_R` | `POSITIONID` | Position name |
| `latest_loc` | `LOCATIONS_R` | `PRIMARYWORKLOCATIONID` | School name, location code |
| `latest_dept` | `DEPARTMENTS_R` | `DEPARTMENTID` | Department name (drives VPD) |
| `latest_cand` | `RECRUITING_CANDIDATES_R` | `PERSONID` | Candidate email, candidate number |
| `emp` / `mgr` / `rec` | `FBX_HCM_EMPLOYEE` | `PERSON_ID` | Employee number, display names for HM/recruiter |
| `j` | `DIM_JOB_R` | `JOBID` | Job name |
| `latest_person_data` | `EXT_FLEX_PERSON_DATA_V` | `PERSON_ID` | Rehire, background check, certification, work keys, assessment |
| `latest_job_refs` | `EXT_FLEX_JOB_REFS_V` | `PERSON_ID` | EFF-based reference contacts (name + email x3) |
| `latest_retirement` | `EXT_FLEX_RETIREMENT_V` | `PERSON_ID` | Working retiree flag, retirement date |
| `dff` | `REQ_DFF_R` | `REQUISITION_ID` | Transfer coordinated, vacancy term submitted |
| `latest_pub` | `REQ_PUBLISHED_JOBS_R` | `REQUISITION_ID` | Newest published job posting details |
| `latest_gallup` | `BIP_GALLUP_ASSESSMENTS` | `PERSON_ID` | Gallup score, band, status, result URL |
| `teach_refs` | `FBX_QSTNR_V` | `SUBJECT_ID` (= application ID) | Questionnaire-based teacher reference contacts |
| `rc` | `REF_CORRECTION` | `JOB_APPLICATION_ID` | Admin-corrected reference names/emails/phones |
| `rnk` | `APPLICANT_RANKING` | `JOB_APPLICATION_ID` | Principal/manager ranking score and notes |
| `survey_status` | `CANDIDATE_REFERENCES` + `CANDIDATE_REFERENCE_ANSWERS` | `PERSON_ID` | Count of survey respondents, per-reference survey completion flags |
| `cn` / `an` | `CANDIDATE_NOTE` / `APPLICANT_NOTE` | Application/person ID | Note counts |
| `ph` | `CANDIDATE_PHONES_R` | `PERSON_ID` | Phone count |

### Reference column precedence

Reference name, phone, and email use `COALESCE(rc.<corrected>, tr.<questionnaire>)` so admin corrections from `ref_correction` take priority over the original questionnaire answers. Per-field change flags (`REF_1_NAME_CHG`, etc.) indicate which values were actually modified.

## Static files

| File | APEX reference | Description |
|---|---|---|
| `page24_base_css.css` | `#APP_FILES#page24_base_css#MIN#.css` | All shared IR styling for page 24. Includes: Oracle Sans font face, uniform column widths, phase/state pills (blue/yellow), Gallup band colors (green/amber/blue), ranking colors (green/blue/red), star rating icons, score badges, sticky first two columns, reference group column tinting (blue/green/orange), reference correction badge, survey received icon, breadcrumb styling, refresh button styling, dialog max-height. |

## How to deploy

1. **Create the EFF view** (if not already present):
   - Run `ext_flex_job_refs_v.sql`.
   - Prerequisite: `ext_flex_stg` table must exist with EFF data loaded.

2. **Create the report view**:
   - Run `recruiting_report_v.sql`.
   - All joined tables must exist first (see source table list above).

3. **Apply VPD policy** (if not already done):
   - Run `security/apply_rec_vpd_policy.sql` to attach `REC_DEPT_READ_POLICY` to the view.

4. **Upload the CSS file**:
   - APEX > Shared Components > Static Application Files > upload `page24_base_css.css`.
   - On page 24, add to CSS File URLs: `#APP_FILES#page24_base_css#MIN#.css`.

5. **Configure the IR region**:
   - Page 24 > IR region source: `SELECT * FROM RECRUITING_REPORT_V`.
   - Static ID: `applicant_irr` (referenced by other features for region refresh).

## How to modify

- **Add a new column**: Add it to the SELECT list in `recruiting_report_v.sql`, add a CTE or JOIN if the data comes from a new table, and re-run the CREATE OR REPLACE VIEW statement. If styling is needed, add CSS rules to `page24_base_css.css`.
- **Change reference priority**: The `COALESCE(rc.<field>, tr.<field>)` pattern determines which source wins. To add a third source, wrap it in another COALESCE level.
- **Add a new join**: Follow the `latest_*` CTE pattern -- use `ROW_NUMBER() OVER (PARTITION BY <pk> ORDER BY <timestamp> DESC)` to dedup, then LEFT JOIN with `AND rn = 1`.
- **Adjust column widths**: Edit the `min-width` / `max-width` values in `page24_base_css.css`. Column targeting uses `td[headers="COLUMN_ALIAS"]` selectors.
- **Change sticky columns**: The first two columns are pinned via `position: sticky` in the CSS. Adjust `left` offsets and `nth-child` selectors to pin different columns.
- **Change reference group colors**: The three reference groups are tinted via `td[headers*="REF_1"]`, `REF_2`, `REF_3` selectors. Change the `background-color` values in the CSS.
- **VPD filtering**: The view's `DEPARTMENT_NAME`, `RECRUITER_ID`, and `HIRING_MANAGER_ID` columns are referenced by the VPD predicate in `rec_rls_pkg`. If you rename or remove these columns, update the VPD policy function.
