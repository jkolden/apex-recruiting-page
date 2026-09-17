# Move Applicant

## What it does

Moves a job application between recruiting phases and states in Oracle Fusion Cloud via REST POST. A right-side drawer on page 24 shows the candidate's current phase/state, lets the user pick a new phase and state from LOV select lists populated by local lookup tables, and optionally add comments. On submit, the package calls the Fusion `/action/move` endpoint, then immediately GETs the updated application record and MERGEs it into `JOB_APPLICANTS_R` so the IR reflects the change without waiting for the next scheduled sync.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Package spec | `pkg_rec_move` | Declares `move_application` function |
| Package body | `pkg_rec_move` | POST to Fusion move endpoint, refresh local row via GET + MERGE |
| Table | `rec_routing_phase` | Lookup: recruiting phases (PK: `phase_id`). Seeded from BICC `RoutingStepPhasePVO` |
| Table | `rec_routing_state` | Lookup: recruiting states (PK: `state_id`). Seeded from BICC `RoutingStepStatePVO` |
| Table (external) | `job_applicants_r` | Target of refresh MERGE after a successful move |
| Table (external) | `bicc_load_log` | Audit log for move attempts and refresh warnings |

## Static files

| File | APEX reference |
|------|---------------|
| `move_applicant_js.js` | `#APP_FILES#move_applicant_js#MIN#.js` |
| `move_applicant_css.css` | `#APP_FILES#move_applicant_css#MIN#.css` |

## Ajax callbacks

| Name | What it does | Returns |
|------|-------------|---------|
| `GET_APP_DETAILS` | Reads `x01` (job_application_id), queries `JOB_APPLICANTS_R` + routing lookups | `{candidate_name, phase, state, phase_id}` |
| `MOVE_APPLICANT` | Reads `x01`-`x04`, calls `pkg_rec_move.move_application` | `{status:"OK"}` or `{status:"ERROR", message:"..."}` |

## Page items

| Item | Type | Purpose |
|------|------|---------|
| `P24_JOB_APPLICATION_ID` | Hidden | Application ID passed to move call |
| `P24_CANDIDATE_DISPLAY` | Display Only | Candidate name shown in drawer header |
| `P24_CURRENT_PHASE` | Display Only | Current phase (pill badge) |
| `P24_CURRENT_STATE` | Display Only | Current state (pill badge) |
| `P24_PHASE_ID` | Select List | Target phase (LOV from `rec_routing_phase` WHERE `phase_type = 'APPLICATION'`) |
| `P24_STATE_ID` | Select List | Target state (LOV from `rec_routing_state`, cascading from phase) |
| `P24_COMMENTS` | Textarea | Optional move comments sent to Fusion |

Region static ID: `move_form_region`

## How to deploy

1. Run `rec_routing_phase.sql` to create the phase lookup table.
2. Run `rec_routing_state.sql` to create the state lookup table.
3. Load seed data into both tables from a BICC `HcmRecProcessLifecycleAM` extract (see `reload_routing_lookups.sql`).
4. Run `pkg_rec_move.sql` (spec), then `pkg_rec_move.plb` (body).
5. Upload `move_applicant_js.js` and `move_applicant_css.css` as Static Application Files.
6. Add JS/CSS file references to page 24.
7. Create the page items, region (`move_form_region`), and Ajax callbacks listed above.
8. Verify APEX Application Settings contain `BICC_FUSION_USERNAME` and `BICC_FUSION_PASSWORD`.

## How to modify

- **Adding fields to the move payload**: Edit `move_application` in the package body; the JSON payload is built with `json_object`. Add the new parameter to the spec, Ajax callback, and JS `submitMove`.
- **Changing auth from Basic to Web Credential**: Replace `p_username`/`p_password` with `p_credential_static_id` in both `move_application` and `refresh_applicant`. Remove the `Content-Type` header clear workaround once credential propagation is confirmed working.
- **Re-seeding routing lookups after env migration**: IDs differ per environment. Run a fresh BICC extract of `RoutingStepPhasePVO` and `RoutingStepStatePVO`, truncate both tables, and re-insert.
- **Drawer styling**: All CSS is scoped to `#move_form_region` and `#drawer_backdrop`. Width is set in the panel rule (380px default).
