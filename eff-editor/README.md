# EFF Editor

## What it does

Right-side drawer panel for editing "GCS Recruiting Details" extensible flexfield (EFF) values on the recruiting report (page 24). When a user clicks the pencil icon, the drawer opens with the current field values loaded from `ext_flex_recruiting_v`. Saving sends a REST PATCH (or POST for new records) to Oracle Fusion's `personExtraInformation` API, then refreshes the local `ext_flex_stg` row. The JS includes in-place DOM patching (`updateRowCells`) so the IR cells update immediately without a full report refresh. Two additional EFF views (`ext_flex_retirement_v`, `ext_flex_person_data_v`) decode other EFF contexts from the same `ext_flex_stg` table.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Package | `pkg_eff_update` | `update_eff_recruiting`: GET self href, then PATCH (or POST if no record exists) to Fusion. `refresh_eff_row`: GET from Fusion REST and MERGE into `ext_flex_stg`. |
| View | `ext_flex_recruiting_v` | Decodes `ext_flex_stg` PEI columns into friendly names for the "GCS Recruiting Details" context (16 char, 1 date, 6 number fields) |
| View | `ext_flex_retirement_v` | Decodes `ext_flex_stg` for the "GCS Retirement" context (2 char, 3 date fields) |
| View | `ext_flex_person_data_v` | Decodes `ext_flex_stg` for the "Additional GCS Person Data" context (10 char, 6 number fields). Returns latest effective row per person. |

## Static files

| File | APEX reference | Description |
|------|---------------|-------------|
| `eff_editor_js.js` | `#APP_FILES#eff_editor_js#MIN#.js` | Drawer lifecycle, form rendering, save handler, in-place DOM patching |
| `eff_editor_css.css` | `#APP_FILES#eff_editor_css#MIN#.css` | Drawer, overlay, form layout, toggle/refresh button styles |

## Ajax callbacks

| Name | Sends | Returns | Purpose |
|------|-------|---------|---------|
| `GET_EFF_RECRUITING` | `x01` = PERSON_ID | `{ status, values: {field: value, ...} }` | Read current EFF values from `ext_flex_recruiting_v` |
| `UPDATE_EFF_RECRUITING` | `x01` = PERSON_ID, `x02` = JSON payload | `{ status, values: {field: value, ...} }` | PATCH to Fusion via `pkg_eff_update`, return refreshed values |
| `REFRESH_EFF_ROW` | `x01` = PERSON_ID | `{ status, values: {field: value, ...} }` | GET from Fusion, MERGE local, return refreshed values for DOM patching |

## How to deploy

1. Compile `pkg_eff_update.sql` (spec), then `pkg_eff_update.plb` (body). Requires `pkg_bicc_common` for `gc_fa_base_url`.
2. Run `ext_flex_recruiting_v.sql`, `ext_flex_retirement_v.sql`, and `ext_flex_person_data_v.sql` to create the views.
3. Upload `eff_editor_js.js` and `eff_editor_css.css` to Shared Components > Static Application Files.
4. On page 24, add CSS/JS File URL references (see Static files table above).
5. Add an IR HTML Expression column with the toggle button (`class="eff-toggle"`, `data-person-id="#CAND_NUM#"`) and refresh button (`class="eff-refresh"`). See `eff_editor_apex.sql` Step 4 for the exact HTML.
6. Create the three Ajax callbacks (GET_EFF_RECRUITING, UPDATE_EFF_RECRUITING, REFRESH_EFF_ROW) using the PL/SQL in `eff_editor_apex.sql`.

## How to modify

Adding a new EFF field requires changes in **three places**:

1. **JS FIELDS array** (`eff_editor_js.js`): Add an entry with `id` (REST camelCase attribute name), `label`, and `type` (select/text/number). For dropdowns, provide an `options` array.
2. **All 3 APEX callbacks** (`eff_editor_apex.sql`): Add the `apex_json.write` call in GET_EFF_RECRUITING, UPDATE_EFF_RECRUITING, and REFRESH_EFF_ROW. The field must be read from `ext_flex_recruiting_v`.
3. **Report SQL**: If the field should appear as an IR column, add it to the report query. The `updateRowCells` function matches column headers by label text (case-insensitive).

Other notes:

- **Credential**: `pkg_eff_update` uses `gcs_reports` (APEX Web Credential). Update `gc_credential` if it changes.
- **PEI mapping**: The view maps generic `PEI_INFORMATION1..16`, `PEI_INFORMATION_DATE1`, and `PEI_INFORMATION_NUMBER1..6` to friendly column names. The mapping is documented in the package body header comments.
- **POST vs PATCH**: The package auto-detects whether a record exists. If `$.count = 0`, it POSTs to create; otherwise it PATCHes via the `self` href. The `Effective-Of` header is required for both.
- **Drawer is a singleton**: Only one drawer DOM element is created. It is reused across clicks and destroyed on IR refresh.
