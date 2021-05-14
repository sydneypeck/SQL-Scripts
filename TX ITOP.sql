Select distinct
encf.encounterepiccsn,
'AS000103' [Facilty Code]
, Convert (varchar, pd.BirthDate, 101) [1. Date of Birth]
, pd.MaritalStatus [2. Married?]
, Case when pd.MultiRacial = 0 then pd.FirstRace + ', ' + + pd.ethnicity else pd.firstrace + ', ' + pd.ethnicity +', ' +pd.secondrace + ', ' + pd.ThirdRace + ', ' + pd.FourthRace + ', ' + pd.fifthrace END [3. Patient's Race/Ethnicity]
, pd.county [4. Patient's county of Residence]
, pd.stateorprovinceabbreviation [5. Patient's State of Residence]
, '?' [6. Was proof of the patient's identity obtained?] -- What do they mean here? Do we need a scanned driver's license?
, '?' [7. Was proof of the patient's age obtained?]
, CONVERT(varchar,dos.DateValue,101) [8. Abortion Date]
, vf.lmp_X [9. Date of Last Menses]
, Cast(GA.weeks as varchar) + 'w' + Cast(GA.Days % GA.Weeks as varchar) + 'd' [10. Probable Post-Fertilization Age]
, encf.oblivebirths_x [11. Number of Previous Live Births]
, pf.pregnancytherapeuticabortioncount [12. Number of Previous Induced Abortions]
, '?' [13. Patient Viewed Woman's Right to Know Act Material] -- What is this? Is there an SDE for it? Asked Tram 4/6/21
, 'Ultrasound' [14. Method of Pregnancy Verification] 
, 'Yes' [15. Patient completed Abortion and Sonogram Election Form] 
, procval.value [16. Type of termination procedure] 
, Case when mof.ordername is not null then 'IV' else 'None' End [17. Type of Anesthesia Used]
, Case when poc.smartdataelementepicid = 'EPIC#31000198790' then 'Medical Waste' when poc.smartdataelementepicid = 'EPIC#31000198793' then 'Pathology' when poc.smartdataelementepicid = 'EPIC#31000198796' then 'Law Enforcement' when poc.smartdataelementepicid is not null then poc.Name else 'N/A' end [18. Method used to dispose of POC]
, Case when pd.deathdate IS NOT NULL then 'No' else 'Yes' END [19. Did patient survive]
, Case when pd.deathdate IS NOT NULL then 'Check Chart' else 'N/A' END [20. Patient's Cause of Death]
From encounterfact encf
Join patientdim pd on encf.PatientKey = pd.patientkey
Join DateDim dos on dos.Datekey = encf.DateKey
Join visitfact VF on VF.EncounterKey = encf.EncounterKey
Join pregnancyfact pf on pf.PatientKey = encf.PatientKey
Join durationdim GA on (vf.GestationalAge_X + 14) = ga.days
Join procedureorderfact pof on pof.encounterkey = encf.encounterkey 
Left join (Select poavd.procedureorderkey, poavd.Value, ad.smartdataelementepicid, Right(ad.name, len(ad.name)-75) [Name] from procedureorderattributevaluedim POAVD
	Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#31000051734', 'EPIC#31000198746', 'EPIC#31000198747', 'EPIC#31000198751', 'EPIC#31000198752', 'EPIC#31000208610', 'EPIC#31000198753', 'EPIC#31000198750', 'EPIC#31000135563', 'EPIC#31000135564') ) procval on procval.procedureorderkey = pof.procedureorderkey
Left join medicationorderfact mof on mof.encounterkey = encf.encounterkey and route = 'Intravenous'
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
Left join (Select poavd.procedureorderkey, poavd.Value, ad.smartdataelementepicid, Right(ad.name, len(ad.name)-82) [Name] from procedureorderattributevaluedim POAVD
	Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#31000198790', 'EPIC#31000198793', 'EPIC#31000198796' ) ) POC on POC.procedureorderkey = pof.procedureorderkey
Where (ica.NAME is NOT NULL or MABcomp.name IS NOT NULL)