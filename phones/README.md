# Phones

## What it does

Displays candidate phone numbers in a read-only inline panel below the IR row on the recruiting report (page 24). Data comes from the `candidate_phones_r` table, which is loaded as a child resource of `recruitingCandidates` by `pkg_rest_recruiting.load_candidates`. The `fmt_phone` function formats raw digit strings into `(XXX) XXX-XXXX` for display. The UI pattern mirrors the notes expand/collapse panels but is read-only -- there is no add form.

## Database objects

| Type | Name | Purpose |
|------|------|---------|
| Table | `candidate_phones_r` | Phone numbers per candidate (PK: `phone_id`, indexed on `person_id`). One row per phone type (MOBILE, HOME, WORK, etc.). |
| Function | `fmt_phone` | DETERMINISTIC function that strips non-digits, handles optional leading 1, formats 10-digit numbers as `(XXX) XXX-XXXX`. Returns raw input unchanged if not 10 digits. |

## Static files

| File | APEX reference | Description |
|------|---------------|-------------|
| `candidate_phones_js.js` | `#APP_FILES#candidate_phones_js#MIN#.js` | Inline panel toggle, fetch, render for phone numbers |
| `candidate_phones_css.css` | `#APP_FILES#candidate_phones_css#MIN#.css` | Styles for cphone- prefixed elements (green accent color) |

## Ajax callbacks

| Name | Sends | Returns | Purpose |
|------|-------|---------|---------|
| `GET_PHONES` | `x01` = PERSON_ID | `{ phones: [{phone_type, phone_number, primary_flag}] }` | Fetch formatted phone numbers for the inline panel |

## How to deploy

1. Run `candidate_phones_r.sql` to create the table and index.
2. Run `fmt_phone.sql` to create the formatting function.
3. Upload `candidate_phones_js.js` and `candidate_phones_css.css` to Shared Components > Static Application Files.
4. On page 24, add CSS/JS File URL references (see Static files table above).
5. Add an IR HTML Expression column with class `cphone-toggle` using `data-person-id="#CAND_NUM#"` and a phone icon (`fa-phone`). Include a `cphone-badge` span for the phone count.
6. Create the `GET_PHONES` Ajax callback on page 24. The callback should query `candidate_phones_r` by `person_id` and call `fmt_phone()` on the raw number.

## How to modify

- **Phone data is loaded externally** by `pkg_rest_recruiting.load_candidates` (in the `phones/` folder there is only the table DDL, not the loader). Changes to the data pipeline are in the `pkg_rest_recruiting` package.
- **Adding phone types**: No code changes needed -- `candidate_phones_r` stores whatever Fusion returns. The JS renders all rows.
- **Formatting non-US numbers**: Edit `fmt_phone.sql`. Currently only 10-digit US numbers are formatted; all others pass through unchanged.
- **CSS accent color**: Phones use `--ut-palette-success` (green) to distinguish from notes (blue). Update `.cphone-panel` border color and `.cphone-primary` badge color to change.
- **Badge count**: The badge is rendered server-side in the IR HTML Expression. The JS does not update the badge count dynamically (unlike notes).
