Select DISTINCT 
'7910' [1a. Facility ID Number]
,pd.PrimaryMrn [1. Patient's ID Number]
, age.Years [2. Patient's age]
, CONVERT(varchar,dos.DateValue,101)  [3. Date Termination Performed]
, pd.country [4a. Residence- Country]
, pd.stateorprovinceabbreviation [4b. Residence- State]
, pd.county [4c. Residence- County]
, pd.City [4d. Residence- City]
, Case when pd.MultiRacial = 0 then pd.FirstRace else pd.firstrace + ', ' + ', ' +pd.secondrace + ', ' + pd.ThirdRace + ', ' + pd.FourthRace + ', ' + pd.fifthrace END [5. Patient's race]  
, pd.Ethnicity [6. Is patient of Hispanic origin?] 
, pf.PregnancySpontaneousAbortionCount [7a. Spontaneous Abortions]
, encf.OBLiveBirths_X [7b. Live Births]
, pf.PregnancyTherapeuticAbortionCount [7c. Therapeutic Abortions]
, 'Medication with Mife and Miso' [8. Primary Procedure]
-- Complications- Need procedureorderattributevaluedim to be fixed
-- Management of complications, not sure how to get it
, vf.LMP_X [11. Date last normal menses began]
, vf.gestationalage_x [12. Physician's estimate of gestation] -- may need to be linked to duration dim to be w/d form
, 'Unknown' [13. Fetal Anomalies]
, Convert(varchar, CAST( getdate() as date), 101) [14. Date report completed]
FROM EncounterFact encf
Join DateDim dos on dos.Datekey = encf.DateKey
Join EpisodeEncounterMappingFact EEMF on EEMF.EncounterKey = encf.EncounterKey
Join PatientDim PD on pd.PatientKey = encf.PatientKey
Join durationdim age on age.DurationKey = encf.AgeKey
Join visitfact VF on VF.EncounterKey = encf.EncounterKey
Join pregnancyfact pf on pf.PatientKey = encf.PatientKey
Join procedureorderfact pof on pof.encounterkey = encf.encounterkey 
Left Join procedureorderattributevaluedim POAVD on poavd.procedureorderkey = pof.procedureorderkey and poavd.AttributeKey IN ('814928', '977845', '112536', '1063710', '27786', '507014', '871111', '1258760', '139106', '170261') -- Fix in prod
Join departmentdim dep on dep.DepartmentKey = encf.departmentkey
Left Join (
	Select poavd.procedureorderkey, string_agg(Right(ad.name, len(ad.name)-75),', ') [Name] , pof.encounterkey
		from procedureorderattributevaluedim POAVD
		Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#31000051734', 'EPIC#31000198746', 'EPIC#31000198747', 'EPIC#31000198751', 'EPIC#31000198752', 'EPIC#31000208610', 'EPIC#31000198753', 'EPIC#31000198750', 'EPIC#31000135563', 'EPIC#31000135564') 
		Join procedureorderfact pof on pof.procedureorderkey = poavd.procedureorderkey
		Group by poavd.ProcedureOrderKey, pof.encounterkey
		) as p on p.encounterkey = encf.encounterkey
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
Where (ica.NAME is NOT NULL or MABcomp.name IS NOT NULL)

-- Others as parameters to get just WA and this affiliate


