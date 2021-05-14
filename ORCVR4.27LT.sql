
SET @Version_Number_OR = '1804'
DROP TABLE IF EXISTS #ORAhlersSubmit;
DROP TABLE IF EXISTS ##RHProgInv

CREATE TABLE #ORAhlersSubmit(
	PAT_ENC_CSN_ID numeric(18,0) -- do not report
	,SiteID char(7)null  [1]
	,PAT_ID char(9)null --either or
	,ACCOUNT_ID char(9)null 
	,DOS char (8)null
	,POV char(2)null 
	,DOB char(8)null
	,medical services subtable char(71)null --as separate columns to concat
	,medical provider char(4) null
	,counseling services subtable char(26)null separate columns
	,version_number char(4)null
	,SEX char(1)null
	,HispEth char(1)null
	,PatRace char(7)null 
	,[LEP-PtDemo_CareLang] varchar(1) 
	,ZipCode char(5)null, 

	,INPATIENT_DATA_ID varchar(18) --do not report
	,PlanPreg char(1) null
	,BegCM char(2) null 
	,ReasonNone char(1) null 
	,CTHx char(1) null
	,CtOrderDate char(6)null
	,PapHx char(1) null
	,PapOrderDate char(6)null 
);

/* 
	Initial insert -- include everything that's easy and doesn't have complex logic 
*/
INSERT INTO #ORAhlersSubmit (
	PAT_ENC_CSN_ID ---Key DNR
	,INPATIENT_DATA_ID --Key DNR
	,SiteID [1 Site]
	,PAT_ID [2a PatID]-- one or the other 
	,ACCOUNT_ID [2b Acc]
	,DOS [3 DOS]
	,DOB [4 DOB]
	,Sex [5 ASAB]
	,HispEth [6 Eth]
	,PatRace [6aRace]
	--[7a1]--ctresp Distinct UPdate
	--[7a1a]--ctdate  Distinct UPdate
	--[7a2]--papresp  Distinct UPdate
	--[7a2a]--papdate  Distinct UPdate
	,LEP-PtDemo_CareLang [7a5 LEP]

	,ZipCode [8 Zip]
	--,[9]--source of pay
	--[10a]--monthly income 
	--[10b]--number supported
	--[13a]--medical services ea per column query
	--[13b14b]--provider
	--[14a]counseling services ea per column 
	--[15a1]--contra before
	--[15b2]--contra after
	--[15b]--reason none
	--[16]--outside referrals
	--[18]insurance status
	--[19]--preg intent
	-------- below here RH Billing Data Elements only. 
	--[A]last name  from #RHProgInv
	--[B]first name  from #RHProgInv
	--[C]middle initial from #RHProgInv
	--[E]rh id  from #RHProgInv
	--[D]ssn  from #RHProgInv
	--POV  from #RHProgInv
	--,dx1  char(7) null        from #RHProgInv
	--,dx2  char(7) null from #RHProgInv
	--,dx3  char(7) null from #RHProgInv
	--,dx4 char(7) null  from #RHProgInv
	--,dx5  char(7) null from #RHProgInv
	--,dx6  char(7) null from #RHProgInv
	--,ins billed char(1) null  from #RHProgInv
	--,conf special char (1)null  from #RHProgInv
	--contra1  from #RHProgInv
	--supQ1  from #RHProgInv
	--contrac2  from #RHProgInv
	--supQ2  from #RHProgInv
	--contra3  from #RHProgInv
	--supQ3  from #RHProgInv
	--contra4  from #RHProgInv
	--supQ4  from #RHProgInv
	--TPR  from #RHProgInv
	--other ins paid  from #RHProgInv

	--Invoice #  from #RHProgInv --Custom

	--supply1rate  from #RHProgInv
	--supply2rate  from #RHProgInv
	--supply3rate  from #RHProgInv
	--supply4rate  from #RHProgInv
	--dx1          from #RHProgInv
	--[9b]--ins billed   from #RHProgInv
	--[9c]--conf special  from #RHProgInv

,AgeAtEnc  -- Filter DNR
	

	
)
 


UPDATE #ORAhlersSubmit


