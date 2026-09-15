-- =============================================================================
-- MASHUP VIEW: QSTNR_V
-- =============================================================================
-- Replaces the BIP "Job Req Questionnaire" SQL report.
-- Joins 3 BICC questionnaire tables + 2 REST recruiting tables.
--
-- Sources:
--   QSTNR_QUESTION_BC  (questionnaire + section + question + participant)
--   QSTNR_RESPONSE_BC  (question-level answers + response header)
--   QSTNR_ANSWER_BC    (answer ID -> readable text lookup)
--   JOB_APPLICANTS_R (candidate name, job application context)
--   JOB_REQUISITIONS_R (requisition title, recruiting type)
--
-- Grain: one row per participant per question per answer.
-- For multi-select questions, multiple rows per question are expected.
-- =============================================================================

CREATE OR REPLACE VIEW QSTNR_V AS
SELECT
    -- Questionnaire definition
    q.QUESTIONNAIRE_NAME,
    q.QUESTIONNAIRE_CODE,
    q.QSTNR_VERSION_NUM,
    q.QUESTIONNAIRE_CREATION_DATE_TS    AS QUESTIONNAIRE_CREATED_DATE,

    -- Section
    q.SECTION_SEQ_NUM,
    q.SECTION_NAME,

    -- Question
    q.QUESTION_SEQ_NUM,
    q.QUESTION_CODE,
    q.QUESTION_TEXT,
    q.QUESTION_TYPE,
    q.CLASSIFICATION_CODE,
    q.MANDATORY_FLAG,

    -- Participant / Recruiting context
    q.QSTNR_PARTICIPANT_ID,
    q.SUBJECT_ID,
    app.CANDIDATENAME                   AS CANDIDATE_NAME,
    app.JOBAPPLICATIONID                AS JOB_APPLICATION_ID,
    app.JOBAPPLICATIONDATE              AS APPLICATION_DATE,
    app.PHASENAME                       AS APPLICATION_PHASE,
    app.STATENAME                       AS APPLICATION_STATE,
    req.REQUISITIONID                   AS REQUISITION_ID,
    req.REQUISITIONNUMBER               AS REQUISITION_NUMBER,
    req.TITLE                           AS REQUISITION_TITLE,
    req.RECRUITINGTYPE                  AS RECRUITING_TYPE,

    -- Response header
    r.QSTNR_RESPONSE_ID,
    r.ATTEMPT_NUM,
    r.RESPONSE_STATUS,
    r.SUBMITTED_DATE_TS                 AS RESPONSE_SUBMITTED_DATE,
    r.LAST_UPDATE_DATE_TS               AS RESPONSE_LAST_UPDATE_DATE,

    -- Answer
    r.QSTN_RESPONSE_ID,
    CASE
        WHEN ans.ANSWER_LONG_TEXT IS NOT NULL
            THEN ans.ANSWER_LONG_TEXT
        WHEN ans.ANSWER_SHORT_TEXT IS NOT NULL
            THEN ans.ANSWER_SHORT_TEXT
        WHEN r.ANSWER_CLOB IS NOT NULL
            THEN r.ANSWER_CLOB
        ELSE NULL
    END                                 AS ANSWER_TEXT,

    CASE
        WHEN r.ANSWER_ID IS NOT NULL AND ans.QSTN_ANSWER_ID IS NOT NULL
            THEN 'SELECT'
        WHEN r.ANSWER_CLOB IS NOT NULL
            THEN 'FREE_TEXT'
        WHEN r.QSTN_RESPONSE_ID IS NOT NULL
            THEN 'OTHER'
        ELSE 'NO_RESPONSE'
    END                                 AS ANSWER_MODE,

    r.ANSWER_ID,
    ans.SCORE                           AS ANSWER_SCORE,

    -- Keys for downstream joins
    q.QUESTIONNAIRE_ID,
    q.QSTNR_QUESTION_ID,
    q.QUESTION_ID

FROM QSTNR_QUESTION_BC q

LEFT JOIN QSTNR_RESPONSE_BC r
    ON r.QSTNR_PARTICIPANT_ID = q.QSTNR_PARTICIPANT_ID
   AND r.QSTNR_QUESTION_ID   = q.QSTNR_QUESTION_ID

LEFT JOIN QSTNR_ANSWER_BC ans
    ON ans.QSTN_ANSWER_ID = r.ANSWER_ID

LEFT JOIN JOB_APPLICANTS_R app
    ON app.JOBAPPLICATIONID = q.SUBJECT_ID

LEFT JOIN JOB_REQUISITIONS_R req
    ON req.REQUISITIONID = app.REQUISITIONID
;
