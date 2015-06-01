WITH CTE
AS
(
      SELECT LEFT(CANADA.PostalCode,3) + ' ' + RIGHT(CANADA.PostalCode,3) AS POST_CODE, CANADA.Latitude, CANADA.Longitude
                        , ROW_NUMBER() OVER (PARTITION BY LEFT(CANADA.PostalCode,3) + ' ' + RIGHT(CANADA.PostalCode,3) ORDER BY CANADA.Latitude ) AS FIRST_ROW
                  FROM [ConversionMapping].dbo.[CanData] AS CANADA 
) SELECT POST_CODE,     Latitude,Longitude
      INTO #CAN_DATA    
      FROM  CTE
      WHERE       FIRST_ROW = 1;

select * 
into [ConversionMapping].[dbo].[saeed_cons_spatial]
from BBDW.DIM_CONSTITUENT AS CO
left outer join #CAN_DATA
on CO.PRIMARYADDRESSPOSTCODE=#CAN_DATA.POST_CODE

------ To send it on local/ copy and run it on local machine --------------
---- the linked object: [KYDSPRDdw30]
IF OBJECT_ID('[workingDB].[dbo].[saeed_cons_spatial]') IS NOT NULL     --Remove dbo here 
    DROP TABLE [workingDB].[dbo].[saeed_cons_spatial]
SELECT *
into [workingDB].[dbo].[saeed_cons_spatial]
from [KYDSPRDdw30].[ConversionMapping].[dbo].[saeed_cons_spatial] 


select top 100 constituentlookupid,post_code,latitude, longitude 
from [saeed_cons_spatial] 
where post_code is not null
