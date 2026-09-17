# Questionnaires

## What it does

Questionnaire data from BICC extracts flows through a three-tier pipeline (landing, staging, final) for three entities: answers, questions, and responses. Two mashup views join the pipeline tables with REST applicant/requisition data: `QSTNR_V` provides one row per participant per question per answer, and `FBX_QSTNR_APPLICANT_V` provides one row per applicant with questionnaire aggregates. Gallup assessment scores are loaded separately via BIP SOAP into `bip_gallup_assessments`. Display on page 24 is read-only -- there is no JS or CSS in this folder. Color-coded badges (answer mode, score bands) are rendered via CSS classes defined in `page24_base_css.css` in the `report-view/` folder.

## Database objects

### Views

| Name | Purpose |
|------|---------|
| `QSTNR_V` | Joins QSTNR_QUESTION_BC + QSTNR_RESPONSE_BC + QSTNR_ANSWER_BC + JOB_APPLICANTS_R + JOB_REQUISITIONS_R. One row per participant/question/answer. Computes ANSWER_TEXT (coalesces long/short/clob) and ANSWER_MODE (SELECT/FREE_TEXT/OTHER/NO_RESPONSE). |
| `FBX_QSTNR_APPLICANT_V` | One row per job application. LEFT JOINs questionnaire aggregates from QSTNR_V (question count, answered count, pct answered, total score, last response date). Includes position/job/location lookups. |

### Final tables (BICC pipeline output)

| Name | PK | Source PVO |
|------|-----|-----------|
| `FBX_QSTNR_ANSWER` | `QSTN_ANSWER_ID` | QuestionAnswerPVO |
| `FBX_QSTNR_QUESTION` | `(QSTNR_PARTICIPANT_ID, QSTNR_QUESTION_ID)` | ParticipantQuestionnaireQuestionPVO |
| `FBX_QSTNR_RESPONSE` | `QSTN_RESPONSE_ID` | QuestionnaireQuestionResponsePVO |

### BIP table

| Name | PK | Source |
|------|-----|-------|
| `bip_gallup_assessments` | `SUBMISSION_ID` | BIP report `Gallup_XML.xdo`, loaded by `pkg_bip_soap.load_gallup_assessments` |

### BICC pipeline files (bicc/ subfolder)

Each of the three entities has a full pipeline set:

| Entity | Landing | Staging | Final | Pkg Spec | Pkg Body |
|--------|---------|---------|-------|----------|----------|
| QSTNR_ANSWER | `landing_qstnr_answer.sql` | `stg_fbx_qstnr_answer.sql` | `fbx_qstnr_answer.sql` | `pkg_bicc_qstnr_answer.sql` | `pkg_bicc_qstnr_answer.plb` |
| QSTNR_QUESTION | `landing_qstnr_question.sql` | `stg_fbx_qstnr_question.sql` | `fbx_qstnr_question.sql` | `pkg_bicc_qstnr_question.sql` | `pkg_bicc_qstnr_question.plb` |
| QSTNR_RESPONSE | `landing_qstnr_response.sql` | `stg_fbx_qstnr_response.sql` | `fbx_qstnr_response.sql` | `pkg_bicc_qstnr_response.sql` | `pkg_bicc_qstnr_response.plb` |

`bicc_loader_map_qstnr.sql` contains the three INSERT statements to register these entities in `bicc_loader_map`.

## Static files

None. Questionnaire data is displayed in read-only IR columns. CSS badge classes for answer modes and score bands are defined in `report-view/page24_base_css.css`, not in this folder.

## Ajax callbacks

None. Questionnaire data is queried directly in the IR report SQL via the views.

## How to deploy

1. Run the BICC pipeline DDL in order for each entity (answer first, then question, then response):
   - `bicc/landing_qstnr_answer.sql` (Step 0 extract, Step 1 external table, Step 2 landing table)
   - `bicc/stg_fbx_qstnr_answer.sql` (staging table + index)
   - `bicc/fbx_qstnr_answer.sql` (final table + PK)
   - Repeat for `_question` and `_response`.
2. Compile package specs then bodies: `pkg_bicc_qstnr_answer.sql` / `.plb`, then question, then response.
3. Run `bicc/bicc_loader_map_qstnr.sql` to register the three load types (priority 80, 81, 82).
4. Update `pkg_bicc_common.plb` with the three new CASE branches (see comments in `bicc_loader_map_qstnr.sql`).
5. Run `fbx_qstnr_v.sql` to create the questionnaire detail view.
6. Run `fbx_qstnr_applicant_v.sql` to create the applicant-level aggregate view.
7. Run `bip_gallup_assessments.sql` to create the Gallup scores table.

## How to modify

- **Adding questionnaire columns**: Add to the final table DDL, then update the staging table and package body INSERT/MERGE. Update `QSTNR_V` if the column should be exposed to the report.
- **Changing answer logic**: The `ANSWER_TEXT` and `ANSWER_MODE` CASE expressions in `QSTNR_V` control how answers are displayed. Modify these to change priority order or add new answer modes.
- **Gallup scores**: Loaded by `pkg_bip_soap` (not in this folder). The `bip_gallup_assessments` table is joined in the page 24 report SQL. The BIP report path is `/Custom/SCI/BIP/Gallup_XML.xdo`.
- **BICC column order**: Landing table column order must match the BICC CSV header exactly. If the BICC schema changes, drop and recreate the external table and landing table.
- **Oracle misspelling**: The QSTNR_QUESTION CSV uses `QUESTIONNAIREPARTCIPANT` (missing "I") in column names. This is baked into the landing table DDL.
