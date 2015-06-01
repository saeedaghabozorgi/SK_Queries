

/********** Fund raiser revenue for various years ********************/

drop table [ConversionMapping].dbo.saeed_FR2009;

WITH INTERACTION_COUNTS AS 
(
	SELECT F.FUNDRAISERDIMID
	, (sum(case when DI.InteractionType='Phone' then 1 else 0 end)+sum(case when DI.InteractionType='Email' then 1 else 0 end)+sum(case when DI.InteractionType='In Person' then 1 else 0 end) ) AS TOTALINTERACTIONCOUNT
	
	,sum(case when DI.InteractionType='Phone' then 1 else 0 end) as INT_Phone
	,sum(case when DI.InteractionType='Email' then 1 else 0 end) as INT_Email
	,sum(case when DI.InteractionType='In Person' then 1 else 0 end) as INT_InPerson
	
	--,sum(case when DI.InteractionType='Mail' then 1 else 0 end) as INT_Mail
	--,sum(case when DI.InteractionType='Task/Other' then 1 else 0 end) as INT_Task
	--,sum(case when DI.InteractionType='No Interaction Type' then 1 else 0 end) as INT_NO
		  FROM  BBDW.DIM_FUNDRAISER AS F
			INNER JOIN BBDW.FACT_INTERACTION AS I
					  ON  F.FUNDRAISERDIMID = I.FUNDRAISERDIMID 
			INNER JOIN BBDW.DIM_CONSTITUENT C
					  ON I.CONSTITUENTDIMID = C.CONSTITUENTDIMID
			inner Join BBDW.DIM_INTERACTION DI
					on DI.INTERACTIONDIMID=I.INTERACTIONDIMID
		  GROUP BY F.FUNDRAISERDIMID  
),





 FR_CO AS 
(
	SELECT F.FUNDRAISERDIMID
	, count(C.CONSTITUENTDIMID) AS CONSTITUENT_COUNT
	, sum(case when c.ISACTIVE=1 then 1 else 0 end) AS CONSTITUENT_ACTIVE
	
		  FROM  BBDW.DIM_FUNDRAISER AS F
			INNER JOIN BBDW.FACT_INTERACTION AS I
					  ON  F.FUNDRAISERDIMID = I.FUNDRAISERDIMID 
				INNER JOIN BBDW.DIM_CONSTITUENT C
					  ON I.CONSTITUENTDIMID = C.CONSTITUENTDIMID
		--  where F.FUNDRAISERDIMID=592146
		  GROUP BY F.FUNDRAISERDIMID 

),



FUNDRAISER AS
(
Select  FUNDRAISERDIMID, FULLNAME, ISACTIVE,ISACTIVEFUNDRAISER,ISACTIVESTAFF, TOTALFUNDRAISERREVENUECOUNT,TOTALFUNDRAISERREVENUEAMOUNT from BBDW.DIM_FUNDRAISER
),

FUNDRAISERYEAR AS
(
select f.fundraiserdimid,   (( case when DATEPART(yy,Max(i.INTERACTIONDATE)) > DATEPART(YY, GETDATE()) then DATEPART(YY, GETDATE()) else DATEPART(yy,Max(i.INTERACTIONDATE))end) - datepart(yy,MIN(i.INTERACTIONDATE))) as experience
      from BBDW.DIM_FUNDRAISER as f
            inner join BBDW.FACT_INTERACTION as i
                  on f.FUNDRAISERDIMID = i.FUNDRAISERDIMID
      group by  f.fundraiserdimid   ),

