Select distinct cfp.PROC_ID
, ce.PROC_NAME
, cfp.UNIT_CHARGE_AMOUNT 
, cpt.cpt_code
from clarity_fsc_proc cfp
Join CLARITY_EAP ce on ce.PROC_ID = cfp.PROC_ID
Outer Apply (
		Select top 1* 
		from CLARITY_EAP_OT ceo 
		where ceo.PROC_ID = ce.PROC_ID
		order by CONTACT_DATE_REAL
		) cpt
where cfp.fee_schedule_id = '43'

