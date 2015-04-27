/* *******************  Prepared by Saee, 16/4/15, 
to find the states of donations without interactions  *****************
***************************************************************************************
*/


drop table #1

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
where (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 )
       

UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE [ACTION_TYPE] = 'Payment'
GO

         
-- to creat the tables in conversion mapping

drop table [ConversionMapping].[dbo].[saeed_donation_states] 
SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY INTERACTION_DATE ) AS seq, *
into [ConversionMapping].[dbo].[saeed_donation_states]
FROM #1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID


drop table [ConversionMapping].[dbo].[saeed_donation_states_constituents] 
SELECT distinct CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
into [ConversionMapping].[dbo].[saeed_donation_states_constituents]
from [ConversionMapping].[dbo].[saeed_donation_states] 



--To test

select * from [ConversionMapping].[dbo].[saeed_donation_states]  
where CONSTITUENTLOOKUPID='174572'

SELECT CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
from [ConversionMapping].[dbo].[saeed_donation_states_constituents] 
where CONSTITUENTLOOKUPID='174572'