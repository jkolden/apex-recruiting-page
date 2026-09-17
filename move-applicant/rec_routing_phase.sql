-- =============================================================================
-- LOOKUP TABLE: REC_ROUTING_PHASE
-- =============================================================================
-- Distinct recruiting process phases from BICC RoutingStepPhasePVO extract.
-- Used as LOV for the applicant move action.
--
-- Source: BICC HcmRecProcessLifecycleAM → RoutingStepPhasePVO (one-off extract)
-- Data:   Seed data — reload via reload_routing_lookups.sql after env migration.
--         Custom IDs differ per environment; regenerate from fresh BICC extract.
-- =============================================================================

CREATE TABLE rec_routing_phase (
    phase_id      NUMBER          NOT NULL,
    phase_code    VARCHAR2(60)    NOT NULL,
    phase_name    VARCHAR2(240)   NOT NULL,
    phase_desc    VARCHAR2(500),
    seq_num       NUMBER,
    phase_type    VARCHAR2(30)    NOT NULL,   -- APPLICATION, REQUISITION, CANDIDATE, EVENT
    CONSTRAINT rec_routing_phase_pk PRIMARY KEY (phase_id)
);

CREATE INDEX rec_routing_phase_n1 ON rec_routing_phase (phase_type, seq_num);

COMMENT ON TABLE  rec_routing_phase              IS 'Recruiting process lifecycle phases (LOV for move action)';
COMMENT ON COLUMN rec_routing_phase.phase_type   IS 'APPLICATION = job app phases, REQUISITION = req phases, CANDIDATE = candidate pool, EVENT = registration/attendance';

-- ─── DATA ───────────────────────────────────────────────────────────────────
-- Seed data loaded by: reload_routing_lookups.sql
-- Source: BICC RoutingStepPhasePVO (one-off extract per environment)
-- After env migration: run a fresh BICC extract of HcmRecProcessLifecycleAM,
-- regenerate reload_routing_lookups.sql from the new CSVs, then execute it.