select
@version#
pe.pat_enc_csn_id --key
,pe.inpatient_data_id --key
,case when
PE.DEPARTMENT_ID in ('110100502') then '1000' --milwaukie
		when PE.DEPARTMENT_ID in ('110100602') then '2010' --NEPortland
		when PE.DEPARTMENT_ID in ('110100202') then '3010' --Beaverton
		when PE.DEPARTMENT_ID in ('110100402') then '3121' --EastPortland
		when PE.DEPARTMENT_ID in ('110100702') then '5010' --Salem
		--when pe.DEPARTMENT_ID in ('110100802') then '6010' --Vancouver Washington Excluded
		when PE.DEPARTMENT_ID in ('110100302') then '7010' --CentralBend
		else 'error' end [SiteID]--1
	,Pat1.PAT_ID  --among others --2
	,pe.ACCOUNT_ID --could be one of the others, so this is the join --2 
	,pe.CONTACT_DATE DOS --hopefullyDOS --3
	,Pat1.BIRTH_DATE DOB--4
	,DATEDIFF(year,pat1.BIRTH_DATE,pe.CONTACT_DATE) AgeAtEnc this is a reference for other things
	,pat4.SEX_ASGN_AT_BIRTH_C --5
	,case 
		When Pat1.ethnic_GRoup_C in('1') then '9'  --3 unk, 4 decline,
		WHen Pat1.ETHNIC_GROUP_C in ('8','6','7','5','2') then '6'
		Else '' end [HispEth] --6
	,PatRace.PatRace  -- 6a
	,case when pat1.LANG_CARE_C in ('22') then ''
		when pat1.lang_care_c is null then '' 
		else '5' end [LEP-PtDemo_CareLang] --7a LEP where Care Lang is not English
	,interpreter_need_YN --alternate LEP
	,left(PAT1.ZIP,5)ZipCode --8 zip
	,pe.INPATIENT_DATA_ID -- KEy
,case 
when PE.VISIT_PROV_TITLE in ('50','100','610','630','744') then '1'
when PE.VISIT_PROV_TITLE in  ('30','150','190','480','640','670') then '2'
when PE.VISIT_PROV_TITLE in ('20','80','240','250','310','490','600','620','650','660') then '3' else '4'
end [CounselEdu]
,case when
vcpp.fin_class_c = 1 then '4' --self pay
when vcpp.fin_class_c in (1,10,100,101) then '2' --private
when vcpp.fin_class_c in (3,103,104,107,108) then '1' --public health ins MMC mcd
else '4'--unknown
end [CovStatus] 

FROM PAT_ENC PE 
INNER JOIN PATIENT pat1 
	ON PE.PAT_ID = pat1.PAT_ID 
INNER JOIN PATIENT_4 pat4 
	ON PE.PAT_ID = pat4.PAT_ID 
join V_COVERAGE_PAYOR_PLAN vcpp on vcpp.COVERAGE_ID =PE.COVERAGE_ID
join  CLARITY_EPP on clarity_epp.PAYOR_ID = vcpp.PAYOR_ID
LEFT OUTER JOIN ZC_ETHNIC_GROUP zcHisp 
	ON pat1.ETHNIC_GROUP_C = zcHisp.ETHNIC_GROUP_C
	LEFT OUTER JOIN (
		SELECT 
			Race.Pat_ID,
			STRING_AGG ( Case
				When Race.patient_race_c in ('1') then '1' --white,
				when race.patient_race_c in ('2') then '2' --black aa,
				when race.patient_race_C in ('3') then '3' --Native,
				when race.patient_race_C in ('24') then '4' --Alaskan,
				when race.patient_race_C in ('25') then '6' --Multi,
				when race.patient_race_C in ('12','4','9','11','13','14','20','21') then '5' --Asian,
				when race.patient_race_C in ('8','7','6','19') then '7' --OtherUnk,
				when race.patient_race_C in ('15','10','16','17') then '8' --PacificIslander
				else '' end,'|') WITHIN GROUP (ORDER BY Race.LINE) PatRace 
		from PATIENT_RACE Race group by (Pat_ID) 
) PatRace on pat1.PAT_ID = PatRace.PAT_ID 
where 
PE.ENC_TYPE_C not in (50,3002,1200,120)
and
PE.DEPARTMENT_ID in ('110100502','110100602','110100202','110100402','110100702','110100302') --OR Locations
and
INPATIENT_DATA_ID is not null  --this should filter out everything that isn't an encounter such as document/call


/* 
	Additional insert statements for the more complex logic 
*/
--sop start
,case
when vcpp.benefit_plan_ID = 35229 then '03'  --sop wash take charge [pull beneid]
else when clarity_epp.rpt_grp_two in ('omap','dshs') then '02' --sop mcd OHP [pull grouper]
else when vcpp.payor_id in ('35221','35222','35223') then '12' --sop RH Program
when vcpp.payor_id = 35225 then '11'
when vcpp.payor_id = 50108 then '07'
else '04' --private ins
end ---[pull payor id]

