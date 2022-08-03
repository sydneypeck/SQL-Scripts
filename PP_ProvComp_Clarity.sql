SELECT 
	ProviderID 
	,MAX(ProviderName) ProviderName 
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 10 AND 34 THEN 1 ELSE 0 END) Abortion_10d_4w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 35 AND 69 THEN 1 ELSE 0 END) Abortion_5w_9w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 70 AND 83 THEN 1 ELSE 0 END) Abortion_10w_11w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 84 AND 97 THEN 1 ELSE 0 END) Abortion_12w_13w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 98 AND 111 THEN 1 ELSE 0 END) Abortion_14w_15w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 112 AND 125 THEN 1 ELSE 0 END) Abortion_15w_17w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 126 AND 139 THEN 1 ELSE 0 END) Abortion_18w_19w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE BETWEEN 140 AND 153 THEN 1 ELSE 0 END) Abortion_20w_21w6d
	,SUM(CASE WHEN Elective = 1 AND GESTATIONAL_AGE >= 154 THEN 1 ELSE 0 END) Abortion_22w_23w6d
	,SUM(PreAbortionUS) PreAbortionUltrasound 
	,SUM(LaminariaAndDilapan) LaminariaAndDilapan
	,SUM(DandCMissedAb) DandCMissedAB
	,COUNT(distinct MedicationAbortionPatDOS) MedicationAbortion
	,SUM(MedicationAbortionRescue) ResuctionMABRescue
	,SUM(NonViablePOC) NonViablePOC
	,SUM(NonViablePOCHydatidiformMole) NonViablePOCHydatidiformMole
	,SUM(Abortion) + SUM(PreAbortionUS) + SUM(LaminariaAndDilapan) + COUNT(distinct MedicationAbortionPatDOS) TotalProcedures 
