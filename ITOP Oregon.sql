Select DISTINCT 
 pd.name
, pd.patientkey
, encf.EncounterEpicCsn
, encf.encounterkey
, pf.pregnancykey
, pd.PrimaryMrn [1. Patient's ID Number]
, CONVERT(varchar,dos.DateValue,101)  [2. Date Termination Performed]
, age.Years [3. Patient's age]
, pd. Address + ', ' + pd.City + ', ' + pd.county + ', ' + pd. StateOrProvinceAbbreviation [4. Patient's Residence Address]
, vf.LMP_X [6. Date last normal menses began]
, Cast(GA.weeks as varchar) + 'w' + Cast(GA.Days % GA.Weeks as varchar) + 'd' [7. Clinical estimation of Gestational Age]
, encfhx.obliving_x [8a. Live births now living]
, (encfhx.oblivebirths_X - encfhx.obliving_X) [8b. Live births now dead]
, pf.PregnancySpontaneousAbortionCount [9a. Spontaneous Abortions]
, pf.PregnancyTherapeuticAbortionCount [9b. Therapeutic Abortions]
, pd.MaritalStatus [10. Marital Status]
, pd.HighestLevelOfEducation [11. Education]
, pd.Ethnicity [12. Is patient of Hispanic origin?]
, Case when pd.MultiRacial = 0 then pd.FirstRace else pd.firstrace + ', ' + ', ' +pd.secondrace + ', ' + pd.ThirdRace + ', ' + pd.FourthRace + ', ' + pd.fifthrace END  [13. Patient's race] 
, CASE when bcm.Value is not NULL then 'Yes' else 'No' END [14. Was birth control being used] 
, bcm.Value [14a. BCM]
, dep.LocationName [15. Name of Facility]
, Dep.city + ', ' + Dep.county + ', ' + Dep.StateOrProvinceAbbreviation + ', ' + Dep.PostalCode [16. Location of Termination] 
, Case when p.Name is NOT NULL then p.name when  mabcomp.name IS NOT NULL then mabcomp.name else ' ' end [17 & 18. Procedures]
, Case when mabcomp.name IS NOT NULL then 'Yes' when fu.Value =1 then 'Yes' else 'No' end [19. Follow up Recommended]
, CASE when edu.stringValue is not NULL then 'Yes' else 'No' END [20. Was postop info provided]
, CASE when comp.name is null then 'NONE' else comp.name END [21. Complications]
, Case when fuenc.encounterdatekey is not NULL and fuvf.appointmentstatus = 'Completed' then 'Yes' else 'No' END [22. Further visits]
, CASE when ED.StringValue is null then 'No' else 'Yes- See chart' END [23. Was patient seen outside clinic]
FROM EncounterFact encf
Join DateDim dos on dos.Datekey = encf.DateKey
Join PatientDim PD on pd.PatientKey = encf.PatientKey
Join durationdim age on age.DurationKey = encf.AgeKey
Join visitfact VF on VF.EncounterKey = encf.EncounterKey
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
Where (ica.NAME is NOT NULL or MABcomp.name IS NOT NULL) and pd.name not like 'ZZ%'
--Other filters as parameters



 



