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

| Child Resource | Maps to View |
|---|---|
| `...GCS__RetirementprivateVO` | `ext_flex_retirement_v` |
| `...Additional__GCS__Person__DataprivateVO` | `ext_flex_person_data_v` |
| `...Secondary__StatusprivateVO` | `ext_flex_secondary_status_v` |

## Implementation Plan (when ready)

1. Create `pkg_eff_update` (spec + body) with:
   - `get_eff_recruiting(p_person_id) RETURN CLOB` — GET current values as JSON
   - `update_eff_recruiting(p_person_id, p_payload CLOB)` — PATCH changed fields
   - `refresh_eff_row(p_person_id)` — GET + MERGE into `ext_flex_stg`
2. Add Ajax callback to recruiting report page (similar to MOVE_APPLICANT)
3. Build APEX drawer/modal for editing EFF fields inline
4. After successful PATCH, call `refresh_eff_row` so the report reflects changes immediately
