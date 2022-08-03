Select distinct
cu.EPT_CSN [Enc_nbr]
, cloc.LOC_NAME [HealthCenterNameLong]
, CASE when cu.QUANTITY < 0 then 'IN' when cu.QUANTITY > 0 then 'OUT' else 'UNK' end [Rec_Type]
, cu.MEDICATION_ID [ItemID]
, CAST(CAST(cu.QUANTITY as int) as varchar) + ' ' + zcmu.NAME [Qty]
, Convert(date, cu.triggered_date) [Rec_date]
, 'Not available' [GL]
, '1' [Fund]
, 'Lora' [Cost Center] --Lora to help with?
, '0' [Rev Src]
, CASE when cu.REVENUE_LOCATION_ID = '1101003' then '25' when cu.REVENUE_LOCATION_ID = '1101002' then '30' when cu.REVENUE_LOCATION_ID = '1101006' then '20' when cu.REVENUE_LOCATION_ID = '1101007' then '50' when cu.REVENUE_LOCATION_ID = '1101008' then '60' when cu.REVENUE_LOCATION_ID = '1101005' then '35' when cu.REVENUE_LOCATION_ID = '1101004' then '11' else 'unk' end [Site]
, '9999' [Project]
, 'Unable' [Account]
, GETDATE() [Export Date]
, coalesce(cm.NAME, cu.proc_description) [Medication]
from clarity_ucl cu
Join clarity_eap ce on ce.PROC_ID = cu.PROCEDURE_ID
--Left Join ARPB_TRANSACTIONS ATX on ATX.PROC_ID = cu.PROCEDURE_ID and cu.EPT_CSN = ATX.PAT_ENC_CSN_ID
Join PATIENT p on p.PAT_ID = cu.PATIENT_ID
Join clarity_loc cloc on cloc.loc_id = cu.revenue_location_ID
left Join ZC_MED_UNIT zcmu on zcmu.disp_qtyunit_c = cu.IMPLIED_QTY_UNIT_C
Join CLARITY_EAP_OT ceo on ceo.PROC_ID = ce.PROC_ID
Left Join clarity_medication cm on cm.medication_id = cu.MEDICATION_ID
where
cu.NDC_CODE_ID is not null and  --gets CAM and Willow
cu.SYSTEM_FLAG_C IN ('1', '3') and --New or modified only
cu.SERVICE_DATE_DT > '2021-05-02' and 
ceo.CODE_TYPE_C IN ('2', '100') and
ceo.cpt_code != 'T1015'
-- Need to limit to CW
-- Not getting immunizations
--Only getting 929 rows when I was getting 1469 with this:
Select distinct 
ce.PROC_NAME 
, cu.proc_description
, p.PAT_NAME
, cu.patient_id
, ce.PROC_CODE
, cu.MEDICATION_ID
, ceo.CPT_CODE
, ceo.CODE_TYPE_C
, cu.SERVICE_DATE_DT
, coalesce(cm.NAME, cu.proc_description)
from clarity_ucl cu
Join clarity_eap ce on ce.PROC_ID = cu.PROCEDURE_ID
--Left Join ARPB_TRANSACTIONS ATX on ATX.PROC_ID = cu.PROCEDURE_ID  and cu.EPT_CSN = ATX.PAT_ENC_CSN_ID
Join PATIENT p on p.PAT_ID = cu.PATIENT_ID
Left Join CLARITY_EAP_OT ceo on ceo.PROC_ID = ce.PROC_ID
Left Join clarity_medication cm on cm.medication_id = cu.MEDICATION_ID
where
(cu.NDC_CODE_ID is NOT null or cu.MEDICATION_ID is not null) and  --gets CAM and Willow
cu.SYSTEM_FLAG_C IN ('1', '3') and --New or modified only
cu.SERVICE_DATE_DT > '2021-05-02' and 
ceo.CODE_TYPE_C IN ('2', '100') and
ceo.CPT_CODE != 'T1015'
and (PROC_CODE in ('S0190') or (cu.PROC_DESCRIPTION LIKE '%miso%'))
Order by PAT_NAME

Select * from clarity_ucl where patient_id = 'Z10899'

Select cu.* from CLARITY_EAP_OT ceo 
Join CLARITY_UCL cu on cu.PROCEDURE_ID = ceo.PROC_ID
where cu.PROC_DESCRIPTION like 'miso%'
 