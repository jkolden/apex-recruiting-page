# Greenville County Schools — Recruiting Management Report

APEX application for managing the GCS recruiting pipeline. Page 24 (Management Report) is the primary workspace — a Classic Report / Interactive Report backed by `RECRUITING_REPORT_V` that combines REST-synced Fusion recruiting data with EFF flexfields, questionnaires, Gallup assessments, reference corrections, rankings, notes, and survey responses.

## Architecture

```
Oracle Fusion Cloud HCM
  │
  ├── REST APIs (recruiting, HCM, dimension lookups)
  │     └── pkg_rest_recruiting    ──→  JOB_REQUISITIONS_R
  │                                     JOB_APPLICANTS_R
  │                                     RECRUITING_CANDIDATES_R
  │                                     CANDIDATE_PHONES_R
  │                                     REQ_DFF_R
  │                                     REQ_PUBLISHED_JOBS_R
  │
  ├── BICC Extracts (questionnaires)
  │     └── pkg_bicc_qstnr_*      ──→  QSTNR_ANSWER_BC
  │                                     QSTNR_QUESTION_BC
  │                                     QSTNR_RESPONSE_BC
  │
  ├── BIP SOAP Reports (Gallup, EFF)
  │     └── pkg_bip_soap           ──→  BIP_GALLUP_ASSESSMENTS
  │                                     EXT_FLEX_STG
  │
  └── REST PATCH/POST (EFF update, move applicant)
        └── pkg_eff_update / pkg_rec_move
                                         │
                                         ▼
                              RECRUITING_REPORT_V
                              (18+ table join, VPD-filtered)
                                         │
                                         ▼
                               APEX Page 24 — IR
                            (10 interactive features)
```

## Platform

| Component | Value |
|-----------|-------|
| APEX | 24.2 |
| Database | Oracle Autonomous Transaction Processing (ATP) |
| Schema | `WKSP_FREEDEMO` |
| App ID | 141 |
| Auth | Oracle Fusion Cloud (APEX Web Credential `gcs_reports`) |
| Fusion instance | `ibzsjb-test.fa.ocs.oraclecloud.com` |

## Feature Index

| Folder | Feature | Description |
|--------|---------|-------------|
| [move-applicant/](move-applicant/) | Move Applicant | Drawer to move applications between recruiting phases/states via Fusion REST |
| [ranking/](ranking/) | Principal Ranking | Drawer for hiring managers to rank applicants (1-5 score + recommendation) |
| [attachments/](attachments/) | Attachments | Modal to list/download Fusion file attachments for a job application |
| [ref-correction/](ref-correction/) | Reference Correction | One-time secure links for applicants to correct reference contact info |
| [notes/](notes/) | Notes | Two-level notes system — per application (candidate notes) and per person (applicant notes) |
| [phones/](phones/) | Candidate Phones | Inline panel showing candidate phone numbers from Fusion |
| [eff-editor/](eff-editor/) | EFF Editor | Drawer to view/edit GCS Recruiting Details extensible flexfields via REST PATCH |
| [questionnaires/](questionnaires/) | Questionnaires | BICC pipeline for Fusion recruiting questionnaire answers + Gallup scores |
| [data-refresh/](data-refresh/) | Data Refresh | On-demand and scheduled REST sync for requisitions, candidates, and applications |
| [security/](security/) | Security | APEX authorization schemes + VPD row-level security on the report view |
| [report-view/](report-view/) | Report View | The `RECRUITING_REPORT_V` SQL view + base IR styling CSS |

## Page Inventory

| Page | Name | Purpose |
|------|------|---------|
| 24 | Management Report | Primary IR — all features above render here |
| 30 | Attachment Download | Hidden page that streams binary file downloads |
| 35 | Notes Hub | Full notes timeline view (uses `notes_timeline_v`) |
| 56 | Reference Correction | Public correction form (no auth) |
| 100 | Token Validation | Public token check + redirect to page 101 |
| 101 | Correction Submit | Public form for reference corrections |
| 4004 | Admin: Dept Grants | Admin page for managing `rec_dept_grant` rows |
| 9003 | Operations | Manual triggers for REST sync, BICC extract, BIP reports, reconciliation |

## Static Files on Page 24

All JS and CSS are loaded as Static Application Files with `#APP_FILES#` references:

### JavaScript

| File | Feature |
|------|---------|
| `eff_editor_js#MIN#.js` | EFF Editor drawer |
| `move_applicant_js#MIN#.js` | Move Applicant drawer |
| `ranking_js#MIN#.js` | Principal Ranking drawer |
| `attachments_js#MIN#.js` | Attachments modal |
| `ref_correction_link_js#MIN#.js` | Reference Correction drawer |
| `app_notes_js#MIN#.js` | Application-level notes panel |
| `person_notes_js#MIN#.js` | Person-level notes panel |
| `candidate_phones_js#MIN#.js` | Candidate phones panel |
| `refresh_recruiting_js#MIN#.js` | Refresh data dropdown button |

### CSS

| File | Feature |
|------|---------|
| `page24_base_css#MIN#.css` | Shared IR styling (pills, badges, sticky columns, breadcrumb) |
| `eff_editor_css#MIN#.css` | EFF Editor drawer |
| `move_applicant_css#MIN#.css` | Move Applicant drawer |
| `ranking_css#MIN#.css` | Principal Ranking drawer |
| `attachments_css#MIN#.css` | Attachments modal |
| `ref_correction_link_css#MIN#.css` | Reference Correction drawer |
| `app_notes_css#MIN#.css` | Application-level notes panel |
| `person_notes_css#MIN#.css` | Person-level notes panel |
| `candidate_phones_css#MIN#.css` | Candidate phones panel |

## Shared Dependencies

These tables/packages are used by multiple features and are not owned by any single feature folder:

| Object | Used by |
|--------|---------|
| `JOB_APPLICANTS_R` | report-view, move-applicant, data-refresh, questionnaires |
| `JOB_REQUISITIONS_R` | report-view, data-refresh, questionnaires |
| `RECRUITING_CANDIDATES_R` | report-view, data-refresh |
| `FBX_HCM_EMPLOYEE` | report-view, security, ref-correction |
| `EXT_FLEX_STG` | eff-editor, report-view |
| `pkg_bicc_common` | data-refresh, questionnaires, security |
| `pkg_email` | ref-correction |
| `APEX Web Credential (gcs_reports)` | data-refresh, eff-editor, attachments, move-applicant, security |

## Scheduler Jobs

| Job | Schedule | Package | Purpose |
|-----|----------|---------|---------|
| `JOB_REST_RECRUITING_DAILY` | 14:00 UTC daily | `pkg_rest_recruiting.refresh_all` | Sync requisitions, candidates, applications |
| `JOB_REST_SYNC_DAILY` | 14:00 UTC daily | `pkg_rest_sync.sync_all` | Sync all other REST data sources (19 sources) |
| `JOB_BICC_DAILY` | (configured separately) | `pkg_bicc_common.run_bicc_daily_today` | BICC pipeline for questionnaires and other entities |