--flomeasures
INSERT INTO #ORAhlersSubmit (
select
FloRec.INPATIENT_DATA_ID
,flomeas.FLO_MEAS_ID
,FloMeas.MEAS_VALUE
,case when flomeas.FLO_MEAS_ID in ('6638') then FloMeas.MEAS_VALUE else '' end [whatever this was]
,case when flomeas.FLO_MEAS_ID in ('6628') then FloMeas.MEAS_VALUE else '' end [bcm]
,case when flomeas.FLO_MEAS_ID in ('6630') then FloMeas.MEAS_VALUE else '' end [r4n]
,case when flomeas.FLO_MEAS_ID in ('3040107910') then FloMeas.MEAS_VALUE else '' end [substance]
,case when flomeas.FLO_MEAS_ID in ('6846') then FloMeas.MEAS_VALUE else '' end [faminv]
,case when flomeas.FLO_MEAS_ID in ('6849') then FloMeas.MEAS_VALUE else '' end [abstain]

from
IP_FLWSHT_REC FloRec 
Join
IP_FLWSHT_MEAS FloMeas
on flomeas.fsd_id = florec.FSD_ID
where flomeas.FLO_MEAS_ID in ('6638','6628','6630','3040107910','6846','6849')


(Select distinct --Pelvic 09
PAT_ENC_CSN_ID ,SUM(CASE when em_code_attribute = 'Pelvic' then 2 when em_code_attribute IN ('Adnexa', 'Uterus', 'Cervix', 'Urethra', 'Bladder', 'Ext') then 1 end) [Pelvic]
from (SELECT distinct pat_enc_csn_id, EM_Code_Attribute from EM_CODE_CALC
where EM_CODE_SECTION = 'Genitourinary-Female') gynfemale
Group by pat_enc_csn_id
Having SUM(CASE when em_code_attribute = 'Pelvic' then 2 when em_code_attribute IN ('Adnexa', 'Uterus', 'Cervix', 'Urethra', 'Bladder', 'Ext') then 1 end)>=2	) Pelvic on Pelvic.pat_enc_csn_id = Patenc.PAT_ENC_CSN_ID


(Select Distinct --MaleEx 
PAT_ENC_CSN_ID
, SUM(CASE when em_code_attribute = 'Penis' then 1 when em_code_attribute IN ('scrotum') then 1 end) [MaleExam]
from (SELECT distinct pat_enc_csn_id, EM_Code_Attribute from EM_CODE_CALC
where EM_CODE_SECTION = 'GENITOURINARY-MALE') MaleExam
Group by pat_enc_csn_id
Having sum (CASE when em_code_attribute = 'Penis' then 1 when em_code_attribute IN ('scrotum') then 1 end)>=2)Male on Male.pat_enc_csn_id = Patenc.pat_enc_csn_ID  --maleEx


(Select Distinct  --06 BreastExam
PAT_ENC_CSN_ID
, SUM(CASE when em_code_attribute = 'Insp' then 1 when em_code_attribute IN ('palp') then 1 end) [BreastExam]
from (SELECT distinct pat_enc_csn_id, EM_Code_Attribute from EM_CODE_CALC
where EM_CODE_SECTION = 'CHEST') BreastExam
Group by pat_enc_csn_id
Having sum (CASE when em_code_attribute = 'Insp' then 1 when em_code_attribute IN ('palp') then 1 end) >=2) BrEx on brex.pat_enc_csn_id = PatEnc.pat_enc_csn_ID  --06 BreastExam

--Begin SDE
INSERT INTO #ORAhlersSubmit (
select
CONTACT_SERIAL_NUM
,SMRTDTA_ELEM_DATA.ELEMENT_ID
,SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#183') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [EndContra]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#057') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [SafeRel]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#029') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [PapHPV16]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#044','PP#68','PP#073','PP#074','PP#075','PP#076','pp#086','pp#089') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [NutrActv]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#046','pp#047','PP#048','PP#049','pp#050','PP#052','pp#053') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [STIHIV]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#064','pp#069','PP#071','PP#072','pp#090') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [PreCon]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#004','pp#058','PP#060','PP#061','pp#062','PP#066') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [PregOp]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#094') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [Tobacco]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#055') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [infert]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#038') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [FAMeth]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#030','PP#032','PP#033') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [Steril]
,case when SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#034','PP#035','PP#036','PP#039','PP#040','PP#041','pp#083','pp#084') then SMRTDTA_ELEM_DESC.SMRTDTA_ELEM_DESC else '' end [Contra]
from

SMRTDTA_ELEM_DATA

