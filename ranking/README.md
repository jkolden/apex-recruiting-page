# Ranking

## What it does

Provides a right-side drawer on page 24 for scoring and recommending job applicants. Users select a 1-5 numeric score and/or a categorical recommendation (Highly Recommended / Recommended / Consider / Not Recommended) and optionally add a free-text note. Rankings are stored in a local `APPLICANT_RANKING` table with one row per job application. There is no write-back to Fusion -- this is purely local data. A before-insert-or-update trigger automatically stamps the APEX username and timestamp on every save.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Table | `applicant_ranking` | One ranking per application (PK: `job_application_id`). Columns: `ranking_score` (1-5), `ranking_text`, `ranking_note`, `ranked_by`, `ranked_on` |
| Trigger | `applicant_ranking_biu` | BEFORE INSERT OR UPDATE: sets `ranked_by` from APEX session and `ranked_on` from SYSTIMESTAMP |

## Static files

| File | APEX reference |
|------|---------------|
| `ranking_js.js` | `#APP_FILES#ranking_js#MIN#.js` |
| `ranking_css.css` | `#APP_FILES#ranking_css#MIN#.css` |

## Ajax callbacks

| Name | What it does | Returns |
|------|-------------|---------|
| `GET_RANKING_DETAILS` | Reads `x01` (job_application_id), queries `JOB_APPLICANTS_R` + `APPLICANT_RANKING` | `{candidate_name, ranking_score, ranking_text, ranking_note, ranked_by}` |
| `SAVE_RANKING` | Reads `x01`-`x04`, MERGEs into `APPLICANT_RANKING` | `{status:"OK"}` or `{status:"ERROR", message:"..."}` |

## Page items

| Item | Type | Purpose |
|------|------|---------|
| `P24_RANK_APP_ID` | Hidden | Job application ID |
| `P24_RANK_CANDIDATE` | Display Only | Candidate name |
| `P24_RANK_SCORE` | Select List | 1-5 numeric score |
| `P24_RANK_TEXT` | Select List | Categorical recommendation (4 values) |
| `P24_RANK_NOTE` | Textarea | Optional free-text justification |
| `P24_RANK_LAST_BY` | Display Only | Shows who last ranked (or "Not yet ranked") |

Region static ID: `ranking_form_region`

## How to deploy

1. Run `applicant_ranking.sql` to create the table, check constraints, and trigger.
2. Upload `ranking_js.js` and `ranking_css.css` as Static Application Files.
3. Add JS/CSS file references to page 24.
4. Create the page items, region (`ranking_form_region`), and Ajax callbacks listed above.
5. Add a ranking column or link in the main IR that calls `openRankingForm(JOB_APPLICATION_ID)`.

## How to modify

- **Adding a new recommendation value**: Add to the `applicant_ranking_text_ck` CHECK constraint (requires `ALTER TABLE ... DROP CONSTRAINT` / `ADD CONSTRAINT`). Update the `P24_RANK_TEXT` LOV.
- **Expanding the score range**: Change the `applicant_ranking_score_ck` CHECK constraint and update the `P24_RANK_SCORE` LOV.
- **Showing rankings in the IR**: LEFT JOIN `applicant_ranking` to `RECRUITING_REPORT_V` (or add it directly to the view) on `job_application_id`.
- **Drawer width**: Set in CSS on `#ranking_form_region` (520px default, wider than the move drawer to accommodate recommendation text).
