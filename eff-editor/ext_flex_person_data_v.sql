-- =============================================================================
-- VIEW: EXT_FLEX_PERSON_DATA_V
-- =============================================================================
-- Decodes the "Additional GCS Person Data" EFF context from ext_flex_stg.
-- Returns one row per person (latest effective_start_date wins).
--
-- Segment mapping from /describe endpoint (2026-09-15):
--   10 character fields (PEI_INFORMATION1-10), 6 number fields, NO date fields.
--
-- GCS Recruiting Details is a SEPARATE context with its own view
-- (ext_flex_recruiting_v). This view does NOT include those fields.
-- =============================================================================
create or replace view ext_flex_person_data_v as
select
    person_extra_info_id,
    person_id,
    candidate_number,
    information_type,
    effective_start_date,
    effective_end_date,
    -- Character columns (PEI_INFORMATION1–10)
    pei_info1   as teacher_subject_area,            -- GCS_TEACH_SUBJECT
    pei_info2   as smartfind_class_code,            -- GCS_SMART_CLASS
    pei_info3   as banked_vacation,                 -- HRC_YES_NO
    pei_info4   as contract_type,                   -- GCS_CONTRACT_TYPE
    pei_info5   as contract_stipulation_1,          -- GCS_CONTRACT_STIPS
    pei_info6   as contract_stipulation_2,          -- GCS_CONTRACT_STIPS
    pei_info7   as contract_stipulation_3,          -- GCS_CONTRACT_STIPS
    pei_info8   as vacation_carryover_extension,    -- HRC_YES_NO
    pei_info9   as national_board_certified,        -- GCS_NBCT
    pei_info10  as para_professional_hq,            -- GCS_PARA_PROF_HQ
    -- Number columns (PEI_INFORMATION_NUMBER1–6)
    pei_num1    as teacher_years_of_experience,
    pei_num2    as cate_experience,
    pei_num3    as personal_leave_used,
    pei_num4    as bus_driver_years_of_exp,
    pei_num5    as bus_aide_years_of_exp,
    pei_num6    as educator_id,
    load_ts
  from (
    select s.*,
           row_number() over (partition by s.person_id
                              order by s.effective_start_date desc) as rn
      from ext_flex_stg s
     where s.information_type = 'Additional GCS Person Data'
  )
 where rn = 1
/
