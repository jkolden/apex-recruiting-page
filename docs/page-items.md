# Page 24 — Page Items

## Faceted Search Items
| Item | Prompt | Source Column | Type | LOV |
|------|--------|--------------|------|-----|
| P24_SEARCH | Search | 35+ columns | Native Search | Row search |
| P24_PUBLISHED_POSTING_STATUS | Published Posting Status | PUBLISHED_POSTING_STATUS | Checkbox | Distinct values |
| P24_REQUISITION | Requisition | JOB_REQUISITION_ID | Checkbox | Custom: REQ + Job + School + HM + State |
| P24_JOB | Job | JOB | Checkbox | Distinct values |
| P24_SCHOOL | School | SCHOOL | Checkbox | Distinct values |
| P24_DEPARTMENT_NAME | Department Name | DEPARTMENT_NAME | Checkbox | Distinct values |
| P24_HIRING_MANAGER | Hiring Manager | HIRING_MANAGER | Checkbox | Distinct values |
| P24_APPLICATION_PHASE | Application Phase | APPLICATION_PHASE | Checkbox | Distinct values |
| P24_NAME | Name | NAME | Checkbox | Distinct values |

All facets: show label, show counts, hide zero counts, show more count 7, show chart enabled.

## Move Applicant Drawer Items
| Item | Type | Purpose |
|------|------|---------|
| P24_JOB_APPLICATION_ID | Hidden | Application ID being moved |
| P24_CANDIDATE_DISPLAY | Display Only | Candidate name (hero treatment) |
| P24_CURRENT_PHASE | Display Only | Current phase (pill badge) |
| P24_CURRENT_STATE | Display Only | Current state (pill badge) |
| P24_PHASE_ID | Select List | New phase (LOV from fbx_qstnr_applicant_v) |
| P24_STATE_ID | Select List | New state (cascading, filtered by phase_id) |
| P24_COMMENTS | Textarea | Optional comments for the move |

P24_STATE_ID cascades on P24_CURRENT_PHASE and P24_PHASE_ID. LOV joins `irc_routing_steps_stg` to `rec_routing_state`.

## Ranking Drawer Items
| Item | Type | Purpose |
|------|------|---------|
| P24_RANK_APP_ID | Hidden | Application ID being ranked |
| P24_RANK_CANDIDATE | Display Only | Candidate name |
| P24_RANK_SCORE | Select List | Score 1-5 (static LOV) |
| P24_RANK_TEXT | Select List | Recommendation (Highly Recommended / Recommended / Consider / Not Recommended) |
| P24_RANK_NOTE | Textarea | Free-text notes |
| P24_RANK_LAST_BY | Display Only | Who last ranked this applicant |

## Reference Correction Link Drawer Items
| Item | Type | Purpose |
|------|------|---------|
| P24_REFLINK_APP_ID | Hidden | Application ID |
| P24_REFLINK_CANDIDATE | Display Only | Candidate name |
| P24_REFLINK_URL | Display Only | Generated correction URL (monospace styling) |
| P24_REFLINK_EMAIL | Text Field | Recipient email (auto-populated for internal candidates) |

## Other Items
| Item | Type | Purpose |
|------|------|---------|
| P24_TICKET_COUNT | Hidden | Count of open tickets for current user (computed) |
