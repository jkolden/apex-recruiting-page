  CREATE OR REPLACE FORCE EDITIONABLE VIEW "EXT_FLEX_RECRUITING_V" ("PERSON_EXTRA_INFO_ID", "PERSON_ID", "CANDIDATE_NUMBER", "INFORMATION_TYPE", "EFFECTIVE_START_DATE", "EFFECTIVE_END_DATE", "INTERVIEW_NOTES", "CERTIFICATION", "SLED", "REFERENCE_CHECK", "WORK_KEYS", "PROCESSING_OWNER", "COMMENTS", "PAY_GRADE", "PAY_STEP", "ADDITIONAL_COMMENTS", "CONTRACT_TYPE", "CONTRACT_STIP_1", "CONTRACT_STIP_2", "CONTRACT_STIP_3", "REHIRE_ELIGIBILITY", "TEACHER_SUBJECT_AREA", "PROPOSED_EFFECTIVE_DATE", "TEACHER_ASSESSMENT_SCORE", "ADDITIONAL_FTE", "TEACHER_YEARS_OF_EXPERIENCE", "EDUCATOR_ID", "CATE_EXPERIENCE", "FTE", "LOAD_TS") AS 
  select
    person_extra_info_id,
    person_id,
    candidate_number,
    information_type,
    effective_start_date,
    effective_end_date,
    -- Character columns
    pei_info1   as interview_notes,               -- PEI_INFORMATION1  seq 10
    pei_info2   as certification,                 -- PEI_INFORMATION2  seq 30
    pei_info3   as sled,                          -- PEI_INFORMATION3  seq 40
    pei_info4   as reference_check,               -- PEI_INFORMATION4  seq 50
    pei_info5   as work_keys,                     -- PEI_INFORMATION5  seq 60
    pei_info6   as processing_owner,              -- PEI_INFORMATION6  seq 90
    pei_info7   as comments,                      -- PEI_INFORMATION7  seq 130
    pei_info8   as pay_grade,                     -- PEI_INFORMATION8  seq 110
    pei_info9   as pay_step,                      -- PEI_INFORMATION9  seq 120
    pei_info10  as additional_comments,           -- PEI_INFORMATION10 seq 140
    pei_info11  as contract_type,                 -- PEI_INFORMATION11 seq 150
    pei_info12  as contract_stip_1,               -- PEI_INFORMATION12 seq 160
    pei_info13  as contract_stip_2,               -- PEI_INFORMATION13 seq 170
    pei_info14  as contract_stip_3,               -- PEI_INFORMATION14 seq 180
    pei_info15  as rehire_eligibility,            -- PEI_INFORMATION15 seq 190
    pei_info16  as teacher_subject_area,          -- PEI_INFORMATION16 seq 210
    -- Date column
    pei_date1   as proposed_effective_date,       -- PEI_INFORMATION_DATE1 seq 70
    -- Number columns
    pei_num1    as teacher_assessment_score,      -- PEI_INFORMATION_NUMBER1 seq 20
    pei_num2    as additional_fte,                -- PEI_INFORMATION_NUMBER2 seq 80
    pei_num3    as teacher_years_of_experience,   -- PEI_INFORMATION_NUMBER3 seq 200
    pei_num4    as educator_id,                   -- PEI_INFORMATION_NUMBER4 seq 220
    pei_num5    as cate_experience,               -- PEI_INFORMATION_NUMBER5 seq 230
    pei_num6    as fte,                           -- PEI_INFORMATION_NUMBER6 seq 240
    load_ts
  from ext_flex_stg
 where information_type = 'GCS Recruiting Details';