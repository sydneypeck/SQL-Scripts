Select distinct
dep.LocationName -- Is this right? Not sure what DatasetName means and if this should be patient's name
, CONVERT(varchar,dos.DateValue,101) [Encounter Date]
, Convert (varchar, pd.BirthDate, 101) [DOB]
, pd.PrimaryMrn [MRN]
, prov.Name [Provider]
, procval.value [16. Type of termination procedure] 
, Cast(postf.weeks as varchar) + 'w' + Cast(postf.Days % postf.Weeks as varchar) + 'd' [State Gest Age]
, Cast(ga.weeks as varchar) + 'w' + Cast(ga.Days % GA.Weeks as varchar) + 'd' [NAF Gest Age]
, '?' [GA Reporting Group] -- Need definitions
From encounterfact encf
Join patientdim pd on encf.PatientKey = pd.patientkey
Join DateDim dos on dos.Datekey = encf.DateKey
Join visitfact VF on VF.EncounterKey = encf.EncounterKey
Join pregnancyfact pf on pf.PatientKey = encf.PatientKey
Join durationdim postf on (vf.GestationalAge_X + 14) = postf.days
Join durationdim GA on vf.gestationalage_x = ga.Days
Join procedureorderfact pof on pof.encounterkey = encf.encounterkey 
Join DepartmentDim Dep on Dep.DepartmentKey = encf.DepartmentKey
Join ProviderDim prov on prov.providerkey = encf.providerkey
Left join (Select poavd.procedureorderkey, poavd.Value, ad.smartdataelementepicid, Right(ad.name, len(ad.name)-75) [Name] from procedureorderattributevaluedim POAVD
	Inner Join attributedim AD on AD.attributekey = poavd.attributekey and ad.smartdataelementepicid IN ('EPIC#31000051734', 'EPIC#31000198746', 'EPIC#31000198747', 'EPIC#31000198751', 'EPIC#31000198752', 'EPIC#31000208610', 'EPIC#31000198753', 'EPIC#31000198750', 'EPIC#31000135563', 'EPIC#31000135564') ) procval on procval.procedureorderkey = pof.procedureorderkey
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