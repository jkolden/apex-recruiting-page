-- EFF decoding view: GCS Recruiting Details
-- Replaces ext_flex_job_refs_v (old context "GCS Job Application References" was removed in dev2)
-- This context merges most segments from the old "Additional GCS Person Data" context
-- with new recruiting-specific fields (Pay Grade, Pay Step, Comments, Additional Comments)
-- Segment mapping confirmed from Manage Extensible Flexfields UI (PER_PERSON_EIT_EFF):
-- Char columns:
--   PEI_INFORMATION1  = Interview Notes               (seq 10)
--   PEI_INFORMATION2  = Certification                 (seq 30)
--   PEI_INFORMATION3  = SLED                          (seq 40)
--   PEI_INFORMATION4  = Reference Check               (seq 50)
--   PEI_INFORMATION5  = Work Keys                     (seq 60)
--   PEI_INFORMATION6  = Processing Owner              (seq 90)
--   PEI_INFORMATION7  = Comments                      (seq 130)  ** NEW
--   PEI_INFORMATION8  = Pay Grade                     (seq 110)  ** NEW
--   PEI_INFORMATION9  = Pay Step                      (seq 120)  ** NEW
--   PEI_INFORMATION10 = Additional Comments           (seq 140)  ** NEW
--   PEI_INFORMATION11 = Contract Type                 (seq 150)
--   PEI_INFORMATION12 = Contract Stip 1               (seq 160)
--   PEI_INFORMATION13 = Contract Stip 2               (seq 170)
--   PEI_INFORMATION14 = Contract Stip 3               (seq 180)
--   PEI_INFORMATION15 = Rehire Eligibility            (seq 190)
--   PEI_INFORMATION16 = Teacher Subject Area          (seq 210)
-- Date columns:
--   PEI_INFORMATION_DATE1 = Proposed Effective Date   (seq 70)
-- Number columns:
--   PEI_INFORMATION_NUMBER1 = Teacher Assessment Score       (seq 20)
--   PEI_INFORMATION_NUMBER2 = Additional FTE                 (seq 80)
--   PEI_INFORMATION_NUMBER3 = Teacher Years of Experience    (seq 200)
--   PEI_INFORMATION_NUMBER4 = Educator ID                    (seq 220)
--   PEI_INFORMATION_NUMBER5 = CATE Experience                (seq 230)  (UI shows "GATE")
--   PEI_INFORMATION_NUMBER6 = FTE                            (seq 240)
create or replace view ext_flex_recruiting_v as
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
 where information_type = 'GCS Recruiting Details'
/
