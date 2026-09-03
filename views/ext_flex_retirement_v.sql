-- EFF decoding view: GCS Retirement
-- Segment mapping confirmed from Manage Extensible Flexfields UI (PER_PERSON_EIT_EFF) - dev2:
-- Char columns:
--   PEI_INFORMATION1 = Working Retiree               (seq 20)
--   PEI_INFORMATION2 = Subject to Earnings Limit     (seq 30)  ** NEW
-- Date columns:
--   PEI_INFORMATION_DATE1 = State of SC Retirement Date  (seq 10)
--   PEI_INFORMATION_DATE2 = TERI Begin Date              (seq 40)  ** NEW
--   PEI_INFORMATION_DATE3 = TERI End Date                (seq 50)  ** NEW
create or replace view ext_flex_retirement_v as
select
    person_extra_info_id,
    person_id,
    candidate_number,
    information_type,
    effective_start_date,
    effective_end_date,
    pei_info1   as working_retiree,               -- PEI_INFORMATION1      seq 20
    pei_info2   as subject_to_earnings_limit,     -- PEI_INFORMATION2      seq 30
    pei_date1   as sc_retirement_date,            -- PEI_INFORMATION_DATE1 seq 10
    pei_date2   as teri_begin_date,               -- PEI_INFORMATION_DATE2 seq 40
    pei_date3   as teri_end_date,                 -- PEI_INFORMATION_DATE3 seq 50
    load_ts
  from ext_flex_stg
 where information_type = 'GCS Retirement'
/
