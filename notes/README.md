# Notes

## What it does

Two-level notes system for the recruiting report (page 24). **Application notes** are keyed on `JOB_APPLICATION_ID` and stored in the `candidate_note` table -- they are specific to one job application. **Person notes** are keyed on `PERSON_ID` and stored in the `applicant_note` table -- they follow the candidate across all applications. Both use an inline expand/collapse panel injected below the IR row. `pkg_ui_interactions` dual-writes notes to Oracle Fusion via the `recruitingUIInteractions` REST API and syncs Fusion-native notes back into the local tables. The `notes_timeline_v` view unions both note types with recruiting context and powers the Notes Hub page (page 35).

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Table | `candidate_note` | Append-only application-level notes (PK: `note_id`, indexed on `job_application_id`) |
| Table | `applicant_note` | Append-only person-level notes (PK: `note_id`, indexed on `person_id`) |
| View | `notes_timeline_v` | Unions both note tables with JOB_APPLICANTS_R, RECRUITING_CANDIDATES_R, JOB_REQUISITIONS_R context |
| Package | `pkg_ui_interactions` | POST notes to Fusion, sync Fusion interactions into local tables (`sync_person`, `sync_all`) |
| Trigger | `candidate_note_bi` | Auto-stamps `created_by`/`created_on` for local inserts (skipped when `interaction_id` is set) |
| Trigger | `applicant_note_bi` | Same trigger pattern for `applicant_note` |

## Static files

| File | APEX reference | Description |
|------|---------------|-------------|
| `app_notes_js.js` | `#APP_FILES#app_notes_js#MIN#.js` | Inline panel toggle, fetch, render, add for application notes |
| `app_notes_css.css` | `#APP_FILES#app_notes_css#MIN#.css` | Styles for appnote- prefixed elements |
| `person_notes_js.js` | `#APP_FILES#person_notes_js#MIN#.js` | Inline panel toggle, fetch, render, add for person notes |
| `person_notes_css.css` | `#APP_FILES#person_notes_css#MIN#.css` | Styles for pnote- prefixed elements |

## Ajax callbacks

| Name | Sends | Returns | Purpose |
|------|-------|---------|---------|
| `GET_APP_NOTES` | `x01` = JOB_APPLICATION_ID | `{ notes: [{created_by, created_on, note_text}] }` | Fetch application notes for the inline panel |
| `ADD_APP_NOTE` | `x01` = JOB_APPLICATION_ID, `x02` = note text | `{ status, notes, note_count }` | Insert a note, POST to Fusion, return updated list |
| `GET_PERSON_NOTES` | `x01` = PERSON_ID | `{ notes: [{created_by, created_on, note_text}] }` | Fetch person notes for the inline panel |
| `ADD_PERSON_NOTE` | `x01` = PERSON_ID, `x02` = note text | `{ status, notes, note_count }` | Insert a note, POST to Fusion, return updated list |

## How to deploy

1. Run `candidate_note.sql` to create the table, indexes, and trigger.
2. Run `applicant_note.sql` to create the table, indexes, and trigger.
3. Compile `pkg_ui_interactions.sql` (spec), then `pkg_ui_interactions.plb` (body).
4. Run `notes_timeline_v.sql` to create the view.
5. Upload `app_notes_js.js`, `app_notes_css.css`, `person_notes_js.js`, `person_notes_css.css` to Shared Components > Static Application Files.
6. On page 24, add CSS/JS File URL references (see Static files table above).
7. Add two IR HTML Expression columns: one with class `appnote-toggle` using `data-app-id="#JOB_APPLICATION_ID#"`, one with class `pnote-toggle` using `data-person-id="#CAND_NUM#"`.
8. Create the four Ajax callbacks on page 24 (GET_APP_NOTES, ADD_APP_NOTE, GET_PERSON_NOTES, ADD_PERSON_NOTE).

## How to modify

- **CSS class prefixes** are intentionally different (`appnote-` vs `pnote-`) to prevent collisions. Maintain this separation when adding new UI elements.
- **Adding fields to notes** (e.g., note categories): add the column to both `candidate_note` and `applicant_note`, update the JS `render()` function, and update the Ajax callback PL/SQL.
- **Fusion sync credentials**: `pkg_ui_interactions` uses `gc_post_credential` (OAuth) for POSTing and `gc_sync_credential` for GETting. Update these constants if credentials change.
- **Sync scheduling**: `sync_all` is intended to run nightly via DBMS_SCHEDULER. The caller must provide an APEX session context.
- **notes_timeline_v** deduplicates REST tables using `ROW_NUMBER ... ORDER BY APEX$ROW_SYNC_TIMESTAMP DESC`. If REST table schemas change, update the CTEs.