join
smrtdta_elem_desc
on
smrtdta_elem_desc.element_id = SMRTDTA_ELEM_DATA.ELEMENT_ID
where SMRTDTA_ELEM_DESC.ELEMENT_ID in ('pp#057','pp#029','pp#044','PP#68','PP#073','PP#074','PP#075','PP#076','pp#086','pp#089','pp#046','pp#047','PP#048','PP#049','pp#050','PP#052','pp#053','pp#064','pp#069','PP#071','PP#072','pp#090','pp#004','pp#058','PP#060','PP#061','pp#062','PP#066','pp#034','PP#035','PP#036','PP#039','PP#040','PP#041','pp#083','pp#084','pp#038','pp#030','PP#032','PP#033','pp#055','pp#094','pp#183')

---end SDE






Create Table #RHProgINV --either or
--can we get CLP 3078 to know when is original ready during date range, or rebill/secondary
INSERT INTO #ORAhlersSubmit (

    POV  char(2) null --encountertype  from #RHProgInv
    ,last name char(20) null   from #RHProgInv
	,first name char(10) null from #RHProgInv
	,middle initial char(1) null from #RHProgInv
	,rh id  from #RHProgInv
	,ssn  char(9) null from #RHProgInv
	--,contra1 char(2) null from #RHProgInv
	--,supQ1 char(3) from #RHProgInv
	--,contrac2  char(2) null from #RHProgInv
	--,supQ2 char(3)  from #RHProgInv
	--,contra3 char(2) null from #RHProgInv
	--,supQ3 char(3) from #RHProgInv
	--,contra4  char(2) null from #RHProgInv
	--,supQ4  char(3) from #RHProgInv
	--,ins billed char(1) null  from #RHProgInv
	--,TPR char(2) from #RHProgInv
	--,other ins paid char(6) nullfrom #RHProgInv
	,Invoice NBR varchar (?)null,  from #RHProgInv
	--,supply1rate  char(6) null from #RHProgInv
	--,supply2rate  char(6) null from #RHProgInv
	--,supply3rate  char(6) null from #RHProgInv
	--,supply4rate char(6) null from #RHProgInv
	,conf special char (1)null  from #RHProgInv
	,dx1  char(7) null        from #RHProgInv
	,dx2  char(7) null from #RHProgInv
	,dx3  char(7) null from #RHProgInv
	,dx4 char(7) null  from #RHProgInv
	,dx5  char(7) null from #RHProgInv
	,dx6  char(7) null from #RHProgInv
	,InsPaid char(6) from #RHProgInv

INSERT INTO #RHProgINV

Select 
DISTINCT fol.INVOICE_NUMBER
,pat_enc.PAT_ENC_CSN_ID
,RHpATIENT.PAT_LAST_NAME
,RHpATIENT.PAT_FIRST_NAME
,LEFT (RHpATIENT.PAT_MIDDLE_NAME,1)[mi]
,REPLACE (cov.subscr_SSN,'-','')[SSN]
,cov.SUBSCR_NUM
,case when hxfo.MFO_CHANGED_YN = 'y' and fol.is_prim_claim_YN = 'y' then 'y' else '' end [Conf]
,Case 
WHEN clarity_EAP_OT.CPT_CODE  in('11981','11982','11983','58300','58301','99384','99385','99386','99394','99395','99396') THEN '13' -- high
WHEN clarity_EAP_OT.CPT_CODE  in('57170','99201','99202','99203','99204','99205','99213','99214','99215','99401','99402') THEN '12' -- med
WHEN clarity_EAP_OT.CPT_CODE  in 
('96372','99211','99212','99441','99442','99443' ) THEN '11' -- low	
else '' end [RHPOV]
,case when hxfo.MFO_CHANGED_YN = 'y' and fol.is_prim_claim_YN = 'y' then 'y' else '' end [Confidential]
,case
when pedx.line=1 then edg.CURRENT_ICD10_LIST else '' end DX1
,case
when pedx.line=2 then edg.CURRENT_ICD10_LIST else '' end DX2
,case
when pedx.line=3 then edg.CURRENT_ICD10_LIST else '' end DX3
,case
when pedx.line=4 then edg.CURRENT_ICD10_LIST else '' end DX4
,case
when pedx.line=5 then edg.CURRENT_ICD10_LIST else '' end DX5
,case
when pedx.line=6 then edg.CURRENT_ICD10_LIST else '' end DX6
---Replace(Dx1.ICD,'.','') Must remove punctuation and extend to fill somewhere
from PAT_ENC pat_enc
left outer join PATIENT RHPatient on RHPatient.EPIC_PAT_ID = pAT_ENC.PAT_ID
left outer join FOL_INFO FOL on  fol.PAT_ENC_CSN_ID=Pat_enc.PAT_ENC_CSN_ID
left outer join FILING_ORDER_HX hxfo on hxfo.CVG_ID = fol.COVERAGE_ID
left outer join coverage cov on cov.coverage_id = pat_enc.coverage_ID
left outer join clarity_UCL UCL on ucl.epT_CSN = pat_enc.PAT_ENC_CSN_ID --Charge CPT
left outer  Join CLARITY_EAP_OT on CLARITY_EAP_OT.PROC_ID = UCL.PROCEDURE_ID --CPT
left outer join PAT_ENC_DX pedx on pedx.pat_enc_CSN_ID = pat_enc.pat_enc_csn_ID
join clarity_EDG edg on edg.dx_ID = pedx.dx_id