FROM ( 
	SELECT 
		op.ORDER_PROC_ID 
		,pat.PAT_NAME 
		,op.PROC_ID 
		,eap.PROC_NAME 
		,pe.PAT_ENC_CSN_ID 
		,pe.PAT_ID 
		,pe.CONTACT_DATE DOS 
		,pe.VISIT_PROV_ID ProviderID  
		,ser.PROV_NAME ProviderName
		,pe.DEPARTMENT_ID 
		,pat.PAT_MRN_ID
		,280 - DATEDIFF(day, pe.CONTACT_DATE, csnEpLink.OB_WRK_EDD_DT) GESTATIONAL_AGE 
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'Elective' AND csnEpLink.OB_WRK_EDD_DT IS NOT NULL THEN ordsdes.Abortion 
			WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType <> 'Elective' THEN ordsdes.Abortion 
			ELSE 0 END Abortion 
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'Elective' THEN 1 ELSE 0 END Elective 
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'D&C' THEN 1 ELSE 0 END DandCMissedAb
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'MABRescue' THEN 1 ELSE 0 END MedicationAbortionRescue
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'NonViablePOC' THEN 1 ELSE 0 END NonViablePOC
		,CASE WHEN op.PROC_ID = 123952 AND ordsdes.AbortionType = 'NonViablePOCMole' THEN 1 ELSE 0 END NonViablePOCHydatidiformMole
		,CASE WHEN op.PROC_ID = 123953 THEN ordsdes.LaminariaAndDilapan ELSE 0 END LaminariaAndDilapan
		,CASE WHEN ressde.RES_ID IS NOT NULL THEN 1 ELSE 0 END PreAbortionUS 
		,CASE WHEN op.PROC_ID = 123939 THEN CONCAT(pat.PAT_ID,CAST(pe.CONTACT_DATE as varchar)) END MedicationAbortionPatDOS /* to eliminate potential duplicates for same Pat/DOS combo */
	FROM ORDER_PROC op 
	INNER JOIN PAT_ENC pe 
		ON op.PAT_ENC_CSN_ID = pe.PAT_ENC_CSN_ID 
	INNER JOIN CLARITY_DEP dep 
		ON pe.DEPARTMENT_ID = dep.DEPARTMENT_ID
	INNER JOIN VALID_PATIENT vpat 
		ON op.PAT_ID = vpat.PAT_ID 
	INNER JOIN PATIENT pat 
		ON pe.PAT_ID = pat.PAT_ID 
	/* 
		Encounter can only be linked to at most 2 episodes, and one must have a resolve date of the contact date of the encounter.
		We want the one that was NOT resolved on the day of the encounter.
	*/
	LEFT OUTER JOIN ( 
		SELECT 
			pe.PAT_ENC_CSN_ID 
			,ep.EPISODE_ID 
			,ep.OB_WRK_EDD_DT
		FROM EPISODE_LINK eplink
		INNER JOIN EPISODE ep 
			ON eplink.EPISODE_ID = ep.EPISODE_ID 
			AND ep.SUM_BLK_TYPE_ID = 2 
			AND eplink.EPI_STATUS_C <> 3
		INNER JOIN PAT_ENC pe 
			ON eplink.PAT_ENC_CSN_ID = pe.PAT_ENC_CSN_ID 
			AND (ep.END_DATE IS NULL OR ep.END_DATE <> pe.CONTACT_DATE) 
	) csnEpLink ON pe.PAT_ENC_CSN_ID = csnEpLink.PAT_ENC_CSN_ID
	INNER JOIN CLARITY_SER ser 
		ON pe.VISIT_PROV_ID = ser.PROV_ID 
	LEFT OUTER JOIN CLARITY_EAP eap 
		ON op.PROC_ID = eap.PROC_ID 
	LEFT OUTER JOIN ( 
		SELECT 
			ORDER_PROC_ID 
			,MAX(LaminariaAndDilapan) LaminariaAndDilapan
			,CASE WHEN MAX(MedicationAbortionRescue) = 1 THEN 'MABRescue'
				WHEN MAX(DandCMissedAb) = 1 THEN 'D&C'
				WHEN MAX(NonViablePOC) = 1 THEN 'NonViablePOC'
				WHEN MAX(NonViablePOCHydatidiformMole) = 1 THEN 'NonViablePOCMole'
				WHEN MAX(Elective) = 1 THEN 'Elective'
				ELSE NULL END AbortionType 
			,MAX(Abortion) Abortion
		FROM ( 
			SELECT 
				sde.RECORD_ID_NUMERIC ORDER_PROC_ID 
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#91396' AND sdeval.SMRTDTA_ELEM_VALUE = '1' THEN 1
					WHEN sde.ELEMENT_ID = 'EPIC#31000208588' AND sdeval.SMRTDTA_ELEM_VALUE = '1' THEN 1 
					ELSE 0 END LaminariaAndDilapan 
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE = 'EPIC#31000198707' THEN 1 ELSE 0 END Elective 
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE = 'EPIC#31000135532' THEN 1 ELSE 0 END DandCMissedAb 
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE IN ('EPIC#31000198716','EPIC#31000198717','EPIC#31000198719') THEN 1 ELSE 0 END MedicationAbortionRescue
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE = 'EPIC#31000198704' THEN 1 ELSE 0 END NonViablePOC
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE = 'EPIC#31000198714' THEN 1 ELSE 0 END NonViablePOCHydatidiformMole
				,CASE WHEN sde.ELEMENT_ID = 'EPIC#31000198702' AND sdeval.SMRTDTA_ELEM_VALUE IS NOT NULL THEN 1 ELSE 0 END Abortion 
			FROM SMRTDTA_ELEM_DATA sde 
			INNER JOIN SMRTDTA_ELEM_VALUE sdeval 
				ON sde.HLV_ID = sdeval.HLV_ID
			WHERE sde.ELEMENT_ID IN ('EPIC#31000198702','EPIC#91396','EPIC#31000208588')
				AND sde.CONTEXT_NAME = 'ORDER'
		) orderSDEs 
		GROUP BY ORDER_PROC_ID 
	) ordsdes 
	ON ordsdes.ORDER_PROC_ID = op.ORDER_PROC_ID
	LEFT OUTER JOIN ORDER_PROC_2 op2 
		ON op.ORDER_PROC_ID = op2.ORDER_PROC_ID
	LEFT OUTER JOIN (
		SELECT 
			sdedata.RECORD_ID_NUMERIC RES_ID  
		FROM SMRTDTA_ELEM_DATA sdedata 
		INNER JOIN SMRTDTA_ELEM_VALUE sdeval 
			ON sdedata.HLV_ID = sdeval.HLV_ID
		WHERE sdedata.ELEMENT_ID = 'PP#649'
			AND sdedata.CONTEXT_NAME = 'RESULT'
			AND sdeval.SMRTDTA_ELEM_VALUE = 'pre-abortion'
		GROUP BY sdedata.RECORD_ID_NUMERIC
	) ressde 
	ON op2.OB_US_MOM_RES_ID = ressde.RES_ID
		AND eap.PROC_CAT_ID IN ( '107', '14' )
	WHERE 
		/* 123953 - Cervical dilators, 123952 - Uterine suction, 123939 - Medication abortion */
		(op.PROC_ID IN ( 123953, 123952, 123939 ) 
			OR 
			/* 107 - IMG OB US PROCEDURES , 14 - IMG US PROCEDURES. Only count ultrasounds where study status is 99-Final */
			(eap.PROC_CAT_ID IN ( '107', '14' ) AND op.RADIOLOGY_STATUS_C = 99)) 
		AND pe.CONTACT_DATE BETWEEN '6/1/2021' AND '6/30/2021' 
		AND dep.SERV_AREA_ID = 10 /* CHN */
		AND vpat.IS_VALID_PAT_YN = 'Y' 
		AND op.ORDER_STATUS_C = 5 /* only include completed procedure orders */
) allprocedures 
GROUP BY ProviderId 


