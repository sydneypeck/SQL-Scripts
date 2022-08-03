SELECT distinct
pd.PrimaryMrn [MRN]
, vf.VisitType
, vf.encountertype
, encf.EncounterEpicCsn
--, encf.encounterkey
, dos.datevalue [Enc Date]
, dep.locationname [Health Center]
, dos.MonthNumber [Month]
, age.years [Age at DOS]
, fspregrecent.value [Planning Pregnancy Next Year]
, CASE when FSPregrecent.Value is not Null and encf.Date = pregi.DateValue then 'Yes' else 'No' end [PregInt Answered Current Enc]
, CASE when FSPreg1y.Value is not Null and pregi.DateValue BETWEEN dateadd(month, -12, dos.datevalue) and dateadd(day, -1, dos.datevalue) then 'Yes' else 'No' END [PregInt Answered Past 12 Mos]
, CASE when FSPreg1y.Value is not null and encf.Date = pregi.DateValue then 'Yes' when FSPreg1y.Value is not Null and pregi.DateValue BETWEEN dateadd(month, -12, dos.datevalue) and dos.datevalue then 'Yes' else 'No' END [PregInt Answered Today or Past 12 months] 
, endbcm.Value [BCM at End of Visit]
, CASE when endbcm.value is null then 'No' else 'Yes' end [BCM Recorded for Current Visit]
, pregi.datevalue
FROM encounterfact Encf
Join visitfact vf on vf.encounterkey = encf.encounterkey
Join DateDim dos on dos.datekey = encf.DateKey
Join patientdim PD on pd.patientkey = encf.patientkey
Join durationdim age on age.durationkey=encf.AgeKey
Join DepartmentDim Dep on Dep.departmentkey = encf.DepartmentKey
Left join (
	Select max(FSVF.flowsheetvaluekey) [FSVK], encf.encounterkey, fsvf.value, fsvf.datekey FROM flowsheetvaluefact FSVF 
		INNER JOIN flowsheetrowdim FSRD on FSRD.FlowsheetRowKey = FSVF.FlowsheetRowKey and FSRD.FlowsheetRowEpicId = '6638'
		Inner Join encounterfact encf on fsvf.patientdurablekey = encf.patientdurablekey and fsvf.datekey = encf.datekey
		Group by encf.encounterkey, fsvf.value, fsvf.datekey
		  ) FSPregRecent on FSPregRecent.EncounterKey = encf.EncounterKey
Left join flowsheetvaluefact fspreg1y on fspreg1y.flowsheetvaluekey = fspregrecent.fsvk
Left Join DateDim pregi on fspregrecent.datekey = pregi.datekey
Left join (
	Select AD.smartdataelementepicid, Max(EAVD.Value) value, EAVD.DateKey, eavd.EncounterKey  FROM Encounterattributevaluedim EAVD
		INNER JOIN attributedim AD on EAVD.attributekey = AD.attributekey and AD.smartdataelementepicid = 'PP#183'
		Group by eavd.datekey, ad.smartdataelementepicid, eavd.encounterkey) EndBCM on EndBCM.encounterkey = encf.encounterkey
Where 

dos.datevalue > '05-03-2021' and dos.datevalue < getdate()
and pd.sex = 'Female'
and Dep.locationname LIKE '%Vancouver%'
and age.years BETWEEN '15' and '44'
and vf.encountertype not in ('Pharmacy Visit', 'Refill', 'Ancillary Procedure', 'Lab')
and vf.visittype not in ('Supply', 'Lab')
and pd.test = 0
and encf.derivedencounterstatus = 'Complete'
and encf.isoutpatientfacetofacevisit = 1
and vf.encountertype != 'Appointment'
Order by pd.PrimaryMrn