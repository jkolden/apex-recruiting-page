# Reference Correction

## What it does

Generates one-time secure URLs that allow job applicants to correct their reference contact information (name, phone, email for up to 3 references). From a right-side drawer on page 24, an admin generates a token-based link and can either copy it to the clipboard or email it directly to the candidate. The applicant clicks the link, which opens public pages 100/101 (no Fusion login required), reviews their current references from questionnaire data, and submits corrections. Corrections are stored in a local overlay table (`ref_correction`), preserving a snapshot of the original values for audit. Tokens expire after 72 hours and are single-use.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Package spec | `pkg_ref_correction` | Declares token, validation, correction, and email procedures |
| Package body | `pkg_ref_correction` | Token generation (dual SYS_GUID), validation, MERGE corrections, email via `pkg_email` |
| Table | `ref_correction_token` | One-time tokens: PK `token_id` (identity), UK on `token` (64 hex chars), 72-hour expiry, `used_yn` flag |
| Table | `ref_correction` | Correction overlay: PK on `job_application_id`. Corrected + original ref values for 3 references |
| Config row | `email_config.APEX_BASE_URL` | Base URL for building the correction link (update per environment) |

## Static files

| File | APEX reference |
|------|---------------|
| `ref_correction_link_js.js` | `#APP_FILES#ref_correction_link_js#MIN#.js` |
| `ref_correction_link_css.css` | `#APP_FILES#ref_correction_link_css#MIN#.css` |

## Ajax callbacks

| Name | What it does | Returns |
|------|-------------|---------|
| `GENERATE_REF_LINK` | Reads `x01` (job_application_id), calls `pkg_ref_correction.generate_token` + `get_candidate_email` | `{status:"OK", url:"...", candidate_name:"...", candidate_email:"..."}` or `{status:"ERROR", message:"..."}` |
| `SEND_REF_LINK_EMAIL` | Reads `x01`-`x04`, calls `pkg_ref_correction.send_correction_email` | `{status:"OK"}` or `{status:"ERROR", message:"..."}` |

## Page items

| Item | Type | Purpose |
|------|------|---------|
| `P24_REFLINK_APP_ID` | Hidden | Job application ID |
| `P24_REFLINK_CANDIDATE` | Display Only | Candidate name |
| `P24_REFLINK_URL` | Display Only | Generated correction URL (monospace, copy-friendly) |
| `P24_REFLINK_EMAIL` | Text Field | Pre-filled with internal candidate email (editable) |
| `P24_REFLINK_NOTE` | Textarea | Optional personal note included in the email |

Region static ID: `reflink_form_region`

Buttons: `COPY_REF_LINK_BTN` (calls `copyRefLink()`), `SEND_REF_EMAIL_BTN` (calls `sendRefLinkEmail()`)

## Related pages

| Page | Purpose |
|------|---------|
| 100 | Public token validation page -- validates token, redirects to 101 or shows expiry message |
| 101 | Public correction form -- pre-fills current ref data, submits to `pkg_ref_correction.save_corrections` |

## How to deploy

1. Run `ref_correction_token.sql` to create the token table.
2. Run `ref_correction.sql` to create the correction overlay table.
3. Run `email_config_ref_correction.sql` to insert the `APEX_BASE_URL` config row (update URL for your environment).
4. Run `pkg_ref_correction.sql` (spec), then `pkg_ref_correction.plb` (body).
5. Upload `ref_correction_link_js.js` and `ref_correction_link_css.css` as Static Application Files.
6. Add JS/CSS file references to page 24.
7. Create the page items, region (`reflink_form_region`), buttons, and Ajax callbacks listed above.
8. Create pages 100 and 101 for the public correction flow.
9. Ensure `pkg_email` is deployed and SMTP is configured.

## How to modify

- **Changing token expiry**: Edit the `INTERVAL '72' HOUR` in `generate_token`.
- **Adding a 4th reference**: Add `ref_4_*` and `orig_ref_4_*` columns to `ref_correction`, update `save_corrections` to accept and store `p_ref_4_*` parameters, and update pages 100/101.
- **Changing the email template**: Edit the HTML in `send_correction_email`. The template uses inline styles for email client compatibility.
- **Environment migration**: Update the `APEX_BASE_URL` row in `email_config` and the `f?p=121:100` app/page reference in `generate_token` if the app ID or page number changes.
- **Overlaying corrections in the report view**: LEFT JOIN `ref_correction` to `RECRUITING_REPORT_V` and use `COALESCE(rc.ref_1_name, qstnr.ref_1_name)` for each reference field.
