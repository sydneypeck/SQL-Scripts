Select distinct 
ce.ORDER_DISPLAY_NAME [Epic Display Name]
, ORDER_LOOKUP_NAME [Epic Back End Name]
, ce2.PROC_Name [Component Name]
, olr.EXTERNAL_ID
, cpt.CPT_CODE
, cfp.UNIT_CHARGE_AMOUNT 
from LPF_PRF_LST_ID_ITM lplii
Inner Join ORDER_LOOKUP_REC olr on olr.ORDER_LOOKUP_ID = lplii.orx_id
Join CLARITY_EAP ce on ce.PROC_ID = olr.PROC_ID
Join LINKED_CHARGEABLES lc on lc.PROC_ID = ce.proc_id	
Left Join CLARITY_EAP ce2 on lc.LINKED_CHRG_ID = ce2.PROC_ID
Left join CLARITY_FSC_PROC cfp on cfp.PROC_ID = ce2.proc_id and FEE_SCHEDULE_ID = '43'
Outer Apply (
		Select top 1* 
		from CLARITY_EAP_OT ceo 
		where ceo.PROC_ID = ce2.PROC_ID
		order by CONTACT_DATE_REAL
		) cpt
where lplii.preference_ID = '6488' -- This is PPGC's fee schedule ID


--Select * from clarity_fsc where FEE_SCHEDULE_NAME like 'PPGC%' -- Use to get Fee Schedule ID


Select * from LPF_PRF_LST_ID_ITM lplii where lplii.PREFERENCE_ID = '6488'