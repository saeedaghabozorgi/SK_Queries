/* *******************  Prepared by Saeed, 11/05/15, ********************/ 
/****************** to find the Trans(payments),BU,apeals,Interac, of donations  ******************/
/*****************************************************************************************/


drop table #1

-- ALL
Select CONSTITUENT.CONSTITUENTLOOKUPID,
CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS ACTION_DATE,
CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE, 
BUSINESS.BUSINESSUNIT AS BUSINESSUNIT, 
appeal.APPEALCATEGORY AS APPEALCATEGORY, 
REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT,
codes.REVENUETRANSACTIONTYPECODE,CODES.REVENUEAPPLICATIONCODE, CONSTITUENT.PRIMARYADDRESSCITY
INTO #1
FROM [ECSKF_RPT_BBDW].[BBDW].[DIM_APPEALBUSINESSUNIT_EXT] AS BUSINESS 
                  INNER JOIN [ECSKF_RPT_BBDW].[BBDW].[DIM_APPEAL] AS APPEAL
                        ON BUSINESS.[APPEALDIMID] = APPEAL.[APPEALDIMID]
                  INNER JOIN [ECSKF_RPT_BBDW].[BBDW]. [FACT_FINANCIALTRANSACTIONLINEITEM] AS REVENUE 
                        ON APPEAL.[APPEALDIMID] = REVENUE.[APPEALDIMID] 
                  INNER JOIN [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] AS CONSTITUENT     
                        ON REVENUE.[CONSTITUENTDIMID] = CONSTITUENT.[CONSTITUENTDIMID]
                  INNER JOIN [ECSKF_RPT_BBDW].[BBDW].[DIM_REVENUECODE] AS CODES
                        ON CODES.[REVENUECODEDIMID] = REVENUE.[REVENUECODEDIMID]
where REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT>0
and CONSTITUENTLOOKUPID <> '0'
and ((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 ))
and CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)>'2005-01-01'
order by CONSTITUENT.CONSTITUENTLOOKUPID,ACTION_DATE



UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE [ACTION_TYPE] = 'Payment'
GO 

-- intractions
INSERT INTO #1 (ACTION_DATE,CONSTITUENTLOOKUPID,ACTION_TYPE,BUSINESSUNIT,APPEALCATEGORY,PRIMARYADDRESSCITY) 
SELECT CONVERT(DATE,FI.INTERACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID ,DI.INTERACTIONTYPE AS INTERACTION_TYPE,DI.INTERACTIONTYPE,DI.INTERACTIONTYPE, CO.PRIMARYADDRESSCITY
    FROM BBDW.FACT_INTERACTION AS FI
            INNER JOIN BBDW.DIM_INTERACTION AS DI
                ON FI.INTERACTIONDIMID = DI.INTERACTIONDIMID
            INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                ON CO.CONSTITUENTDIMID = FI.CONSTITUENTDIMID
            INNER JOIN BBDW.DIM_FUNDRAISER AS FR
                ON FR.FUNDRAISERDIMID = FI.FUNDRAISERDIMID     
				where ( DI.INTERACTIONTYPE <>'No Interaction Type' and DI.INTERACTIONTYPE <>'Task/Other')
				and CONVERT(DATE,FI.INTERACTIONDATE)< '2015-06-01'   
				and CONVERT(DATE,FI.INTERACTIONDATE)< '2005-01-01'  

-- to find Inactive users= All-Active
IF OBJECT_ID('tempdb..#inactive_users') IS NOT NULL     --Remove dbo here 
    DROP TABLE #inactive_users
select distinct CONSTITUENTLOOKUPID,PRIMARYADDRESSCITY, '2015-06-01' as ACTION_DATE, 
'Inactive' AS ACTION_TYPE, 'Inactive' AS BUSINESSUNIT, 'Inactive' AS APPEALCATEGORY                 ---- All Users
  INTO #inactive_users
from #1 where CONSTITUENTLOOKUPID not in (
SELECT CO.CONSTITUENTLOOKUPID --- Active users
FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
INNER JOIN BBDW.DIM_CONSTITUENT AS CO
    ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
INNER JOIN BBDW.DIM_REVENUECODE AS CODES
    ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where codes.REVENUETRANSACTIONTYPECODE = 4 or  (codes.REVENUETRANSACTIONTYPECODE = 0 and CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)> '2015-01-01')
group by CONSTITUENTLOOKUPID)

---- Insert Inactive users records into #1
INSERT INTO #1
(CONSTITUENTLOOKUPID,  ACTION_DATE, ACTION_TYPE,BUSINESSUNIT, APPEALCATEGORY, PRIMARYADDRESSCITY)
select CONSTITUENTLOOKUPID,  ACTION_DATE, ACTION_TYPE,  BUSINESSUNIT, APPEALCATEGORY,  PRIMARYADDRESSCITY  
from #inactive_users
 


------------------------ to creat the tables in conversion mapping

IF OBJECT_ID('[ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]

SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY ACTION_DATE ) AS seq, *
into [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]
FROM #1 
WHERE CONSTITUENTLOOKUPID <> '0'
ORDER BY CONSTITUENTLOOKUPID

IF OBJECT_ID('[ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]

SELECT distinct CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
into [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]
from [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states] 



--To test
select * from [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]  
where CONSTITUENTLOOKUPID='174572'



SELECT CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
from [ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents] 
where CONSTITUENTLOOKUPID='174572'


------ To run on local --------------
---- the linked object: [KYDSPRDdw30]


IF OBJECT_ID('[workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]
SELECT *
into [workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_states] 


IF OBJECT_ID('[workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]
SELECT *
into [workingDB].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_Const_Transac_Interaction_BU_Appeal_constituents] 