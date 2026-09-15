-- =============================================================================
-- VIEW: FBX_QSTNR_APPLICANT_V
-- =============================================================================
-- One row per job application.  Starts from JOB_APPLICANTS_R so ALL
-- applicants appear, then LEFT JOINs questionnaire aggregates from
-- FBX_QSTNR_V.  Requisition context comes from JOB_REQUISITIONS_R,
-- enriched with position, job, and location lookups.
-- =============================================================================

CREATE OR REPLACE VIEW FBX_QSTNR_APPLICANT_V AS
SELECT
    app.JOBAPPLICATIONID                AS JOB_APPLICATION_ID,
    app.CANDIDATENAME                   AS CANDIDATE_NAME,
    COALESCE(rp.PHASE_NAME, app.PHASENAME)  AS APPLICATION_PHASE,
    app.PHASEID                         AS APPLICATION_PHASE_ID,
    COALESCE(rs.STATE_NAME, app.STATENAME)  AS APPLICATION_STATE,
    app.STATEID                         AS APPLICATION_STATE_ID,
    app.REQUISITIONID                   AS REQUISITION_ID,
    app.REQUISITIONNUMBER               AS REQUISITION_NUMBER,
    req.TITLE                           AS REQUISITION_TITLE,
    req.RECRUITINGTYPE                  AS RECRUITING_TYPE,
    req.JOBFUNCTION                     AS JOB_FUNCTION,
    pos.NAME                            AS POSITION_NAME,
    j.JOB_NAME,
    loc.LOCATION_NAME,

    -- Questionnaire aggregates (NULL when no questionnaires exist)
    qst.QUESTIONNAIRE_COUNT,
    qst.QUESTION_COUNT,
    qst.ANSWERED_COUNT,
    qst.PCT_ANSWERED,
    qst.TOTAL_SCORE,
    qst.LAST_RESPONSE_DATE,

    app.JOBAPPLICATIONDATE              AS APPLICATION_DATE

FROM JOB_APPLICANTS_R app

LEFT JOIN rec_routing_phase rp
    ON rp.PHASE_ID = app.PHASEID

LEFT JOIN rec_routing_state rs
    ON rs.STATE_ID = app.STATEID

LEFT JOIN JOB_REQUISITIONS_R req
    ON req.REQUISITIONID = app.REQUISITIONID

LEFT JOIN HCM_POSITION_R pos
    ON pos.POSITIONID = req.POSITIONID

LEFT JOIN DIM_JOB_R j
    ON j.JOB_ID = req.JOBID

LEFT JOIN DIM_LOCATION_R loc
    ON loc.LOCATION_ID = req.PRIMARYLOCATIONID

LEFT JOIN (
    SELECT
        q.JOB_APPLICATION_ID,
        COUNT(DISTINCT q.QUESTIONNAIRE_ID)      AS QUESTIONNAIRE_COUNT,
        COUNT(DISTINCT q.QSTNR_QUESTION_ID)     AS QUESTION_COUNT,
        COUNT(DISTINCT CASE
            WHEN q.ANSWER_MODE IN ('SELECT','FREE_TEXT','OTHER')
            THEN q.QSTNR_QUESTION_ID
        END)                                    AS ANSWERED_COUNT,
        ROUND(
            100 * COUNT(DISTINCT CASE
                WHEN q.ANSWER_MODE IN ('SELECT','FREE_TEXT','OTHER')
                THEN q.QSTNR_QUESTION_ID
            END)
            / NULLIF(COUNT(DISTINCT q.QSTNR_QUESTION_ID), 0)
        , 1)                                    AS PCT_ANSWERED,
        SUM(q.ANSWER_SCORE)                     AS TOTAL_SCORE,
        MAX(q.RESPONSE_SUBMITTED_DATE)          AS LAST_RESPONSE_DATE
    FROM FBX_QSTNR_V q
    WHERE q.JOB_APPLICATION_ID IS NOT NULL
    GROUP BY q.JOB_APPLICATION_ID
) qst
    ON qst.JOB_APPLICATION_ID = app.JOBAPPLICATIONID
;