REVENUE_ALL AS
(
SELECT F.FUNDRAISERDIMID,
SUM(R.FINANCIALTRANSACTIONLINEITEMAMOUNT) as REVENUE_AMOUNT,
sum(case when AB.businessunit='Communications' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_Communications,
sum(case when AB.businessunit='Corporate Partnerships' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_CP,
sum(case when AB.businessunit='Direct Marketing' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_DM,
sum(case when AB.businessunit='Events' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_Events,
sum(case when AB.businessunit='Healthy Kids International' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_HKI,
sum(case when AB.businessunit='Major Gifts' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_MG,
sum(case when AB.businessunit='SickKids Charitable Giving Fund' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_CGF,
sum(case when AB.businessunit='SKF' then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as BU_SKF,

sum(case when CODES.[REVENUETRANSACTIONTYPECODE]=0 and CODES.[REVENUEAPPLICATIONCODE]=0 then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as REV_DONATION,
sum(case when CODES.[REVENUETRANSACTIONTYPECODE]=1 then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as REV_PLEDGE,
sum(case when CODES.[REVENUETRANSACTIONTYPECODE]=0 and CODES.[REVENUEAPPLICATIONCODE]=3 then R.FINANCIALTRANSACTIONLINEITEMAMOUNT else 0 end) as REV_RECG

                             FROM BBDW.DIM_FUNDRAISER AS F
							 Left outer JOIN [BBDW].[FACT_REVENUEFUNDRAISER] RF
								on RF.FUNDRAISERDIMID = F.FUNDRAISERDIMID
  							left JOIN 	  BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS R
								on R.[FINANCIALTRANSACTIONLINEITEMFACTID] = RF.[FINANCIALTRANSACTIONLINEITEMFACTID]
							INNER JOIN [ECSKF_RPT_BBDW].[BBDW].[DIM_REVENUECODE] AS CODES
                              ON CODES.[REVENUECODEDIMID] =   R.[REVENUECODEDIMID]
							 inner join BBDW.DIM_APPEAL as AP
								on AP.APPEALDIMID=R.APPEALDIMID
							inner join BBDW.DIM_APPEALBUSINESSUNIT_EXT as AB
								on AB.APPEALDIMID=AP.APPEALDIMID
							WHERE (CODES.[REVENUETRANSACTIONTYPECODE] = 1 -- PLEDGE HEADER
                              OR (CODES.[REVENUEAPPLICATIONCODE] <> 2 AND CODES.[REVENUEAPPLICATIONCODE] <> 6 AND CODES.[REVENUETRANSACTIONTYPECODE] = 0))-- PAYMENTS EXCLUDING PLEDGE PAYMENTS
							  and year(R.FINANCIALTRANSACTIONDATE)=2009
							--  where F.FUNDRAISERDIMID='487611'
                              group by F.FUNDRAISERDIMID  )






select 
FUNDRAISER.FUNDRAISERDIMID, FULLNAME, ISACTIVE,ISACTIVEFUNDRAISER,ISACTIVESTAFF,FY.experience
,FR_CO.CONSTITUENT_COUNT,FR_CO.CONSTITUENT_ACTIVE
,TOTALINTERACTIONCOUNT, TOTALFUNDRAISERREVENUECOUNT
,REVENUE_ALL.REVENUE_AMOUNT
,REV_DONATION,REV_PLEDGE,REV_RECG
,BU_Communications,BU_CP,BU_DM,BU_Events,BU_HKI,BU_MG,BU_CGF,BU_SKF
,INT_Phone,INT_Email,INT_InPerson
into [ConversionMapping].dbo.saeed_FR2009
from FUNDRAISER
inner join INTERACTION_COUNTS
on FUNDRAISER.FUNDRAISERDIMID=INTERACTION_COUNTS.FUNDRAISERDIMID
inner join FR_CO
on FUNDRAISER.FUNDRAISERDIMID = FR_CO.FUNDRAISERDIMID
inner join REVENUE_ALL
on FUNDRAISER.FUNDRAISERDIMID=REVENUE_ALL.FUNDRAISERDIMID
inner join FUNDRAISERYEAR FY
on FUNDRAISER.FUNDRAISERDIMID = FY.FUNDRAISERDIMID




update [ConversionMapping].[dbo].[saeed_FR2009] set constituent_count=0 where constituent_count is null
update [ConversionMapping].[dbo].[saeed_FR2009] set CONSTITUENT_ACTIVE=0 where CONSTITUENT_ACTIVE is null
update [ConversionMapping].[dbo].[saeed_FR2009] set REVENUE_AMOUNT=0 where REVENUE_AMOUNT is null

update [ConversionMapping].[dbo].[saeed_FR2009] set BU_CP=0 where BU_CP is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_DM=0 where BU_DM is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_Events=0 where BU_Events is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_HKI=0 where BU_HKI is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_MG=0 where BU_MG is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_CGF=0 where BU_CGF is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_SKF=0 where BU_SKF is null
update [ConversionMapping].[dbo].[saeed_FR2009] set BU_Communications=0 where BU_Communications is null


update [ConversionMapping].[dbo].[saeed_FR2009] set INT_Phone=0 where INT_Phone is null
update [ConversionMapping].[dbo].[saeed_FR2009] set INT_Email=0 where INT_Email is null
update [ConversionMapping].[dbo].[saeed_FR2009] set INT_InPerson=0 where INT_InPerson is null

update [ConversionMapping].[dbo].[saeed_FR2009] set experience=10 where experience>10

delete from [ConversionMapping].[dbo].[saeed_FR2009] where FUndraiserDimid=0
delete from [ConversionMapping].[dbo].[saeed_FR2009] where FUndraiserDimid='2241971'
delete from [ConversionMapping].[dbo].[saeed_FR2009] where FUndraiserDimid='2170189'

Select * from [ConversionMapping].[dbo].[saeed_FR2009]
order by REVENUE_AMOUNT
--where constituent_count=26500



/********** the aggregation part ********************/

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  A.[FUNDRAISERDIMID]
		,A.fullname
      ,A.[REVENUE_AMOUNT]  y2009
	  ,B.[REVENUE_AMOUNT] y2010
	   ,c.[REVENUE_AMOUNT] y2011
	   	   ,d.[REVENUE_AMOUNT] y2012
		   	   ,e.[REVENUE_AMOUNT] y2013
			   	   ,f.[REVENUE_AMOUNT] y2014
  FROM [ConversionMapping].[dbo].[saeed_FR2009] as A
  inner join [dbo].[saeed_FR2010] as B
  on A.[FUNDRAISERDIMID] = B.[FUNDRAISERDIMID]
    inner join [dbo].[saeed_FR2011] as c
  on A.[FUNDRAISERDIMID] = c.[FUNDRAISERDIMID]
      inner join [dbo].[saeed_FR2012] as d
  on A.[FUNDRAISERDIMID] = d.[FUNDRAISERDIMID]
      inner join [dbo].[saeed_FR2013] as e
  on A.[FUNDRAISERDIMID] = e.[FUNDRAISERDIMID]
      inner join [dbo].[saeed_FR2014] as f
  on A.[FUNDRAISERDIMID] = f.[FUNDRAISERDIMID]
  order by y2014



