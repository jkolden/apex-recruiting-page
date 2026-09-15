-- =============================================================================
-- TABLE: APPLICANT_RANKING
-- =============================================================================
-- Stores principal/manager ranking for each job application.
-- One shared ranking per application (any authorized user can update).
-- =============================================================================

CREATE TABLE applicant_ranking (
    job_application_id   NUMBER        NOT NULL,
    ranking_score        NUMBER(1)     NULL,          -- 1-5 numeric scale
    ranking_text         VARCHAR2(30)  NULL,          -- Highly Recommended / Recommended / Consider / Not Recommended
    ranking_note         VARCHAR2(500) NULL,          -- optional free-text note
    ranked_by            VARCHAR2(240) NOT NULL,      -- APEX user who last set the ranking
    ranked_on            TIMESTAMP(6)  DEFAULT SYSTIMESTAMP NOT NULL,
    --
    CONSTRAINT applicant_ranking_pk PRIMARY KEY (job_application_id),
    CONSTRAINT applicant_ranking_score_ck CHECK (ranking_score BETWEEN 1 AND 5),
    CONSTRAINT applicant_ranking_text_ck CHECK (
        ranking_text IN ('Highly Recommended','Recommended','Consider','Not Recommended')
    )
);

COMMENT ON TABLE  applicant_ranking IS 'Principal/manager ranking per job application';
COMMENT ON COLUMN applicant_ranking.ranking_score IS '1 (lowest) to 5 (highest)';
COMMENT ON COLUMN applicant_ranking.ranking_text  IS 'Categorical recommendation';
COMMENT ON COLUMN applicant_ranking.ranking_note  IS 'Optional free-text justification';
COMMENT ON COLUMN applicant_ranking.ranked_by     IS 'APEX username who last updated';
COMMENT ON COLUMN applicant_ranking.ranked_on     IS 'Timestamp of last ranking update';

CREATE OR REPLACE TRIGGER applicant_ranking_biu
BEFORE INSERT OR UPDATE ON applicant_ranking
FOR EACH ROW
BEGIN
    :NEW.ranked_by := COALESCE(SYS_CONTEXT('APEX$SESSION','APP_USER'), USER);
    :NEW.ranked_on := SYSTIMESTAMP;
END;
/
