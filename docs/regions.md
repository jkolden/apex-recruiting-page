# Page 24 — Regions

## 1. Search Results (applicant_irr)
- **Type**: Native SQL Report (Faceted Search)
- **Template**: Standard with no padding, hidden header
- **Options**: Stretch, static row colors, row highlight, inline, hide no-pagination
- **Source**: `SELECT ... FROM RECRUITING_REPORT_V` (VPD-secured)
- **Display Sequence**: 20
- **73 columns** including notes toggles, ranking display, Gallup scores, reference data, deep links, attachments, phase/state pills, job posting info

## 2. Search (Faceted Search Panel)
- **Type**: Native Faceted Search
- **Position**: REGION_POSITION_02 (left sidebar)
- **Filtered Region**: applicant_irr
- **Display Sequence**: 10
- **Settings**: Show charts, show total row count, compact numbers threshold 10000
- **9 facets**: Search, Published Posting Status, Requisition, Job, School, Department, Hiring Manager, Application Phase, Name

## 3. Button Bar
- **Type**: Static Content (HTML)
- **Template**: Button Region (no padding, no UI)
- **Display Sequence**: 10
- **Content**: `<div id="active_facets"></div>` (facet pill container)
- **Buttons**: RESET (undo icon), OPEN_TICKETS (dynamic label with count)

## 4. Move Applicant (move_form_region)
- **Type**: Static Content
- **Region Name**: `move_form_region`
- **Template**: Standard with scroll body
- **Display Sequence**: 30
- **Purpose**: Slide-out drawer for moving applicants between phases/states
- **Buttons**: MOVE_BTN (hot), CANCEL_BTN

## 5. Rank Applicant (ranking_form_region)
- **Type**: Static Content
- **Region Name**: `ranking_form_region`
- **Template**: Standard with scroll body
- **Display Sequence**: 40
- **Purpose**: Slide-out drawer for scoring and recommending applicants
- **Buttons**: SAVE_RANKING_BTN (hot), CANCEL_RANKING_BTN

## 6. Send Correction Link (reflink_form_region)
- **Type**: Static Content
- **Region Name**: `reflink_form_region`
- **Template**: Standard with scroll body
- **Display Sequence**: 50
- **Purpose**: Slide-out drawer for generating and emailing reference correction links
- **Buttons**: COPY_REF_LINK_BTN, SEND_REF_EMAIL_BTN (hot), CANCEL_REFLINK_BTN
