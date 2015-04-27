/* *******************  Prepared by Saee, 22/4/15, 
to find the states of sequential donations without repeat paymnets,..*****************
***************************************************************************************
*/

--sample constituent lookup id =174572

drop table #1


-- payments
SELECT 
ROW_NUMBER() OVER( ORDER BY CONSTITUENTLOOKUPID,FINANCIALTRANSACTIONDATE ) AS rown,
CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID, CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE 
                  ,REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
				 ,codes.REVENUETRANSACTIONTYPECODE, CODES.REVENUEAPPLICATIONTYPECODE
    INTO #1
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where ((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) 
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 ))
--and CONSTITUENTLOOKUPID='8-12085473'
order by CONSTITUENTLOOKUPID,INTERACTION_DATE


UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE [ACTION_TYPE] = 'Payment'
GO


----------------------- To add row number
drop table #2
SELECT 
 (ROW_NUMBER() OVER( ORDER BY CONSTITUENTLOOKUPID,rown )) -
 (ROW_NUMBER() OVER( PARTITION BY CONSTITUENTLOOKUPID,ACTION_TYPE ORDER BY CONSTITUENTLOOKUPID,rown )) as grp,
*
into #2
FROM #1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID
--select * from #2 where CONSTITUENTLOOKUPID='1000043'
------------------------ To group by only rows which are sequencial
drop table #3
With T as ( 

 select * from #2

) SELECT CONSTITUENTLOOKUPID,ACTION_TYPE, COUNT(*) act_count,grp,min(rown) as row_num
into #3
FROM   T
GROUP  BY CONSTITUENTLOOKUPID,ACTION_TYPE, grp 
ORDER BY CONSTITUENTLOOKUPID,min(rown)


select * from #3 order by CONSTITUENTLOOKUPID,grp
-------------------- To add seq number to dataset and make the database

drop table [ConversionMapping].[dbo].[saeed_donation_states_pure] 
drop table [ConversionMapping].[dbo].[saeed_donation_states_pure_constituents] 

SELECT 
ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY row_num ) AS seq, *
into [ConversionMapping].[dbo].[saeed_donation_states_pure]
FROM #3 
ORDER BY CONSTITUENTLOOKUPID

------------------- To aggregate and  make the constituent table
SELECT distinct CONSTITUENTLOOKUPID 
into [ConversionMapping].[dbo].[saeed_donation_states_pure_constituents]
from [ConversionMapping].[dbo].[saeed_donation_states_pure] 


-------------------- To test
select distinct ACTION_TYPE from [ConversionMapping].[dbo].[saeed_donation_states_pure] 