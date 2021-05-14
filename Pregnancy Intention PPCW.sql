SELECT distinct
encf.PatientKey
, vf.VisitType
, vf.encountertype
, encf.EncounterEpicCsn
--, encf.encounterkey
, dos.datevalue [Enc Date]
, dep.locationname [Health Center]
, dos.MonthNumber [Month]
, age.years [Age at DOS]
, fspreg1y.value [Planning Pregnancy Next Year]
, CASE when FSPreg1y.Value is not Null and encf.Date = pregi.DateValue then 'Yes' else 'No' end [PregInt Answered Current Enc]
, CASE when FSPreg1y.Value is not Null and pregi.DateValue BETWEEN dateadd(month, -12, dos.datevalue) and dos.datevalue then 'Yes' else 'No' END [PregInt Answered Past 12 Mos]
, CASE when FSPreg1y.Value is not null and encf.Date = pregi.DateValue then 'Yes' when FSPreg1y.Value is not Null and pregi.DateValue BETWEEN dateadd(month, -12, dos.datevalue) and dos.datevalue then 'Yes' else 'No' END [PregInt Answered Today or Past 12 months] 
, endbcm.Value [BCM at End of Visit]
, CASE when endbcm.value is null then 'No' else 'Yes' end [BCM Recorded for Current Visit]
, pregi.datevalue
FROM encounterfact Encf
Inner join visitfact vf on vf.encounterkey = encf.encounterkey
Join DateDim dos on dos.datekey = encf.DateKey
Join patientdim PD on pd.patientkey = encf.patientkey
Join durationdim age on age.durationkey=encf.AgeKey
Join DepartmentDim Dep on Dep.departmentkey = encf.DepartmentKey
Left join (
	Select max(FSVF.flowsheetvaluekey) [FSVK], encf.encounterkey FROM flowsheetvaluefact FSVF 
		INNER JOIN flowsheetrowdim FSRD on FSRD.FlowsheetRowKey = FSVF.FlowsheetRowKey and FSRD.FlowsheetRowEpicId = '6638'
		Inner Join encounterfact encf on fsvf.patientdurablekey = encf.patientdurablekey and fsvf.datekey <= encf.datekey
		Group by encf.encounterkey
		  ) FSPregRecent on FSPregRecent.EncounterKey = encf.EncounterKey
Left join flowsheetvaluefact fspreg1y on fspreg1y.flowsheetvaluekey = fspregrecent.fsvk
Left Join DateDim pregi on fspreg1y.datekey = pregi.datekey
Left join (
	Select AD.smartdataelementepicid, EAVD.Value, EAVD.Encounterkey  FROM Encounterattributevaluedim EAVD
		INNER JOIN attributedim AD on EAVD.attributekey = AD.attributekey and AD.smartdataelementepicid = 'PP#183'
			) EndBCM on EndBCM.encounterkey = encf.encounterkey
Where 
-- dos.datevalue > dateadd (m, -1, getdate()) --Parameter
dos.datevalue > '05-03-2021' and dos.datevalue < getdate()
and pd.sex = 'Female'
and Dep.locationname LIKE '%Vancouver%'
and age.years BETWEEN '15' and '44'
and vf.encountertype not in ('Pharmacy Visit', 'Refill', 'Ancillary Procedure', 'Lab')
and vf.visittype not in ('Supply', 'Lab')

Order by patientkey