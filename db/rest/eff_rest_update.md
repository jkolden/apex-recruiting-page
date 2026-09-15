# EFF REST Update — Extensible Flexfield Write-Back via REST API

## Status: POC Validated (2026-09-15)

PATCH confirmed working on dev2 for Nancy Nice (PersonId 300000041951212). Assessment score changed from 88 to 90 via REST.

## API Path (4 levels deep)

```
personExtraInformation/{PersonId}
  └── child/personEFF/{PersonId}
        └── child/PersonExtraInformationContextGCS__Recruiting__DetailsprivateVO/{hex_row_key}
```

Full GET URL:
```
/hcmRestApi/resources/11.13.18.05/personExtraInformation/{PersonId}/child/personEFF/{PersonId}/child/PersonExtraInformationContextGCS__Recruiting__DetailsprivateVO
```

## PATCH Requirements

- **Method**: PATCH on the row's `self` href (includes a long hex key identifying the date-effective row)
- **Content-Type**: `application/json`
- **Effective-Of** header (REQUIRED for date-effective resources):
  ```
  Effective-Of: RangeMode=UPDATE;RangeStartDate={EffectiveStartDate};RangeEndDate={EffectiveEndDate}
  ```
  Dates come from the GET response (e.g., `2026-08-27` and `4712-12-31`).
- **Credential**: `gcs_reports` (same as other REST calls)

## Attribute Mapping (REST camelCase names)

The REST API exposes friendly names, NOT PeiInformation* columns:

| REST Attribute | EFF Segment | Report Column | Type |
|---|---|---|---|
| `interviewNotes` | PEI_INFORMATION1 | Interview Notes | Y/N |
| `teacherAssessmentScore` | PEI_INFORMATION_NUMBER1 | Assessment Score | Number |
| `certification` | PEI_INFORMATION2 | Certification | Y/N |
| `sled` | PEI_INFORMATION3 | Background Check (SLED) | Y/N |
| `referenceCheck` | PEI_INFORMATION4 | Reference Check | Y/N |
| `workKeys` | PEI_INFORMATION5 | Work Keys | Y/N |
| `processingOwner` | PEI_INFORMATION6 | Processing Owner | Text |
| `proposedEffectiveDate` | PEI_INFORMATION_DATE1 | EFF Effective Date | Date |
| `additionalFte` | PEI_INFORMATION_NUMBER2 | Additional FTE | Number |
| `comments` | PEI_INFORMATION7 | Comments | Text |
| `payGrade` | PEI_INFORMATION8 | Pay Grade | Text |
| `payStep` | PEI_INFORMATION9 | Pay Step | Text |
| `additionalComments` | PEI_INFORMATION10 | Additional Comments | Text |
| `contractType` | PEI_INFORMATION11 | Contract Type | Text |
| `contractStip1` | PEI_INFORMATION12 | Contract Stip 1 | Text |
| `contractStip2` | PEI_INFORMATION13 | Contract Stip 2 | Text |
| `contractStip3` | PEI_INFORMATION14 | Contract Stip 3 | Text |
| `rehireEligibility` | PEI_INFORMATION15 | Rehire Eligible | Y/N |
| `teacherSubjectArea` | PEI_INFORMATION16 | Teacher Subject Area | Text |
| `teacherYearsOfExperience` | PEI_INFORMATION_NUMBER3 | Teacher Years of Exp | Number |
| `educatorId` | PEI_INFORMATION_NUMBER4 | Educator ID | Number |
| `cateExperience` | PEI_INFORMATION_NUMBER5 | CATE Experience | Number |
| `fte` | PEI_INFORMATION_NUMBER6 | FTE | Number |

## Example PATCH

```
PATCH /hcmRestApi/resources/11.13.18.05/personExtraInformation/300000041951212/child/personEFF/300000041951212/child/PersonExtraInformationContextGCS__Recruiting__DetailsprivateVO/{hex_row_key}

Headers:
  Content-Type: application/json
  Effective-Of: RangeMode=UPDATE;RangeStartDate=2026-08-27;RangeEndDate=4712-12-31

Body:
  {"teacherAssessmentScore": 90}
```

## Errors Encountered During POC

| Error | Cause | Fix |
|---|---|---|
| 400 FND-2835 "must define context as single row" | Used POST (create) instead of PATCH | Use PATCH — GCS Recruiting Details is single-row EFF |
| 400 "Effective-Of header is required" | Missing header on PATCH | Add `Effective-Of: RangeMode=UPDATE;RangeStartDate=...;RangeEndDate=...` |
| `workers` returns empty items | Integration user lacks core HR roles; external candidates have no worker record | Use `personExtraInformation` endpoint instead |

