CREATE OR REPLACE PACKAGE BODY pkg_ref_correction AS

    -- =========================================================================
    -- GENERATE_TOKEN
    -- Creates a secure token, stores it, returns the full correction URL.
    -- =========================================================================
    FUNCTION generate_token (
        p_job_application_id  IN NUMBER,
        p_requested_by        IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_token        VARCHAR2(64);
        l_base_url     VARCHAR2(4000);
        l_requester    VARCHAR2(240);
    BEGIN
        -- 64 hex chars from two GUIDs (32 bytes of entropy)
        l_token := RAWTOHEX(SYS_GUID()) || RAWTOHEX(SYS_GUID());

        l_requester := COALESCE(
            p_requested_by,
            SYS_CONTEXT('APEX$SESSION','APP_USER'),
            USER
        );

        INSERT INTO ref_correction_token (
            token, job_application_id, requested_by, expires_on
        ) VALUES (
            l_token, p_job_application_id, l_requester,
            SYSTIMESTAMP + INTERVAL '72' HOUR
        );

        -- Build URL from config
        l_base_url := pkg_email.get_config('APEX_BASE_URL');
        IF l_base_url IS NULL THEN
            l_base_url := 'https://CONFIGURE-APEX-BASE-URL';
        END IF;

        -- Remove trailing slash if present
        l_base_url := RTRIM(l_base_url, '/');

        -- No explicit COMMIT here — APEX commits at the end of the Ajax callback.
        -- An explicit COMMIT corrupts APEX session state and breaks subsequent calls.

        -- Convert friendly URL base to legacy f?p= format
        -- /ords/r/freedemo/fa_integ_ibzsjb_test -> /ords/freedemo
        -- Required because friendly URLs are off; wwv_flow.accept only works under legacy path
        l_base_url := REGEXP_REPLACE(l_base_url, '/r/([^/]+)/[^/]+$', '/\1');

        RETURN l_base_url || '/f?p=121:100:::::P100_TOKEN:' || l_token;
    END generate_token;


    -- =========================================================================
    -- VALIDATE_TOKEN
    -- Returns job_application_id if token is valid, NULL otherwise.
    -- =========================================================================
    FUNCTION validate_token (p_token IN VARCHAR2) RETURN NUMBER IS
        l_app_id NUMBER;
    BEGIN
        SELECT job_application_id INTO l_app_id
          FROM ref_correction_token
         WHERE token    = p_token
           AND used_yn  = 'N'
           AND expires_on > SYSTIMESTAMP;

        RETURN l_app_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END validate_token;


    -- =========================================================================
    -- CONSUME_TOKEN
    -- Mark token as used after successful correction submission.
    -- =========================================================================
    PROCEDURE consume_token (p_token IN VARCHAR2) IS
    BEGIN
        UPDATE ref_correction_token
           SET used_yn = 'Y',
               used_on = SYSTIMESTAMP
         WHERE token   = p_token
           AND used_yn = 'N';
    END consume_token;


    -- =========================================================================
    -- SAVE_CORRECTIONS
    -- Validates token, snapshots current questionnaire refs, MERGEs
    -- corrections into ref_correction, consumes token.
    -- =========================================================================
    PROCEDURE save_corrections (
        p_token       IN VARCHAR2,
        p_ref_1_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_1_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_1_email IN VARCHAR2 DEFAULT NULL,
        p_ref_2_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_2_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_2_email IN VARCHAR2 DEFAULT NULL,
        p_ref_3_name  IN VARCHAR2 DEFAULT NULL,
        p_ref_3_phone IN VARCHAR2 DEFAULT NULL,
        p_ref_3_email IN VARCHAR2 DEFAULT NULL
    ) IS
        l_app_id       NUMBER;
        l_token_id     NUMBER;
        l_requested_by VARCHAR2(240);

        -- Original values from questionnaire
        l_orig_1_name  VARCHAR2(500);
        l_orig_1_phone VARCHAR2(100);
        l_orig_1_email VARCHAR2(500);
        l_orig_2_name  VARCHAR2(500);
        l_orig_2_phone VARCHAR2(100);
        l_orig_2_email VARCHAR2(500);
        l_orig_3_name  VARCHAR2(500);
        l_orig_3_phone VARCHAR2(100);
        l_orig_3_email VARCHAR2(500);
    BEGIN
        -- Validate token
        l_app_id := validate_token(p_token);
        IF l_app_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'Invalid, expired, or already-used correction link.');
        END IF;

        -- Get token metadata
        SELECT token_id, requested_by
          INTO l_token_id, l_requested_by
          FROM ref_correction_token
         WHERE token = p_token;

        -- Snapshot current questionnaire ref values (same pivot as ext_refs CTE)
        -- Question codes renamed in dev2: GCS_TEACH_REF_* -> GCS_REF_EXT_* / GCS_EXT_REF_*
        BEGIN
            SELECT
                MAX(CASE WHEN QUESTION_CODE = 'GCS_REF_EXT_NAME1'   THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_PHONE1'  THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_REF_EXT_EMAIL1'  THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_NAME2'   THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_PHONE2'  THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_EMAIL2'  THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_NAME3'   THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_PHONE3'  THEN ANSWER_TEXT END),
                MAX(CASE WHEN QUESTION_CODE = 'GCS_EXT_REF_EMAIL3'  THEN ANSWER_TEXT END)
            INTO
                l_orig_1_name, l_orig_1_phone, l_orig_1_email,
                l_orig_2_name, l_orig_2_phone, l_orig_2_email,
                l_orig_3_name, l_orig_3_phone, l_orig_3_email
            FROM FBX_QSTNR_V
            WHERE SUBJECT_ID = l_app_id
              AND QUESTION_CODE IN (
                  'GCS_REF_EXT_NAME1','GCS_EXT_REF_PHONE1','GCS_REF_EXT_EMAIL1',
                  'GCS_EXT_REF_NAME2','GCS_EXT_REF_PHONE2','GCS_EXT_REF_EMAIL2',
                  'GCS_EXT_REF_NAME3','GCS_EXT_REF_PHONE3','GCS_EXT_REF_EMAIL3'
              );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL;  -- no questionnaire data yet, originals stay NULL
        END;

        -- MERGE corrections (most recent correction wins)
        MERGE INTO ref_correction t
        USING (SELECT l_app_id AS job_application_id FROM dual) s
        ON (t.job_application_id = s.job_application_id)
        WHEN MATCHED THEN UPDATE SET
            t.ref_1_name      = p_ref_1_name,
            t.ref_1_phone     = p_ref_1_phone,
            t.ref_1_email     = p_ref_1_email,
            t.ref_2_name      = p_ref_2_name,
            t.ref_2_phone     = p_ref_2_phone,
            t.ref_2_email     = p_ref_2_email,
            t.ref_3_name      = p_ref_3_name,
            t.ref_3_phone     = p_ref_3_phone,
            t.ref_3_email     = p_ref_3_email,
            t.orig_ref_1_name  = l_orig_1_name,
            t.orig_ref_1_phone = l_orig_1_phone,
            t.orig_ref_1_email = l_orig_1_email,
            t.orig_ref_2_name  = l_orig_2_name,
            t.orig_ref_2_phone = l_orig_2_phone,
            t.orig_ref_2_email = l_orig_2_email,
            t.orig_ref_3_name  = l_orig_3_name,
            t.orig_ref_3_phone = l_orig_3_phone,
            t.orig_ref_3_email = l_orig_3_email,
            t.token_id         = l_token_id,
            t.corrected_on     = SYSTIMESTAMP,
            t.requested_by     = l_requested_by
        WHEN NOT MATCHED THEN INSERT (
            job_application_id,
            ref_1_name, ref_1_phone, ref_1_email,
            ref_2_name, ref_2_phone, ref_2_email,
            ref_3_name, ref_3_phone, ref_3_email,
            orig_ref_1_name, orig_ref_1_phone, orig_ref_1_email,
            orig_ref_2_name, orig_ref_2_phone, orig_ref_2_email,
            orig_ref_3_name, orig_ref_3_phone, orig_ref_3_email,
            token_id, corrected_on, requested_by
        ) VALUES (
            l_app_id,
            p_ref_1_name, p_ref_1_phone, p_ref_1_email,
            p_ref_2_name, p_ref_2_phone, p_ref_2_email,
            p_ref_3_name, p_ref_3_phone, p_ref_3_email,
            l_orig_1_name, l_orig_1_phone, l_orig_1_email,
            l_orig_2_name, l_orig_2_phone, l_orig_2_email,
            l_orig_3_name, l_orig_3_phone, l_orig_3_email,
            l_token_id, SYSTIMESTAMP, l_requested_by
        );

        -- Consume the token
        consume_token(p_token);

        -- No explicit COMMIT — APEX commits at the end of the request.
        -- An explicit COMMIT here corrupts APEX session state.
    END save_corrections;


    -- =========================================================================
    -- SEND_CORRECTION_EMAIL
    -- Sends the correction link to the candidate via pkg_email.
    -- =========================================================================
    PROCEDURE send_correction_email (
        p_job_application_id  IN NUMBER,
        p_candidate_email     IN VARCHAR2,
        p_candidate_name      IN VARCHAR2,
        p_url                 IN VARCHAR2,
        p_personal_note       IN VARCHAR2 DEFAULT NULL
    ) IS
        l_html CLOB;
    BEGIN
        l_html :=
            '<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">'
         || '<h2 style="color: #2c5f2d;">Greenville County Schools</h2>'
         || '<p>Hello ' || HTF.ESCAPE_SC(p_candidate_name) || ',</p>'
         || '<p>We are reaching out regarding your job application. '
         || 'We need you to review and, if necessary, correct your reference contact information.</p>'
         || CASE WHEN p_personal_note IS NOT NULL THEN
                '<div style="background: #f8f9fa; border-left: 3px solid #2c5f2d; '
             || 'padding: 12px 16px; margin: 20px 0; border-radius: 0 6px 6px 0;">'
             || '<p style="margin: 0; color: #333;">'
             || HTF.ESCAPE_SC(p_personal_note) || '</p></div>'
            END
         || '<p style="text-align: center; margin: 30px 0;">'
         || '<a href="' || HTF.ESCAPE_SC(p_url) || '" '
         || 'style="background-color: #2c5f2d; color: white; padding: 14px 28px; '
         || 'text-decoration: none; border-radius: 5px; font-size: 16px;">'
         || 'Review My References</a></p>'
         || '<p style="color: #666; font-size: 13px;">'
         || 'This link will expire in 72 hours and can only be used once. '
         || 'If you did not expect this email, please disregard it.</p>'
         || '<p style="color: #666; font-size: 13px;">'
         || 'If the button above does not work, copy and paste this URL into your browser:</p>'
         || '<p style="word-break: break-all; font-size: 12px; color: #999;">'
         || HTF.ESCAPE_SC(p_url) || '</p>'
         || '</div>';

        pkg_email.send_mail_now(
            p_to        => p_candidate_email,
            p_subject   => 'Please Review Your Reference Information',
            p_body_html => l_html,
            p_body_text => 'Hello ' || p_candidate_name
                        || ', please review your reference information at: ' || p_url
                        || CASE WHEN p_personal_note IS NOT NULL
                               THEN CHR(10) || CHR(10) || 'Note: ' || p_personal_note
                           END
                        || ' (link expires in 72 hours).',
            p_tag       => 'REF_CORRECTION'
        );

        -- Record which email the link was sent to
        UPDATE ref_correction_token
           SET candidate_email = p_candidate_email
         WHERE job_application_id = p_job_application_id
           AND used_yn = 'N'
           AND candidate_email IS NULL;

        -- No explicit COMMIT — APEX commits at the end of the Ajax callback.
    END send_correction_email;


    -- =========================================================================
    -- GET_CANDIDATE_EMAIL
    -- Returns WORK_EMAIL for internal candidates, NULL for external.
    -- =========================================================================
    FUNCTION get_candidate_email (p_job_application_id IN NUMBER) RETURN VARCHAR2 IS
        l_email VARCHAR2(500);
    BEGIN
        SELECT emp.WORK_EMAIL INTO l_email
          FROM JOB_APPLICANTS_R app
          JOIN FBX_HCM_EMPLOYEE emp ON emp.PERSON_ID = app.CANDIDATEPERSONID
         WHERE app.JOBAPPLICATIONID = p_job_application_id
           AND app.INTERNALFLAG = 'true'
           AND emp.WORK_EMAIL IS NOT NULL
           AND ROWNUM = 1;

        RETURN l_email;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_candidate_email;

END pkg_ref_correction;
/
