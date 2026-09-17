-- =============================================================================
-- VIEW: NOTES_TIMELINE_V
-- =============================================================================
-- Unified view combining candidate_note (per application) and applicant_note
-- (per person) with recruiting context from REST tables.
-- Powers the Notes Hub APEX page (faceted search + candidate timeline).
-- =============================================================================

CREATE OR REPLACE VIEW NOTES_TIMELINE_V AS
WITH latest_app AS (
    SELECT a.JOBAPPLICATIONID,
           a.CANDIDATENAME,
           a.CANDIDATEPERSONID,
           a.REQUISITIONNUMBER,
           a.REQUISITIONID,
           a.PHASENAME,
           a.STATENAME,
           ROW_NUMBER() OVER (PARTITION BY a.JOBAPPLICATIONID
                              ORDER BY a."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
      FROM JOB_APPLICANTS_R a
),
latest_req AS (
    SELECT r.REQUISITIONID,
           r.REQUISITIONNUMBER,
           r.TITLE            AS REQUISITION_TITLE,
           r.RECRUITINGTYPE,
           ROW_NUMBER() OVER (PARTITION BY r.REQUISITIONID
                              ORDER BY r."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
      FROM JOB_REQUISITIONS_R r
),
latest_cand AS (
    SELECT c.PERSONID,
           c.CANDIDATENUMBER,
           c.EMAIL,
           ROW_NUMBER() OVER (PARTITION BY c.PERSONID
                              ORDER BY c."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
      FROM RECRUITING_CANDIDATES_R c
),
cand_name AS (
    -- CANDIDATENAME lives on JOB_APPLICANTS_R, not RECRUITING_CANDIDATES_R.
    -- Pick the most recent application's name per person.
    SELECT CANDIDATEPERSONID AS PERSONID,
           CANDIDATENAME,
           ROW_NUMBER() OVER (PARTITION BY CANDIDATEPERSONID
                              ORDER BY "APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
      FROM JOB_APPLICANTS_R
)
-- Application-level notes
SELECT
    cn.note_id,
    'APPLICATION'                          AS NOTE_TYPE,
    cn.note_text,
    LOWER(cn.created_by)                   AS CREATED_BY,
    cn.created_on,
    cn.job_application_id,
    app.CANDIDATEPERSONID                  AS PERSON_ID,
    app.CANDIDATENAME || CASE WHEN cand.CANDIDATENUMBER IS NOT NULL
        THEN ' (#' || cand.CANDIDATENUMBER || ')' END AS CANDIDATE_NAME,
    cand.CANDIDATENUMBER                   AS CANDIDATE_NUMBER,
    LOWER(TRIM(cand.EMAIL))                AS CANDIDATE_EMAIL,
    app.REQUISITIONNUMBER                  AS REQ_NUMBER,
    req.REQUISITION_TITLE,
    app.PHASENAME                          AS APPLICATION_PHASE,
    app.STATENAME                          AS APPLICATION_STATE
FROM candidate_note cn
LEFT JOIN latest_app app
    ON app.JOBAPPLICATIONID = cn.job_application_id AND app.rn = 1
LEFT JOIN latest_cand cand
    ON cand.PERSONID = app.CANDIDATEPERSONID AND cand.rn = 1
LEFT JOIN latest_req req
    ON req.REQUISITIONID = app.REQUISITIONID AND req.rn = 1

UNION ALL

-- Person-level notes
SELECT
    an.note_id,
    'PERSON'                               AS NOTE_TYPE,
    an.note_text,
    LOWER(an.created_by)                   AS CREATED_BY,
    an.created_on,
    NULL                                   AS job_application_id,
    an.person_id,
    cn.CANDIDATENAME || CASE WHEN cand.CANDIDATENUMBER IS NOT NULL
        THEN ' (#' || cand.CANDIDATENUMBER || ')' END AS CANDIDATE_NAME,
    cand.CANDIDATENUMBER                   AS CANDIDATE_NUMBER,
    LOWER(TRIM(cand.EMAIL))                AS CANDIDATE_EMAIL,
    NULL                                   AS REQ_NUMBER,
    NULL                                   AS REQUISITION_TITLE,
    NULL                                   AS APPLICATION_PHASE,
    NULL                                   AS APPLICATION_STATE
FROM applicant_note an
LEFT JOIN latest_cand cand
    ON cand.PERSONID = an.person_id AND cand.rn = 1
LEFT JOIN cand_name cn
    ON cn.PERSONID = an.person_id AND cn.rn = 1
/

COMMENT ON TABLE NOTES_TIMELINE_V IS
    'Unified view of candidate_note + applicant_note with recruiting context for Notes Hub';