## Context Duplication Warning (2026-09-15)

**The recruiting report (`recruiting_report_v`) does NOT use `ext_flex_recruiting_v` (GCS Recruiting Details).**
It reads from `ext_flex_person_data_v` (**Additional GCS Person Data** — 13,717 rows on dev2).

There are four EFF contexts loaded by BIP into `ext_flex_stg`:

| Context | Rows (dev2) | Used By Report? | Status |
|---|---|---|---|
| Additional GCS Person Data | 13,717 | **YES** — `latest_person_data` CTE | Active |
| GCS Retirement | 13,720 | YES — `latest_retirement` CTE | Active |
| Secondary Status | 162 | No | Active |
| GCS Recruiting Details | 3 | **No** — only 3 test rows | Nearly empty |
| GCS Job Application References | 0 | Dead code — `latest_job_refs` returns nothing | **Removed on dev2** |

**Duplicate fields**: Many segments (certification, sled, reference_check, work_keys, etc.) exist in
both "Additional GCS Person Data" and "GCS Recruiting Details" but mapped to different PEI_INFORMATION
positions. Sara confirmed this overlap is known — the final EFF layout may consolidate them.

**pkg_eff_update targets "Additional GCS Person Data"** because that's what the report reads.
If the EFF contexts are reorganized before go-live, update:
1. `gc_context_path` constant in `pkg_eff_update.plb`
2. `json_table` column mapping in `refresh_eff_row`
3. `information_type` value in the MERGE INSERT

**REST attribute names for "Additional GCS Person Data" are UNVERIFIED.** The POC validated names
for "GCS Recruiting Details" only. Shared field labels (certification, sled, etc.) should produce the
same camelCase names, but fields unique to this context need a GET to confirm. Test URL:
```
GET /hcmRestApi/resources/11.13.18.05/personExtraInformation/{PersonId}/child/personEFF/{PersonId}/child/PersonExtraInformationContextAdditional__GCS__Person__DataprivateVO
```

## Known Issue: BIP Data Lag

EFF data in the recruiting report currently comes from BIP (via `pkg_bip_soap.load_extensible_flex` into `ext_flex_stg`). After a REST PATCH:

- **Fusion is updated immediately** (verified in Fusion UI)
- **Local `ext_flex_stg` is stale** until the next BIP load runs (`JOB_BIP_FLEX_DAILY`)

### Options to resolve:
1. **Refresh single row after PATCH** — GET the updated EFF data via REST and MERGE into `ext_flex_stg` (like `pkg_rec_move.refresh_applicant` does). Requires mapping REST camelCase names back to PEI_INFORMATION* columns.
2. **Read directly from REST for display** — Skip `ext_flex_stg` for the updated row and read from REST on demand. More complex, slower.
3. **Accept the lag** — If BIP runs frequently enough, the delay may be acceptable.

Option 1 is recommended — same pattern already proven with `pkg_rec_move`.

## Other EFF Contexts Available

The `personEFF` child also exposes these GCS contexts (same PATCH pattern would work):

| Child Resource | Maps to View | Status |
|---|---|---|
| `...Additional__GCS__Person__DataprivateVO` | `ext_flex_person_data_v` | **Active — pkg_eff_update targets this** |
| `...GCS__RetirementprivateVO` | `ext_flex_retirement_v` | Active |
| `...Secondary__StatusprivateVO` | `ext_flex_secondary_status_v` | Active |
| `...GCS__Recruiting__DetailsprivateVO` | `ext_flex_recruiting_v` | POC validated, only 3 rows on dev2 |

## Implementation Status

**pkg_eff_update** deployed (2026-09-15):
- `update_eff_recruiting(p_person_id, p_payload)` — PATCH + refresh
- `refresh_eff_row(p_person_id)` — GET + MERGE into ext_flex_stg
- Targets "Additional GCS Person Data" context (what the report reads)
- Ajax callback snippets in spec comments (UPDATE_EFF, REFRESH_EFF)

**TODO before go-live**:
1. Do a GET on the Additional GCS Person Data context to verify REST attribute names
2. Update json_table in `refresh_eff_row` if any names differ from best guesses
3. Revisit EFF context layout if Sara consolidates the duplicate fields
4. Build APEX drawer/modal for editing EFF fields inline
5. Add Ajax callbacks to recruiting report page
