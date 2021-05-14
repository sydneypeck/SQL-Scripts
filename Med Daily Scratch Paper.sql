--Select Atx.*, CU.PROC_DESCRIPTION, ce.GL_NUM_CREDIT from ARPB_TRANSACTIONS Atx
--Join CLARITY_EAP ce on Atx.PROC_ID = ce.PROC_ID
--Join CLARITY_UCL cu on cu.UCL_ID = Atx.CHG_ROUTER_SRC_ID --and rx_order_dat is not null
--where 
----atx.tx_type_c IN ('1', '3') and
--Atx.POST_DATE > '2021-05-03'and
--Atx.CPT_CODE = 'RXMED'

----Select top 10* from clarity_ucl

--Select zcoc.NAME ,epci.* from Clarity_eap ce
--Join edp_proc_cat_info epci on epci.proc_cat_ID = ce.PROC_CAT_ID
--Join ZC_ORDER_TYPE zcot on zcot.ORDER_TYPE_C = epci.ORDER_TYPE_C
--Join ZC_ORDER_CLASS zcoc on zcoc.ORDER_CLASS_C = epci.IP_def_ord_cls_C
--where ce.PROC_code = 'S0190'

--Select top 10* from CLARITY_UCL where PROCEDURE_ID = '31394' and CHARGE_FILED_TIME > '2021-05-03'

Select distinct 
ce.PROC_NAME
, cu.proc_description
, p.PAT_NAME
, cu.patient_id

from clarity_ucl cu
Join clarity_eap ce on ce.PROC_ID = cu.PROCEDURE_ID
Left Join ARPB_TRANSACTIONS ATX on ATX.PROC_ID = cu.PROCEDURE_ID
Join PATIENT p on p.PAT_ID = cu.PATIENT_ID
where
cu.medication_id is not null and  --gets CAM and Willow
cu.SYSTEM_FLAG_C IN ('1', '3') and --New or modified only
cu.SERVICE_DATE_DT > '2021-05-02'
Order by cu.PATIENT_ID

--Select * from clarity_ucl cu where (cu.medication_id is not null OR.cpt_code = 'RXMED')  and cu.SERVICE_DATE_DT > '2021-05-03'

