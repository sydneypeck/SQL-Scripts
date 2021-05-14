Select 
pat.name [Patient Name]
, pat.BirthDate [DOB]
, pat.ssn [SSN]
, pat.Address + ' ' + pat.city + ', ' + pat.StateOrProvinceAbbreviation + ' ' + pat.postalcode [Address]
, pat.sex [Sex]
, Case when pat.MultiRacial = 0 then pat.FirstRace else pat.firstrace + ', ' +pat.secondrace + ', ' + pat.ThirdRace + ', ' + pat.FourthRace + ', ' + pat.fifthrace END [Race]
, dos.datevalue [DOS]
, LCD.Name [Lab]
, lcrf.Value [Lab Result]
, ' ' [Treated Y/N]
, '          ' [Treatment Date]
, '                 ' [Treatment Drug]
, pat.patientepicid [ID]
from labcomponentresultfact lcrf
Join patientdim pat on lcrf.patientkey = pat.patientkey
Join labcomponentdim LCD on LCD.LabComponentKey = lcrf.labcomponentkey
Join datedim DOS on lcrf.ordereddatekey = DOS.datekey
Join encounterfact ef on lcrf.encounterkey = ef.encounterkey
Join departmentdim dd on ef.departmentkey = dd.departmentkey
Where  
lcrf.Flag like 'Abn%' AND 
lcrf.ordereddatekey > '20210201'
and lcd.BaseName IN ('CHLAMYDIA', 'CTENDOCERV', 'CTGCCOMBO', 'CTPAP', 'CTPHARYNG', 'CTRECTAL', 'CTSWAB', 'CTURINE', 'CTUROGEN', 'CTVAGINAL', 'FTAABS', 'GCENDOCERV', 'GCPAP', 'GCPHARYNG', 'GCRECTAL', 'GCSWAB', 'GCURINE', 'GCUROGEN', 'GCVAG', 'GONORRHEA', 'HIV1AB', 'HIV2AB', 'HIV12AGAB', 'HIV12POAB', 'HIV1RNAPCR', 'HIV1RNAQLTMA', 'HIV1RNAQN', 'HIV4', 'HIV4RFXRNA', 'HIVGENOSURE', 'HIVGENRES', 'HIVSCFIN', 'RPR', 'RPRTITER', 'SYPHILIS', 'SYPHILISAB', 'RAPDHIV1X2')

-- limit to Texas and clinics, through parameters? Need Same for Louisiana, will it be same report?