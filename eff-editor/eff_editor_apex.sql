-- =============================================================================
-- EFF Editor — APEX Setup Instructions (Page 24)
-- =============================================================================
-- Adds inline expand/collapse form to edit GCS Recruiting Details EFF fields
-- directly from the recruiting report IR. Same UX pattern as applicant_notes.
-- =============================================================================

-- =============================================================================
-- STEP 1: Upload CSS + JS to Shared Components > Static Application Files
-- =============================================================================
-- Upload: eff_editor_js.js, eff_editor_css.css
--
-- On Page 24, add file references:
--   CSS File URL:  #APP_FILES#eff_editor_css#MIN#.css
--   JS  File URL:  #APP_FILES#eff_editor_js#MIN#.js

-- =============================================================================
-- STEP 2: Add IR column for the toggle button
-- =============================================================================
-- In the IR on page 24, add a computed/virtual column:
--   Column Alias:  EFF_EDIT
--   Type:          HTML Expression
--
-- HTML Expression:
--
--   <button type="button" class="eff-toggle"
--           data-person-id="#CAND_NUM#"
--           aria-label="Edit EFF">
--     <span class="fa fa-pencil-square-o"></span>
--   </button>
--
-- Set Column Alignment = Center, Width = 48px, Heading = "Edit EFF"
-- (#CAND_NUM# = CANDIDATEPERSONID from recruiting_report_v)

-- =============================================================================
-- STEP 3: Ajax Callbacks
-- =============================================================================
-- Create two Ajax Callback processes on page 24:

-- ---- GET_EFF_RECRUITING ----
-- Name:     GET_EFF_RECRUITING
-- Type:     Ajax Callback
-- PL/SQL:

/*
DECLARE
    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
BEGIN
    apex_json.open_object;

    -- Read current values from ext_flex_recruiting_v (local cache)
    DECLARE
        l_found BOOLEAN := FALSE;
    BEGIN
        FOR r IN (
            SELECT *
              FROM ext_flex_recruiting_v
             WHERE person_id = l_person_id
             ORDER BY effective_start_date DESC
             FETCH FIRST 1 ROW ONLY
        ) LOOP
            l_found := TRUE;
            apex_json.write('status', 'OK');
            apex_json.open_object('values');
            -- Non-LOV fields (editable)
            apex_json.write('processingOwner',          r.processing_owner);
            apex_json.write('payGrade',                 r.pay_grade);
            apex_json.write('payStep',                  r.pay_step);
            apex_json.write('fte',                      r.fte);
            apex_json.write('additionalFte',            r.additional_fte);
            apex_json.write('proposedEffectiveDate',    r.proposed_effective_date);
            apex_json.write('teacherAssessmentScore',   r.teacher_assessment_score);
            apex_json.write('teacherYearsOfExperience', r.teacher_years_of_experience);
            apex_json.write('educatorId',               r.educator_id);
            apex_json.write('cateExperience',           r.cate_experience);
            apex_json.write('comments',                 r.comments);
            apex_json.write('additionalComments',       r.additional_comments);
            -- LOV fields (read-only display, future use)
            apex_json.write('interviewNotes',           r.interview_notes);
            apex_json.write('certification',            r.certification);
            apex_json.write('sled',                     r.sled);
            apex_json.write('referenceCheck',           r.reference_check);
            apex_json.write('workKeys',                 r.work_keys);
            apex_json.write('contractType',             r.contract_type);
            apex_json.write('contractStip1',            r.contract_stip_1);
            apex_json.write('contractStip2',            r.contract_stip_2);
            apex_json.write('contractStip3',            r.contract_stip_3);
            apex_json.write('rehireEligibility',        r.rehire_eligibility);
            apex_json.write('teacherSubjectArea',       r.teacher_subject_area);
            apex_json.close_object;
        END LOOP;

        IF NOT l_found THEN
            apex_json.write('status', 'OK');
            apex_json.open_object('values');
            apex_json.close_object;  -- empty values = new record
        END IF;
    END;

    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status',  'ERROR');
        apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
        apex_json.close_object;
END;
*/

-- ---- UPDATE_EFF_RECRUITING ----
-- Name:     UPDATE_EFF_RECRUITING
-- Type:     Ajax Callback
-- PL/SQL:

/*
DECLARE
    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
    l_payload   CLOB   := apex_application.g_x02;
BEGIN
    -- PATCH to Fusion + refresh local ext_flex_stg
    pkg_eff_update.update_eff_recruiting(l_person_id, l_payload);

    -- Return refreshed values so the form re-renders
    apex_json.open_object;
    apex_json.write('status', 'OK');

    DECLARE
        l_found BOOLEAN := FALSE;
    BEGIN
        FOR r IN (
            SELECT *
              FROM ext_flex_recruiting_v
             WHERE person_id = l_person_id
             ORDER BY effective_start_date DESC
             FETCH FIRST 1 ROW ONLY
        ) LOOP
            l_found := TRUE;
            apex_json.open_object('values');
            apex_json.write('processingOwner',          r.processing_owner);
            apex_json.write('payGrade',                 r.pay_grade);
            apex_json.write('payStep',                  r.pay_step);
            apex_json.write('fte',                      r.fte);
            apex_json.write('additionalFte',            r.additional_fte);
            apex_json.write('proposedEffectiveDate',    r.proposed_effective_date);
            apex_json.write('teacherAssessmentScore',   r.teacher_assessment_score);
            apex_json.write('teacherYearsOfExperience', r.teacher_years_of_experience);
            apex_json.write('educatorId',               r.educator_id);
            apex_json.write('cateExperience',           r.cate_experience);
            apex_json.write('comments',                 r.comments);
            apex_json.write('additionalComments',       r.additional_comments);
            apex_json.write('interviewNotes',           r.interview_notes);
            apex_json.write('certification',            r.certification);
            apex_json.write('sled',                     r.sled);
            apex_json.write('referenceCheck',           r.reference_check);
            apex_json.write('workKeys',                 r.work_keys);
            apex_json.write('contractType',             r.contract_type);
            apex_json.write('contractStip1',            r.contract_stip_1);
            apex_json.write('contractStip2',            r.contract_stip_2);
            apex_json.write('contractStip3',            r.contract_stip_3);
            apex_json.write('rehireEligibility',        r.rehire_eligibility);
            apex_json.write('teacherSubjectArea',       r.teacher_subject_area);
            apex_json.close_object;
        END LOOP;

        IF NOT l_found THEN
            apex_json.open_object('values');
            apex_json.close_object;
        END IF;
    END;

    apex_json.close_object;

EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status',  'ERROR');
        apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
        apex_json.close_object;
END;
*/

-- ---- REFRESH_EFF_ROW ----
-- Name:     REFRESH_EFF_ROW
-- Type:     Ajax Callback
-- PL/SQL:

/*
DECLARE
    l_person_id NUMBER := TO_NUMBER(apex_application.g_x01);
BEGIN
    pkg_eff_update.refresh_eff_row(l_person_id);

    -- Return refreshed values so JS can patch the row in-place
    apex_json.open_object;
    apex_json.write('status', 'OK');

    DECLARE
        l_found BOOLEAN := FALSE;
    BEGIN
        FOR r IN (
            SELECT *
              FROM ext_flex_recruiting_v
             WHERE person_id = l_person_id
             ORDER BY effective_start_date DESC
             FETCH FIRST 1 ROW ONLY
        ) LOOP
            l_found := TRUE;
            apex_json.open_object('values');
            apex_json.write('processingOwner',          r.processing_owner);
            apex_json.write('payGrade',                 r.pay_grade);
            apex_json.write('payStep',                  r.pay_step);
            apex_json.write('fte',                      r.fte);
            apex_json.write('additionalFte',            r.additional_fte);
            apex_json.write('proposedEffectiveDate',    r.proposed_effective_date);
            apex_json.write('teacherAssessmentScore',   r.teacher_assessment_score);
            apex_json.write('teacherYearsOfExperience', r.teacher_years_of_experience);
            apex_json.write('educatorId',               r.educator_id);
            apex_json.write('cateExperience',           r.cate_experience);
            apex_json.write('comments',                 r.comments);
            apex_json.write('additionalComments',       r.additional_comments);
            apex_json.write('interviewNotes',           r.interview_notes);
            apex_json.write('certification',            r.certification);
            apex_json.write('sled',                     r.sled);
            apex_json.write('referenceCheck',           r.reference_check);
            apex_json.write('workKeys',                 r.work_keys);
            apex_json.write('contractType',             r.contract_type);
            apex_json.write('contractStip1',            r.contract_stip_1);
            apex_json.write('contractStip2',            r.contract_stip_2);
            apex_json.write('contractStip3',            r.contract_stip_3);
            apex_json.write('rehireEligibility',        r.rehire_eligibility);
            apex_json.write('teacherSubjectArea',       r.teacher_subject_area);
            apex_json.close_object;
        END LOOP;

        IF NOT l_found THEN
            apex_json.open_object('values');
            apex_json.close_object;
        END IF;
    END;

    apex_json.close_object;

EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write('status',  'ERROR');
        apex_json.write('message', REGEXP_REPLACE(SQLERRM, '^ORA-[0-9]+: *'));
        apex_json.close_object;
END;
*/

-- =============================================================================
-- STEP 4: IR HTML Expression (pencil + refresh in one column)
-- =============================================================================
--
--   <button type="button" class="eff-toggle"
--           data-person-id="#CAND_NUM#"
--           aria-label="Edit EFF">
--     <span class="fa fa-pencil-square-o"></span>
--   </button>
--   <button type="button" class="eff-refresh"
--           data-person-id="#CAND_NUM#"
--           aria-label="Refresh EFF">
--     <span class="fa fa-refresh"></span>
--   </button>

-- =============================================================================
-- DONE
-- =============================================================================
-- Deployment checklist:
--   1. Compile pkg_eff_update spec + body (corrected context path)
--   2. Upload eff_editor_css.css and eff_editor_js.js to Static App Files
--   3. Add CSS/JS references to page 24
--   4. Add EFF_EDIT HTML Expression column to the IR (pencil + refresh)
--   5. Create 3 Ajax callbacks: GET_EFF_RECRUITING, UPDATE_EFF_RECRUITING,
--      REFRESH_EFF_ROW
--   6. Test: refresh icon spins -> GETs from Fusion -> IR refreshes
--      pencil icon -> drawer opens -> edit -> Save -> drawer + IR refresh