----- CTPAP HX

UPDATE #ORAhlersSubmit

	SET 
	CtOrderDate = labs.CtOrderDate
	,PapOrderDate = labs.PapOrderDate
FROM ( 
	SELECT 
		pop.PAT_ENC_CSN_ID 
		,MAX(CASE WHEN eapOT.PROC_ID IN ('87110', '87270', '87320', '87490', '87491', '87492', '87810')
						AND pop.AgeAtEnc <= 24 THEN op.ORDERING_DATE ELSE NULL END) CtOrderDate
		,MAX(CASE WHEN eapOT.PROC_ID IN ('88141','88142')
						AND pop.AgeAtEnc >= 21 THEN op.ORDERING_DATE ELSE NULL END) PapOrderDate
	FROM #ORAhlersSubmit pop 
	INNER JOIN ORDER_PROC op 
		ON pop.PAT_ID = op.PAT_ID 
		AND op.ORDERING_DATE < pop.DOS 
	INNER JOIN ORDER_RESULTS ordres 
		ON op.ORDER_PROC_ID = ordres.ORDER_PROC_ID 
	INNER JOIN CLARITY_EAP_OT eapOT 
		ON op.PROC_ID = eapOT.PROC_ID 
	WHERE eapOT.CPT_CODE IN ('87110', '87270', '87320', '87490', '87491', '87492', '87810','88141','88142')
	GROUP BY pop.PAT_ENC_CSN_ID 
) labs 
WHERE labs.PAT_ENC_CSN_ID = #ORAhlersSubmit.PAT_ENC_CSN_ID 
--- Flowsheet counseling
UPDATE #ORAhlersSubmit
SET 
	PlanPreg = flos.PlanPreg
	,BegCM = flos.BegCM
	,ReasonNone = flos.ReasonNone
	,Substance = flos.Substance 
	,FamInv = flos.FamInv 
	,Abstain = flos.Abstain  
FROM ( 
	SELECT 
		INPATIENT_DATA_ID
		,MAX(CASE WHEN FLO_MEAS_ID = '6638' THEN MEAS_VALUE ELSE '' END) PlanPreg
		,MAX(CASE WHEN FLO_MEAS_ID = '6628' THEN MEAS_VALUE ELSE '' END) BegCM 
		,MAX(CASE WHEN FLO_MEAS_ID = '6630' THEN MEAS_VALUE ELSE '' END) ReasonNone
		,MAX(CASE WHEN FLO_MEAS_ID = '3040107910' THEN '06' ELSE '' END) Substance 
		,MAX(CASE WHEN FLO_MEAS_ID = '6846' THEN '17' ELSE '' END) FamInv 
		,MAX(CASE WHEN FLO_MEAS_ID = '6849' THEN '13' ELSE '' END) Abstain
	FROM ( 
		SELECT 
			rec.INPATIENT_DATA_ID 
			,meas.FLO_MEAS_ID
			,meas.MEAS_VALUE 
			,ROW_NUMBER() OVER (PARTITION BY rec.INPATIENT_DATA_ID ORDER BY meas.RECORDED_TIME DESC) RN 
		FROM IP_FLWSHT_REC rec 
		INNER JOIN #ORCVR pop 
			ON rec.INPATIENT_DATA_ID = pop.INPATIENT_DATA_ID
		INNER JOIN IP_FLWSHT_MEAS meas 
			ON rec.FSD_ID = meas.FSD_ID 
		WHERE meas.FLO_MEAS_ID IN ('6638','6628','6630','3040107910','6846','6849') 
			AND meas.MEAS_VALUE IS NOT NULL 
	) allFlos 
	WHERE RN = 1 -- most recent 
	GROUP BY INPATIENT_DATA_ID 
) flos 
WHERE flos.INPATIENT_DATA_ID = #ORAhlersSubmit.INPATIENT_DATA_ID