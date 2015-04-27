/* *******************  Prepared by Saeed, 24/4/15, ********************/ 
/****************** to find the apeals of donations  ******************/
/*****************************************************************************************/


drop table #1

-- payments
Select CONSTITUENT.CONSTITUENTLOOKUPID,
CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE) AS INTERACTION_DATE,
CODES.REVENUETRANSACTIONTYPE AS ACTION_TYPE, 
 REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT AS AMOUNT,
BUSINESS.BUSINESSUNIT, appeal.APPEALCATEGORY,
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
where ((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 1 or  codes.REVENUETRANSACTIONTYPECODE = 2 or codes.REVENUETRANSACTIONTYPECODE = 4 ))
order by CONSTITUENT.CONSTITUENTLOOKUPID,INTERACTION_DATE
       

UPDATE #1
   SET [ACTION_TYPE] = 'Donation'
 WHERE [ACTION_TYPE] = 'Payment'
GO

-- to find Inactive users= All-Active
drop table #inactive_users
select distinct CONSTITUENTLOOKUPID,PRIMARYADDRESSCITY, '2015-01-01' as INTERACTION_DATE, 
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
(CONSTITUENTLOOKUPID,  INTERACTION_DATE, ACTION_TYPE,BUSINESSUNIT, APPEALCATEGORY, PRIMARYADDRESSCITY)
select CONSTITUENTLOOKUPID,  INTERACTION_DATE, ACTION_TYPE,  BUSINESSUNIT, APPEALCATEGORY,  PRIMARYADDRESSCITY  from #inactive_users

         


-- to creat the tables in conversion mapping

drop table [ConversionMapping].[dbo].[saeed_const_BU_appeal_states] 
SELECT   ROW_NUMBER() OVER(PARTITION BY constituentlookupid ORDER BY INTERACTION_DATE ) AS seq, *
into [ConversionMapping].[dbo].[saeed_const_BU_appeal_states]
FROM #1 
        WHERE CONSTITUENTLOOKUPID <> '0'
        ORDER BY CONSTITUENTLOOKUPID


drop table [ConversionMapping].[dbo].[saeed_const_BU_appeal_constituents] 
SELECT distinct CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
into [ConversionMapping].[dbo].[saeed_const_BU_appeal_constituents]
from [ConversionMapping].[dbo].[saeed_const_BU_appeal_states] 



--To test

select * from [ConversionMapping].[dbo].[saeed_const_BU_appeal_states]  
where CONSTITUENTLOOKUPID='174572'



SELECT CONSTITUENTLOOKUPID, PRIMARYADDRESSCITY
from [ConversionMapping].[dbo].[saeed_const_BU_appeal_constituents] 
where CONSTITUENTLOOKUPID='174572'