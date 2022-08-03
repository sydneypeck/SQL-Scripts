Select DISTINCT 
pd.PrimaryMrn [1. Patient's ID Number]
, CONVERT(varchar,dos.DateValue,101)  [2. Date Termination Performed]
, provd.name [Provider]
, Cast(GA.weeks as varchar) + 'w' + Cast(GA.Days % GA.Weeks as varchar) + 'd' [7. Clinical estimation of Gestational Age]
, dep.LocationName [15. Name of Facility]
, Case when p.Name is NOT NULL then p.name when  mabcomp.name IS NOT NULL then mabcomp.name else ' ' end [17 & 18. Procedures]
, CASE when comp.name is null then 'NONE' else comp.name END [21. Complications]
FROM EncounterFact encf
Join DateDim dos on dos.Datekey = encf.DateKey
Join PatientDim PD on pd.PatientKey = encf.PatientKey
Join durationdim age on age.DurationKey = encf.AgeKey
Join visitfact VF on VF.EncounterKey = encf.EncounterKey
Join providerdim provd on vf.primaryvisitproviderkey = provd.providerkey
Left Join episodeencountermappingfact eemf on eemf.encounterkey = encf.encounterkey 
Inner Join episodefact ef on eemf.episodekey = ef.episodekey and ef.type = 'Pregnancy'
Left Join pregnancyfact pf on ef.episodekey = pf.episodekey
Left Join episodeencountermappingfact fuenc on fuenc.episodekey = pf.episodekey and fuenc.encounterdatekey > encf.datekey
Left join visitfact fuvf on fuvf.EncounterKey = fuenc.encounterkey
Left join (Select fsvf.value, fsvf.lastinencounter, fsvf.encounterkey from flowsheetvaluefact_FirstandLastinEncounter fsvf
	Inner Join flowsheetrowdim fsrd on fsrd.FlowsheetRowKey = fsvf.flowsheetrowkey and fsrd.FlowsheetRowEpicId = '6782') BCM on BCM.EncounterKey = encf.encounterkey and bcm.lastinencounter = '1'
Join DepartmentDim Dep on Dep.DepartmentKey = encf.DepartmentKey
Join procedureorderfact pof on pof.encounterkey = encf.encounterkey 
Left Join (
	Select poavd.procedureorderkey, string_agg(Right(ad.name, len(ad.name)-75),', ') [Name] , pof.encounterkey
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#31000051734', 'EPIC#31000198746', 'EPIC#31000198747', 'EPIC#31000198751', 'EPIC#31000198752', 'EPIC#31000208610', 'EPIC#31000198753', 'EPIC#31000198750', 'EPIC#31000135563', 'EPIC#31000135564') 
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey
		Group by poavd.ProcedureOrderKey, pof.encounterkey
		) as p on p.encounterkey = encf.encounterkey
Left Join DurationDim GA on vf.gestationalage_x = GA.Days
Left join (Select cnavd.clinicalnoteattributevaluekey, cnavd.StringValue, ad.smartdataelementepicid, ad.name [Name], cnavd.EncounterKey from clinicalnoteattributevaluedim CNAVD
	Inner Join attributedim AD on AD.attributekey = cnavd.attributekey and ad.smartdataelementepicid IN ('PP#024', 'PP#003') ) EDU on EDU.EncounterKey = encf.encounterkey
Left join (Select cnavd.clinicalnoteattributevaluekey, cnavd.StringValue, ad.smartdataelementepicid, ad.name [Name], cnavd.EncounterKey from clinicalnoteattributevaluedim CNAVD
	Inner Join attributedim AD on AD.attributekey = cnavd.attributekey and ad.smartdataelementepicid IN ('EPIC#70730') ) ED on ED.EncounterKey = encf.encounterkey
Left Join (
	Select poavd.procedureorderkey, ad.name, pof.encounterkey, poavd.value
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid = 'EPIC#17906'
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey
		) as fu on fu.encounterkey = encf.encounterkey
Left Join (
	Select poavd.procedureorderkey, string_agg(Right(ad.name, len(ad.name)-39),', ') [Name], pof.encounterkey
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#90410', 'EPIC#31000144396', 'EPIC#31000198784', 'EPIC#31000198786', 'EPIC#71662', 'EPIC#31000198782', 'EPIC#31000203695', 'EPIC#31000181699', 'EPIC#31000198787', 'EPIC#31000208618', 'EPIC#31000091071', 'EPIC#31000079110')
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey
		Group by poavd.ProcedureOrderKey, pof.encounterkey
		) as comp on comp.encounterkey = encf.encounterkey
Left Join (
	Select poavd.procedureorderkey, string_agg(Right(ad.name, len(ad.name)-42),', ') [Name], pof.encounterkey
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid = 'epic#31000161584'
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey
		Group by poavd.ProcedureOrderKey, pof.encounterkey
		) as ICA on ica.encounterkey = encf.encounterkey
Left Join (
	Select poavd.procedureorderkey, ad.name, pof.encounterkey
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('PP#555', 'PP#556', 'PP#557', 'PP#558')
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey) as MABComp on mabcomp.encounterkey = encf.encounterkey
Left Join encounterfact encfhx on encfhx.patientkey = encf.patientkey AND encfhx.type = 'History'
Where (ica.NAME is NOT NULL or MABcomp.name IS NOT NULL) and pd.name not like 'ZZ%' and dos.monthnumber = 5 and dep.name like 'PPGC%'
Order by CONVERT(varchar,dos.DateValue,101)




 



