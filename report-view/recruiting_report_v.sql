-- =============================================================================
-- VIEW: RECRUITING_REPORT_V
-- =============================================================================
-- Consolidated recruiting report view combining REST applicant/requisition
-- data with EFF person flexfields, employee lookups, and dimension tables.
-- Covers both Teacher and Non-Teacher legacy report fields.
-- =============================================================================

CREATE OR REPLACE VIEW RECRUITING_REPORT_V AS
WITH latest_app AS (
    SELECT a.*,
           ROW_NUMBER() OVER (PARTITION BY a.JOBAPPLICATIONID
                              ORDER BY a."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
    FROM JOB_APPLICANTS_R a
),
latest_req AS (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY r.REQUISITIONID
                              ORDER BY r."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
    FROM JOB_REQUISITIONS_R r
),
latest_pos AS (
    SELECT p.*,
           ROW_NUMBER() OVER (PARTITION BY p.POSITIONID
                              ORDER BY p."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
    FROM HCM_POSITION_R p
),
latest_person_data AS (
    SELECT pd.*,
           ROW_NUMBER() OVER (PARTITION BY pd.person_id
                              ORDER BY pd.effective_start_date DESC) AS rn
    FROM ext_flex_person_data_v pd
),
latest_job_refs AS (
    SELECT refs.*,
           ROW_NUMBER() OVER (PARTITION BY refs.person_id
                              ORDER BY refs.effective_start_date DESC) AS rn
    FROM ext_flex_job_refs_v refs
),
latest_retirement AS (
    SELECT ret.*,
           ROW_NUMBER() OVER (PARTITION BY ret.person_id
                              ORDER BY ret.effective_start_date DESC) AS rn
    FROM ext_flex_retirement_v ret
),
latest_loc AS (
    SELECT loc.*,
           ROW_NUMBER() OVER (PARTITION BY loc.LOCATIONID
                              ORDER BY loc."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
    FROM LOCATIONS_R loc
),
latest_cand AS (
    SELECT c.*,
           ROW_NUMBER() OVER (PARTITION BY c.PERSONID
                              ORDER BY c."APEX$ROW_SYNC_TIMESTAMP" DESC) AS rn
    FROM RECRUITING_CANDIDATES_R c
),
latest_dept AS (
    SELECT d.*,
           ROW_NUMBER() OVER (PARTITION BY d.ORGANIZATIONID
                              ORDER BY d.EFFECTIVESTARTDATE DESC) AS rn
    FROM DEPARTMENTS_R d
    WHERE d.ACTIVESTATUS = 'A'
),
latest_pub AS (
    SELECT requisition_id,
           published_visibility,
           published_posting_status,
           published_start_date,
           published_end_date,
           published_time_zone,
           published_created_by,
           ROW_NUMBER() OVER (
               PARTITION BY requisition_id
               ORDER BY published_start_date DESC NULLS LAST
           ) AS rn
      FROM req_published_jobs_r
),
latest_gallup AS (
    SELECT ga.*,
           ROW_NUMBER() OVER (PARTITION BY ga.PERSON_ID
                              ORDER BY ga.SCORE DESC NULLS LAST, ga.SUBMISSION_ID DESC) AS rn
    FROM bip_gallup_assessments ga
),
teach_refs AS (
    SELECT
        SUBJECT_ID,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_1_NAME'  THEN ANSWER_TEXT END) AS GCS_TEACH_REF_1_NAME,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_1_PHONE' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_1_PHONE,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_1_EMAIL' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_1_EMAIL,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_REL1'    THEN ANSWER_TEXT END) AS GCS_TEACH_REF_1_REL,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_2_NAME'  THEN ANSWER_TEXT END) AS GCS_TEACH_REF_2_NAME,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_2_PHONE' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_2_PHONE,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_2_EMAIL' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_2_EMAIL,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_REL2'    THEN ANSWER_TEXT END) AS GCS_TEACH_REF_2_REL,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_3_NAME'  THEN ANSWER_TEXT END) AS GCS_TEACH_REF_3_NAME,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_3_PHONE' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_3_PHONE,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_3_EMAIL' THEN ANSWER_TEXT END) AS GCS_TEACH_REF_3_EMAIL,
        MAX(CASE WHEN QUESTION_CODE = 'GCS_TEACH_REF_REL3'    THEN ANSWER_TEXT END) AS GCS_TEACH_REF_3_REL
    FROM FBX_QSTNR_V
    WHERE QUESTION_CODE IN (
        'GCS_TEACH_REF_1_NAME','GCS_TEACH_REF_1_PHONE','GCS_TEACH_REF_1_EMAIL','GCS_TEACH_REF_REL1',
        'GCS_TEACH_REF_2_NAME','GCS_TEACH_REF_2_PHONE','GCS_TEACH_REF_2_EMAIL','GCS_TEACH_REF_REL2',
        'GCS_TEACH_REF_3_NAME','GCS_TEACH_REF_3_PHONE','GCS_TEACH_REF_3_EMAIL','GCS_TEACH_REF_REL3'
    )
    GROUP BY SUBJECT_ID
),
survey_status AS (
    SELECT
        href.PERSON_ID,
        COUNT(DISTINCT href.REF_EMAIL)     AS SURVEY_RESPONDENT_COUNT,
        LISTAGG(DISTINCT LOWER(TRIM(href.REF_EMAIL)), ',')
            WITHIN GROUP (ORDER BY LOWER(TRIM(href.REF_EMAIL))) AS SURVEY_EMAILS
    FROM CANDIDATE_REFERENCES href
    JOIN CANDIDATE_REFERENCE_ANSWERS sa
        ON sa.SURVEY_TOKEN = href.SURVEY_TOKEN
    GROUP BY href.PERSON_ID
)
SELECT
    /* -- Requisition -- */
    req.REQUISITIONID                   AS JOB_REQUISITION_ID,
    req.JOBFUNCTION                     AS CATEGORY,
    app.REQUISITIONNUMBER               AS REQ,
    req.TITLE                           AS JOB,
    loc.LOCATIONNAME                    AS SCHOOL,
    loc.LOCATIONCODE                    AS LOCATION_CODE,
    dept.NAME                           AS DEPARTMENT_NAME,
    dept.LOCATIONNAME                   AS DEPT_LOCATION,
    pos.NAME                            AS POSITION_NAME,
    j.JOB_NAME,

    /* -- Requisition Status -- */
    req.PHASENAME                       AS REQ_PHASE,
    req.STATENAME                       AS REQ_STATE,
    req.INTERNALPUBLISHEDJOBSTATUS      AS INTERNAL_POSTING_STATUS,
    req.EXTERNALPUBLISHEDJOBSTATUS      AS EXTERNAL_POSTING_STATUS,
    req.NUMBEROFOPENINGS,
    req.HIREDCOUNT,
    req.RECRUITINGTYPE,
    req.FULLTIMEORPARTTIME,
    CASE
      WHEN req.INTERNALPUBLISHEDJOBSTATUS = 'ORA_POSTED'
       AND req.EXTERNALPUBLISHEDJOBSTATUS = 'ORA_POSTED' THEN '2 of 2 Postings Live'
      WHEN req.INTERNALPUBLISHEDJOBSTATUS = 'ORA_POSTED'
        OR req.EXTERNALPUBLISHEDJOBSTATUS = 'ORA_POSTED' THEN '1 of 2 Postings Live'
      ELSE 'No Active Postings'
    END                                 AS POSTING_SUMMARY,

    /* -- Candidate -- */
    app.JOBAPPLICATIONID                AS JOB_APPLICATION_ID,
    app.CANDIDATEPERSONID               AS CAND_NUM,
    emp.PERSON_NUMBER                   AS EE_NUM,
    CASE WHEN app.INTERNALFLAG = 'true'
         THEN 'Internal' ELSE 'External'
    END                                 AS INTEXT,
    app.CANDIDATENAME                   AS NAME,
    LOWER(TRIM(cand.EMAIL))              AS CANDIDATE_EMAIL,
    cand.CANDIDATENUMBER                  AS CANDIDATE_NUMBER,

    /* -- People -- */
    req.HIRINGMANAGERID                 AS HIRING_MANAGER_ID,
    req.RECRUITERID                     AS RECRUITER_ID,
    mgr.DISPLAY_NAME                    AS HIRING_MANAGER,
    rec.DISPLAY_NAME                    AS RECRUITER,
    rc.REQUESTED_BY,

    /* -- Application Status -- */
    app.PHASENAME                       AS APPLICATION_PHASE,
    app.STATENAME                       AS APPLICATION_STATE,
    app.JOBAPPLICATIONDATE              AS APPLICATION_DATE,

    /* -- EFF: Additional GCS Person Data -- */
    pd.rehire_eligible,
    pd.reference_check,
    pd.sled                             AS BACKGROUND_CHECK,
    pd.certification,
    pd.work_keys,
    pd.teacher_assessment_score         AS ASSESSMENT_SCORE,
    pd.interview_notes,
    pd.teacher_subject_area,
    pd.gcs_effective_date               AS EFF_EFFECTIVE_DATE,

    /* -- EFF: Job Application References -- */
    refs.reference_1_name                AS EFF_REFERENCE_1_NAME,
    refs.reference_1_email               AS EFF_REFERENCE_1_EMAIL,
    refs.reference_2_name                AS EFF_REFERENCE_2_NAME,
    refs.reference_2_email               AS EFF_REFERENCE_2_EMAIL,
    refs.reference_3_name                AS EFF_REFERENCE_3_NAME,
    refs.reference_3_email               AS EFF_REFERENCE_3_EMAIL,

    /* -- EFF: Retirement -- */
    ret.working_retiree,
    ret.sc_retirement_date,

    /* -- Requisition DFF -- */
    dff.TRANSFER_COORDINATED,
    dff.VACANCY_TERM_SUBMITTED,

    /* -- Published Job (newest posting) -- */
    pub.PUBLISHED_VISIBILITY,
    pub.PUBLISHED_POSTING_STATUS,
    pub.PUBLISHED_START_DATE,
    pub.PUBLISHED_END_DATE,
    pub.PUBLISHED_TIME_ZONE,
    pub.PUBLISHED_CREATED_BY,

    /* -- Gallup Assessment (from BIP) -- */
    ga.score                             AS GALLUP_SCORE,
    ga.band                              AS GALLUP_BAND,
    ga.package_status_code               AS GALLUP_STATUS,
    REPLACE(REPLACE(TRIM(ga.gallup_result_url), CHR(10), ''), CHR(13), '') AS GALLUP_RESULT_URL,

    /* -- Questionnaire: Teacher References (COALESCE correction over original) -- */
    COALESCE(rc.REF_1_NAME,  tr.GCS_TEACH_REF_1_NAME)                       AS GCS_TEACH_REF_1_NAME,
    fmt_phone(COALESCE(rc.REF_1_PHONE, tr.GCS_TEACH_REF_1_PHONE))           AS GCS_TEACH_REF_1_PHONE,
    LOWER(TRIM(COALESCE(rc.REF_1_EMAIL, tr.GCS_TEACH_REF_1_EMAIL)))         AS GCS_TEACH_REF_1_EMAIL,
    tr.GCS_TEACH_REF_1_REL                                                   AS GCS_TEACH_REF_1_REL,
    COALESCE(rc.REF_2_NAME,  tr.GCS_TEACH_REF_2_NAME)                       AS GCS_TEACH_REF_2_NAME,
    fmt_phone(COALESCE(rc.REF_2_PHONE, tr.GCS_TEACH_REF_2_PHONE))           AS GCS_TEACH_REF_2_PHONE,
    LOWER(TRIM(COALESCE(rc.REF_2_EMAIL, tr.GCS_TEACH_REF_2_EMAIL)))         AS GCS_TEACH_REF_2_EMAIL,
    tr.GCS_TEACH_REF_2_REL                                                   AS GCS_TEACH_REF_2_REL,
    COALESCE(rc.REF_3_NAME,  tr.GCS_TEACH_REF_3_NAME)                       AS GCS_TEACH_REF_3_NAME,
    fmt_phone(COALESCE(rc.REF_3_PHONE, tr.GCS_TEACH_REF_3_PHONE))           AS GCS_TEACH_REF_3_PHONE,
    LOWER(TRIM(COALESCE(rc.REF_3_EMAIL, tr.GCS_TEACH_REF_3_EMAIL)))         AS GCS_TEACH_REF_3_EMAIL,
    tr.GCS_TEACH_REF_3_REL                                                   AS GCS_TEACH_REF_3_REL,

    /* -- Reference Correction Indicators -- */
    CASE WHEN rc.job_application_id IS NOT NULL THEN 'Y' ELSE 'N' END AS REFS_CORRECTED_YN,
    rc.corrected_on                                     AS REFS_CORRECTED_ON,
    /* Per-field change flags (Y only if value actually differs from original) */
    CASE WHEN rc.ref_1_name  IS NOT NULL AND rc.ref_1_name  != NVL(rc.orig_ref_1_name,  CHR(0)) THEN 'Y' ELSE 'N' END AS REF_1_NAME_CHG,
    CASE WHEN rc.ref_1_phone IS NOT NULL AND rc.ref_1_phone != NVL(rc.orig_ref_1_phone, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_1_PHONE_CHG,
    CASE WHEN rc.ref_1_email IS NOT NULL AND rc.ref_1_email != NVL(rc.orig_ref_1_email, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_1_EMAIL_CHG,
    CASE WHEN rc.ref_2_name  IS NOT NULL AND rc.ref_2_name  != NVL(rc.orig_ref_2_name,  CHR(0)) THEN 'Y' ELSE 'N' END AS REF_2_NAME_CHG,
    CASE WHEN rc.ref_2_phone IS NOT NULL AND rc.ref_2_phone != NVL(rc.orig_ref_2_phone, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_2_PHONE_CHG,
    CASE WHEN rc.ref_2_email IS NOT NULL AND rc.ref_2_email != NVL(rc.orig_ref_2_email, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_2_EMAIL_CHG,
    CASE WHEN rc.ref_3_name  IS NOT NULL AND rc.ref_3_name  != NVL(rc.orig_ref_3_name,  CHR(0)) THEN 'Y' ELSE 'N' END AS REF_3_NAME_CHG,
    CASE WHEN rc.ref_3_phone IS NOT NULL AND rc.ref_3_phone != NVL(rc.orig_ref_3_phone, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_3_PHONE_CHG,
    CASE WHEN rc.ref_3_email IS NOT NULL AND rc.ref_3_email != NVL(rc.orig_ref_3_email, CHR(0)) THEN 'Y' ELSE 'N' END AS REF_3_EMAIL_CHG,

    /* -- Principal/Manager Ranking -- */
    rnk.RANKING_SCORE,
    rnk.RANKING_TEXT,
    rnk.RANKING_NOTE,
    rnk.RANKED_BY,
    rnk.RANKED_ON,

    /* -- Reference Survey Responses -- */
    ss.PERSON_ID                                             AS SURVEY_PERSON_ID,
    NVL(ss.SURVEY_RESPONDENT_COUNT, 0)                       AS SURVEY_RESPONDENT_COUNT,
    CASE WHEN INSTR(',' || ss.SURVEY_EMAILS || ',',
        ',' || LOWER(TRIM(COALESCE(rc.REF_1_EMAIL, tr.GCS_TEACH_REF_1_EMAIL))) || ',') > 0
        THEN 'Y' ELSE 'N' END                               AS REF_1_SURVEY_YN,
    CASE WHEN INSTR(',' || ss.SURVEY_EMAILS || ',',
        ',' || LOWER(TRIM(COALESCE(rc.REF_2_EMAIL, tr.GCS_TEACH_REF_2_EMAIL))) || ',') > 0
        THEN 'Y' ELSE 'N' END                               AS REF_2_SURVEY_YN,
    CASE WHEN INSTR(',' || ss.SURVEY_EMAILS || ',',
        ',' || LOWER(TRIM(COALESCE(rc.REF_3_EMAIL, tr.GCS_TEACH_REF_3_EMAIL))) || ',') > 0
        THEN 'Y' ELSE 'N' END                               AS REF_3_SURVEY_YN,

    /* -- Candidate Notes -- */
    NVL(cn.note_count, 0)                                    AS NOTE_COUNT,

    /* -- Applicant Notes (person-level) -- */
    NVL(an.note_count, 0)                                    AS APPLICANT_NOTE_COUNT,

    /* -- Candidate Phones -- */
    NVL(ph.phone_count, 0)                                   AS PHONE_COUNT

FROM latest_app app

LEFT JOIN latest_req req
    ON req.REQUISITIONID = app.REQUISITIONID AND req.rn = 1

LEFT JOIN latest_pos pos
    ON pos.POSITIONID = req.POSITIONID AND pos.rn = 1

LEFT JOIN latest_loc loc
    ON loc.LOCATIONID = req.PRIMARYWORKLOCATIONID AND loc.rn = 1

LEFT JOIN latest_dept dept
    ON dept.ORGANIZATIONID = req.DEPARTMENTID AND dept.rn = 1

LEFT JOIN DIM_JOB_R j
    ON j.JOB_ID = req.JOBID

LEFT JOIN FBX_HCM_EMPLOYEE emp
    ON emp.PERSON_ID = app.CANDIDATEPERSONID

LEFT JOIN FBX_HCM_EMPLOYEE mgr
    ON mgr.PERSON_ID = req.HIRINGMANAGERID

LEFT JOIN FBX_HCM_EMPLOYEE rec
    ON rec.PERSON_ID = req.RECRUITERID

LEFT JOIN latest_cand cand
    ON cand.PERSONID = app.CANDIDATEPERSONID AND cand.rn = 1

LEFT JOIN latest_person_data pd
    ON pd.person_id = app.CANDIDATEPERSONID AND pd.rn = 1

LEFT JOIN latest_job_refs refs
    ON refs.person_id = app.CANDIDATEPERSONID AND refs.rn = 1

LEFT JOIN latest_retirement ret
    ON ret.person_id = app.CANDIDATEPERSONID AND ret.rn = 1

LEFT JOIN REQ_DFF_R dff
    ON dff.REQUISITION_ID = req.REQUISITIONID

LEFT JOIN latest_pub pub
    ON pub.REQUISITION_ID = req.REQUISITIONID AND pub.rn = 1

LEFT JOIN latest_gallup ga
    ON ga.person_id = app.CANDIDATEPERSONID AND ga.rn = 1

LEFT JOIN teach_refs tr
    ON tr.SUBJECT_ID = app.JOBAPPLICATIONID

LEFT JOIN ref_correction rc
    ON rc.job_application_id = app.JOBAPPLICATIONID

LEFT JOIN applicant_ranking rnk
    ON rnk.JOB_APPLICATION_ID = app.JOBAPPLICATIONID

LEFT JOIN survey_status ss
    ON ss.PERSON_ID = app.CANDIDATEPERSONID

LEFT JOIN (SELECT job_application_id, COUNT(*) AS note_count
           FROM candidate_note GROUP BY job_application_id) cn
    ON cn.job_application_id = app.JOBAPPLICATIONID

LEFT JOIN (SELECT person_id, COUNT(*) AS note_count
           FROM applicant_note GROUP BY person_id) an
    ON an.person_id = app.CANDIDATEPERSONID

LEFT JOIN (SELECT person_id, COUNT(*) AS phone_count
           FROM candidate_phones_r GROUP BY person_id) ph
    ON ph.person_id = app.CANDIDATEPERSONID

WHERE app.rn = 1
ORDER BY req.JOBFUNCTION, app.REQUISITIONNUMBER;
