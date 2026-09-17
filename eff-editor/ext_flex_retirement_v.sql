  CREATE OR REPLACE FORCE EDITIONABLE VIEW "EXT_FLEX_RETIREMENT_V" ("PERSON_EXTRA_INFO_ID", "PERSON_ID", "CANDIDATE_NUMBER", "INFORMATION_TYPE", "EFFECTIVE_START_DATE", "EFFECTIVE_END_DATE", "WORKING_RETIREE", "SUBJECT_TO_EARNINGS_LIMIT", "SC_RETIREMENT_DATE", "TERI_BEGIN_DATE", "TERI_END_DATE", "LOAD_TS") AS 
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
 where information_type = 'GCS Retirement';