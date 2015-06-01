
/* *******************  Prepared by Saeed, 29/4/15, ********************/ 
/* *******************  updated by Saeed, 30/4/15, ********************/ 
/****************** to find the states of donations(gifts and payments) and interactions  without repetition******************/
/*****************************************************************************************/

IF OBJECT_ID('tempdb..#1') IS NOT NULL     --Remove dbo here 
    DROP TABLE #1 

-- payments
SELECT CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID, CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE 
                  ,REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
				 ,codes.REVENUETRANSACTIONTYPECODE, CODES.REVENUEAPPLICATIONCODE, CO.PRIMARYADDRESSCITY
            INTO #1
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT>0
and CONSTITUENTLOOKUPID <> '0'
and
((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 3)  -- Rec Gift payment
or (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 2)  -- Pledge Payment
or codes.REVENUETRANSACTIONTYPECODE = 1 --pledge header
or  codes.REVENUETRANSACTIONTYPECODE = 2  -- Rec gift
or codes.REVENUETRANSACTIONTYPECODE = 4)   -- Planned Gift



UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE REVENUETRANSACTIONTYPECODE = 0 and REVENUEAPPLICATIONCODE = 0

UPDATE #1
   SET [ACTION_TYPE] = 'RG_Payment'
 WHERE REVENUETRANSACTIONTYPECODE = 0 and REVENUEAPPLICATIONCODE = 3

UPDATE #1
   SET [ACTION_TYPE] = 'Pledge_Payment'
 WHERE REVENUETRANSACTIONTYPECODE = 0 and REVENUEAPPLICATIONCODE = 2

GO


-- to creat the tables in conversion mapping
IF OBJECT_ID('tempdb..saeed_const_transac_payment_states') IS NOT NULL     --Remove dbo here 
	drop table [ConversionMapping].[dbo].[saeed_const_transac_payment_states] 
SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY INTERACTION_DATE ) AS seq, *
into [ConversionMapping].[dbo].[saeed_const_transac_payment_states]
FROM #1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID

IF OBJECT_ID('tempdb..saeed_const_transac_payment_constituents') IS NOT NULL     --Remove dbo here 
	drop table [ConversionMapping].[dbo].[saeed_const_transac_payment_constituents] 
SELECT distinct CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
into [ConversionMapping].[dbo].[saeed_const_transac_payment_constituents]
from [ConversionMapping].[dbo].[saeed_const_transac_payment_states] 



--To test
select * from 
[ConversionMapping].[dbo].[saeed_const_transac_payment_states]  
where CONSTITUENTLOOKUPID='174572'
order by seq



--SELECT CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
--from [ConversionMapping].[dbo].[saeed_const_transac_payment_constituents]
--where CONSTITUENTLOOKUPID='174572'



------ To send it on local/ copy and run it on local machine --------------
---- the linked object: [KYDSPRDdw30]
IF OBJECT_ID('[workingDB].[dbo].[saeed_const_transac_payment_constituents]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_const_transac_payment_constituents]
SELECT *
into [workingDB].[dbo].[saeed_const_transac_interac_pure_constituents]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_const_transac_payment_constituents] 

IF OBJECT_ID('[workingDB].[dbo].[saeed_const_transac_payment_states]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_const_transac_payment_states]
SELECT *
into [workingDB].[dbo].[saeed_const_transac_payment_states]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_const_transac_payment_states] 