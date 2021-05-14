Select 
pat.name [Patient Name]
, pat.BirthDate [DOB]
, dos.datevalue [DOS]
, LCD.Name [Lab]
, lcrf.Value [Lab Result]
, rho.Name [Rhogam Type]
, rho.AdministrationDateKey [Rhogam Date] -- How do I get just the latest Rhogam Date?
from labcomponentresultfact lcrf
Join patientdim pat on lcrf.patientkey = pat.patientkey
Join labcomponentdim LCD on LCD.LabComponentKey = lcrf.labcomponentkey
Join datedim DOS on lcrf.ordereddatekey = DOS.datekey
Join medicationadministrationfact maf on maf.patientkey = pat.patientkey
Left join (Select maf2.AdministrationDateKey, md.simplegenericname, md.name, maf2.patientkey from medicationadministrationfact  maf2
	Inner join medicationdim md on maf2.PrimaryComponentKey = md.medicationepicid and  md.simplegenericname = 'Rho D Immune Globulin') Rho on rho.patientkey = pat.patientkey
Where  
--lcrf.ordereddatekey > '20210201' and
 lcd.CommonName IN ('RH TYPING, POC', 'RH TYPE') and lcrf.value LIKE '%Neg%'

