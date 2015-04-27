
/* *******************  Prepared by Saeed, 16/4/15, ********************/ 
/* *******************  updated by Saeed, 27/4/15, ********************/ 
/****************** to find the states of donations and interactions  ******************/
/*****************************************************************************************/

drop table #1

-- payments
SELECT CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID, CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE 
                  ,REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
				 ,codes.REVENUETRANSACTIONTYPECODE, CODES.REVENUEAPPLICATIONTYPECODE
            INTO #1
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 )
-- intractions
INSERT INTO #1 (INTERACTION_DATE,CONSTITUENTLOOKUPID,ACTION_TYPE,AMOUNT,APPLICATION_TYPE) 
SELECT CONVERT(DATE,FI.INTERACTIONDATE) AS INTERACTION_DATE,CO.CONSTITUENTLOOKUPID ,DI.INTERACTIONTYPE AS INTERACTION_TYPE 
    , NULL AS AMOUNT, NULL AS APPLICATION_TYPE 

    FROM BBDW.FACT_INTERACTION AS FI
            INNER JOIN BBDW.DIM_INTERACTION AS DI
                ON FI.INTERACTIONDIMID = DI.INTERACTIONDIMID
            INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                ON CO.CONSTITUENTDIMID = FI.CONSTITUENTDIMID
            INNER JOIN BBDW.DIM_FUNDRAISER AS FR
                ON FR.FUNDRAISERDIMID = FI.FUNDRAISERDIMID            


         
-- to creat the tables in conversion mapping

drop table [ConversionMapping].[dbo].[saeed_constituents_states] 
drop table [ConversionMapping].[dbo].[saeed_constituents] 

SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY INTERACTION_DATE ) AS Row, *
into [ConversionMapping].[dbo].[saeed_constituents_states]
FROM #1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID


SELECT distinct CONSTITUENTLOOKUPID 
into [ConversionMapping].[dbo].[saeed_constituents]
from [ConversionMapping].[dbo].[saeed_constituents_states] 
