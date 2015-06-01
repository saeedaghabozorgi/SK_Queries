
/* *******************  Prepared by Saeed, 29/4/15, ********************/ 
/* *******************  updated by Saeed, 30/4/15, ********************/ 
/****************** to find the states of donations and interactions  without repetition******************/
/*****************************************************************************************/

IF OBJECT_ID('tempdb..#1') IS NOT NULL     --Remove dbo here 
    DROP TABLE #1 

-- payments
SELECT CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID, CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE 
                  ,REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
				 ,codes.REVENUETRANSACTIONTYPECODE, CODES.REVENUEAPPLICATIONTYPECODE, CO.PRIMARYADDRESSCITY
            INTO #1
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT>0
and CONSTITUENTLOOKUPID <> '0'
and ((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 ))

-- intractions
INSERT INTO #1 (INTERACTION_DATE,CONSTITUENTLOOKUPID,ACTION_TYPE,AMOUNT,APPLICATION_TYPE,PRIMARYADDRESSCITY) 
SELECT CONVERT(DATE,FI.INTERACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID ,DI.INTERACTIONTYPE AS INTERACTION_TYPE 
    , NULL AS AMOUNT, NULL AS APPLICATION_TYPE, CO.PRIMARYADDRESSCITY
    FROM BBDW.FACT_INTERACTION AS FI
            INNER JOIN BBDW.DIM_INTERACTION AS DI
                ON FI.INTERACTIONDIMID = DI.INTERACTIONDIMID
            INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                ON CO.CONSTITUENTDIMID = FI.CONSTITUENTDIMID
            INNER JOIN BBDW.DIM_FUNDRAISER AS FR
                ON FR.FUNDRAISERDIMID = FI.FUNDRAISERDIMID     
				where ( DI.INTERACTIONTYPE <>'No Interaction Type' and DI.INTERACTIONTYPE <>'Task/Other')
				and CONVERT(DATE,FI.INTERACTIONDATE)> '2015-06-01'

UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE [ACTION_TYPE] = 'Payment'





-- to find Inactive users= All-Active
IF OBJECT_ID('tempdb..#inactive_users') IS NOT NULL     --Remove dbo here 
    DROP TABLE #inactive_users

select distinct CONSTITUENTLOOKUPID,PRIMARYADDRESSCITY, '2015-06-01' as INTERACTION_DATE, 
'Inactive' AS ACTION_TYPE                 ---- All Users
  INTO #inactive_users
from #1 where CONSTITUENTLOOKUPID not in (
SELECT CO.CONSTITUENTLOOKUPID --- Active users
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
		where codes.REVENUETRANSACTIONTYPECODE = 4 
		or  CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)> '2015-01-01'
		group by CONSTITUENTLOOKUPID)

---- Insert Inactive users records into #1
INSERT INTO #1
(CONSTITUENTLOOKUPID,  INTERACTION_DATE, ACTION_TYPE,  PRIMARYADDRESSCITY)
select CONSTITUENTLOOKUPID,  INTERACTION_DATE, ACTION_TYPE,    PRIMARYADDRESSCITY  from #inactive_users

  
  
  
----------------------- To add row number
IF OBJECT_ID('tempdb..#tmp1') IS NOT NULL     --Remove dbo here 
    DROP TABLE #tmp1
select ROW_NUMBER() OVER( ORDER BY CONSTITUENTLOOKUPID,INTERACTION_DATE ) AS rown,*
into #tmp1
from #1
order by CONSTITUENTLOOKUPID,INTERACTION_DATE

IF OBJECT_ID('tempdb..#2') IS NOT NULL     --Remove dbo here 
    DROP TABLE #2
SELECT 
 (ROW_NUMBER() OVER( ORDER BY CONSTITUENTLOOKUPID,rown )) -
 (ROW_NUMBER() OVER( PARTITION BY CONSTITUENTLOOKUPID,ACTION_TYPE ORDER BY CONSTITUENTLOOKUPID,rown )) as grp,
*
into #2
FROM #tmp1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID
--select * from #2 where CONSTITUENTLOOKUPID='1000043' order by interaction_date
------------------------ To group by only rows which are sequencial
IF OBJECT_ID('tempdb..#3') IS NOT NULL     --Remove dbo here 
    DROP TABLE #3;


With T as ( 

 select * from #2

) SELECT CONSTITUENTLOOKUPID, ACTION_TYPE, COUNT(*) act_count,grp,min(rown) as row_num, PRIMARYADDRESSCITY
into #3
FROM   T
GROUP  BY CONSTITUENTLOOKUPID,ACTION_TYPE, grp , PRIMARYADDRESSCITY
ORDER BY CONSTITUENTLOOKUPID,min(rown)


--select * from #3 where CONSTITUENTLOOKUPID='1000043' order by CONSTITUENTLOOKUPID,grp 
  
        
         
------------------------ to creat the tables in conversion mapping

IF OBJECT_ID('[ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states]




SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY row_num ) AS seq, *
into [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states]
FROM #3 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID

IF OBJECT_ID('[ConversionMapping].[dbo].[saeed_const_transac_interac_pure_constituents]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_constituents]

SELECT distinct CONSTITUENTLOOKUPID , PRIMARYADDRESSCITY
into [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_constituents]
from [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states]  


--To test

--select * from 
--[ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states]  
--where CONSTITUENTLOOKUPID='174572'
--order by row_num



--SELECT CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
--from [ConversionMapping].[dbo].[saeed_const_transac_interac_pure_constituents] 
--where CONSTITUENTLOOKUPID='174572'



------ To run on local --------------
---- the linked object: [KYDSPRDdw30]
IF OBJECT_ID('[workingDB].[dbo].[saeed_const_transac_interac_pure_constituents]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_const_transac_interac_pure_constituents]
SELECT *
into [workingDB].[dbo].[saeed_const_transac_interac_pure_constituents]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_const_transac_interac_pure_constituents] 

IF OBJECT_ID('[workingDB].[dbo].[saeed_const_transac_interac_pure_states]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_const_transac_interac_pure_states]
SELECT *
into [workingDB].[dbo].[saeed_const_transac_interac_pure_states]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_const_transac_interac_pure_states] 