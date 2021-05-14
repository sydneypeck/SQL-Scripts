Select distinct
PAT_ENC_CSN_ID
, SUM(CASE when em_code_attribute = 'Pelvic' then 2 when em_code_attribute IN ('Adnexa', 'Uterus', 'Cervix', 'Urethra', 'Bladder', 'Ext') then 1 end) [Elements]
from (SELECT distinct pat_enc_csn_id, EM_Code_Attribute from EM_CODE_CALC 
where EM_CODE_SECTION = 'Genitourinary-Female') genfemale
Group by pat_enc_csn_id


