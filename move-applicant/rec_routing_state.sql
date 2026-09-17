-- =============================================================================
-- LOOKUP TABLE: REC_ROUTING_STATE
-- =============================================================================
-- Distinct recruiting process states from BICC RoutingStepStatePVO extract.
-- Used as LOV for the applicant move action.
--
-- Source: BICC HcmRecProcessLifecycleAM → RoutingStepStatePVO (one-off extract)
-- Data:   Seed data — reload via reload_routing_lookups.sql after env migration.
--         Custom IDs differ per environment; regenerate from fresh BICC extract.
-- =============================================================================

CREATE TABLE rec_routing_state (
    state_id          NUMBER          NOT NULL,
    state_code        VARCHAR2(60)    NOT NULL,
    state_name        VARCHAR2(240)   NOT NULL,
    state_desc        VARCHAR2(500),
    public_state_id   NUMBER,
    public_state_name VARCHAR2(240),
    state_type        VARCHAR2(30)    NOT NULL,   -- APPLICATION, REQUISITION, CANDIDATE, EVENT
    CONSTRAINT rec_routing_state_pk PRIMARY KEY (state_id)
);

CREATE INDEX rec_routing_state_n1 ON rec_routing_state (state_type);

COMMENT ON TABLE  rec_routing_state                    IS 'Recruiting process lifecycle states (LOV for move action)';
COMMENT ON COLUMN rec_routing_state.public_state_id    IS 'External-facing grouping (e.g. 1002=Under Consideration)';
COMMENT ON COLUMN rec_routing_state.state_type         IS 'APPLICATION = job app states, REQUISITION = req states, CANDIDATE = candidate pool, EVENT = registration/attendance';

-- ─── DATA ───────────────────────────────────────────────────────────────────
-- Seed data loaded by: reload_routing_lookups.sql
-- Source: BICC RoutingStepStatePVO (one-off extract per environment)
-- After env migration: run a fresh BICC extract of HcmRecProcessLifecycleAM,
-- regenerate reload_routing_lookups.sql from the new CSVs, then execute it.
