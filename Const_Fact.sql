/* *******************  Prepared by Saeed, 11/05/15, ********************/ 
/****************** to find the Trans,BU,apeals,Interac, of donations  ******************/
/*****************************************************************************************/

Print ('Creating Table Bio')
IF OBJECT_ID('tempdb..#Bio') IS NOT NULL DROP TABLE #Bio  --Remove dbo here 
   
Select CONSTITUENTLOOKUPID,CONSTITUENTDIMID,[AGE],[TITLE],CONSTITUENT.[GENDER],CONSTITUENT.[DONOTMAIL]
      ,CONSTITUENT.[GIVESANONYMOUSLY]
      ,CONSTITUENT.[ISACTIVE]
      ,CONSTITUENT.[ISCONSTITUENT]
      ,CONSTITUENT.[ISDECEASED]
      ,CONSTITUENT.[ISGROUP]
      ,CONSTITUENT.[ISORGANIZATION]
      ,CONSTITUENT.[ISNETCOMMUNITYMEMBER]
	  ,CONSTITUENT.[MARITALSTATUS]
      ,CONSTITUENT.[ISACTIVEBOARDMEMBER]
      ,CONSTITUENT.[ISACTIVECOMMITTEE]
      ,CONSTITUENT.[ISACTIVEFUNDRAISER]
      ,CONSTITUENT.[ISACTIVEPROSPECT]
      ,CONSTITUENT.[ISACTIVESTAFF]
      ,CONSTITUENT.[ISACTIVESPONSOR]
      ,CONSTITUENT.[ISACTIVEVOLUNTEER]
INTO #Bio
from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] AS CONSTITUENT
inner join  [ECSKF_RPT_BBDW].[dbo].[SKF_RPT_ConstituentType_EXT] AS CONSTITUENT_TYPE
on CONSTITUENT_TYPE.[CONSTITUENTSYSTEMID]=CONSTITUENT.[CONSTITUENTSYSTEMID]
where CONSTITUENT_TYPE.CONSTITUENTTYPE='Individual'

update #Bio set gender='Female' where Title  in ('Ms.','Mrs.','Miss','Dr. & Mrs.','Madam','Madame','Sister') and (gender='Unknown' or gender is null)
update #Bio set gender='Male' where Title  in ('Mr.','Brother','Father') and (gender='Unknown' or gender is null)

--select count(*) from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] as CONSTITUENT
--inner join  [ECSKF_RPT_BBDW].[dbo].[SKF_RPT_ConstituentType_EXT] AS CONSTITUENT_TYPE
--on CONSTITUENT_TYPE.[CONSTITUENTSYSTEMID]=CONSTITUENT.[CONSTITUENTSYSTEMID]
--where CONSTITUENT_TYPE.CONSTITUENTTYPE='Individual'
--select count(*) from #Bio
--select top 100 * from #Bio
--select distinct [CONSTITUENTADDRESSTYPE] from #Bio
--select  * from #Bio where  CONSTITUENTLOOKUPID='70434'
-- select  maritalstatus, count(maritalstatus) from #Bio group by maritalstatus
--------------------------------------------------------------------
Print ('Creating Table ADD')
IF OBJECT_ID('tempdb..#Add') IS NOT NULL DROP TABLE #Add ; --Remove dbo here 
   
Select CONSTITUENTLOOKUPID,CONSTITUENTDIMID,[PRIMARYADDRESSCITY]
      ,[PRIMARYADDRESSSTATE]
      ,ADD_DETAILS.[ISCONFIDENTIAL]
      ,ADD_DETAILS.[ISPRIMARY]
	 ,ADD_TYPE.[CONSTITUENTADDRESSTYPE]
	 ,AFF.AFFLUENCEINDICATORNUMBER
	 
INTO #Add
from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] AS CONSTITUENT
left outer join [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENTADDRESSFLAG] as ADD_DETAILS
on ADD_DETAILS.[CONSTITUENTADDRESSFLAGDIMID] = CONSTITUENT.[CONSTITUENTADDRESSFLAGDIMID]
left outer join [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENTADDRESSTYPE] as ADD_TYPE
on ADD_TYPE.[CONSTITUENTADDRESSTYPEDIMID]= CONSTITUENT.[CONSTITUENTADDRESSFLAGDIMID]
left outer join [ECSKF_RPT_BBDW].[dbo].SKF_RPT_WealthAndRatings_EXT as AFF
on AFF.ConstituentSystemID=CONSTITUENT.CONSTITUENTSYSTEMID
--where CONSTITUENT.CONSTITUENTLOOKUPID='174572'
--select CONSTITUENTLOOKUPID, AFFLUENCEINDICATORNUMBER from #Add where CONSTITUENTLOOKUPID in ('70434','71525','86433','91566','91792','94358')
-- select count(*) ,count(distinct CONSTITUENTLOOKUPID) from #Add
--select CONSTITUENTADDRESSTYPE from #Add
IF OBJECT_ID('tempdb..#AddDet') IS NOT NULL DROP TABLE #AddDet  --Remove dbo here 
select *  
into #AddDet
from(select a.CONSTITUENTDIMID, c.CONSTITUENTADDRESSTYPE from  [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT]  as a 
inner join [ECSKF_RPT_BBDW].[BBDW].[FACT_CONSTITUENTADDRESS]  as b
on a.CONSTITUENTDIMID=b.CONSTITUENTDIMID
inner join [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENTADDRESSTYPE] as c
on b.CONSTITUENTADDRESSTYPEDIMID=c.CONSTITUENTADDRESSTYPEDIMID
--where CONSTITUENTLOOKUPID='174572'
) as SRC
Pivot
(
count(CONSTITUENTADDRESSTYPE)
FOR CONSTITUENTADDRESSTYPE IN (Home, Business)
)as pivot_table
--select * from #AddDet
--select distinct(AFFLUENCEINDICATORNUMBER) from SKF_RPT_WealthAndRatings_EXT
--select * from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT]
--select * from [ECSKF_RPT_BBDW].[BBDW].[FACT_CONSTITUENTADDRESS] where CONSTITUENTDIMID='683601'
--select * from [dbo].[SKF_DM_ConstituentAddress_EXT] where CONSTITUENTID='E5E4D1C1-700A-4DC9-B12F-FC2B411D01D3'
-- select count(*),count(distinct CONSTITUENTDIMID) from #AddDet
---------------------------------------------------------------------
Print ('Creating Table Intr')
IF OBJECT_ID('tempdb..#intr') IS NOT NULL DROP TABLE #intr  --Remove dbo here 

Select CONSTITUENTLOOKUPID, max(INTER.[INTEREST]) as Interest
INTO #intr
from #Bio AS CONSTITUENT
left outer join [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENTINTEREST] as INTER
on INTER.CONSTITUENTDIMID=CONSTITUENT.CONSTITUENTDIMID
group by CONSTITUENTLOOKUPID

--select count(*),count(distinct CONSTITUENTLOOKUPID) from #intr

-----------------------------------------------------------------------
Print ('Creating Table APPEAL')
IF OBJECT_ID('tempdb..#APPEAL') IS NOT NULL DROP TABLE #APPEAL  --Remove dbo here 
SELECT CONS_APPEAL.[CONSTITUENTDIMID]
	  ,count(*) as APEAL_COUNT,
	  sum(case when APPEAL.APPEALCATEGORY='Lottery' then 1 else 0 end) as APEAL_COUNT_lotry,
	  sum(case when APPEAL.APPEALCATEGORY='General Donations' then 1 else 0 end) as APEAL_COUNT_GenDon,
	  sum(case when APPEAL.APPEALCATEGORY='Door to Door' then 1 else 0 end) as APEAL_COUNT_DTD,
	  sum(case when APPEAL.APPEALCATEGORY='Corporate Partnerships' then 1 else 0 end) as APEAL_COUNT_CP,
	  sum(case when APPEAL.APPEALCATEGORY='Direct Mail' then 1 else 0 end) as APEAL_COUNT_DM
INTO #APPEAL
  FROM [ECSKF_RPT_BBDW].[BBDW].[FACT_CONSTITUENTAPPEAL] CONS_APPEAL
  inner join [ECSKF_RPT_BBDW].[BBDW].[DIM_APPEAL] APPEAL
  on CONS_APPEAL.APPEALDIMID=APPEAL.APPEALDIMID
  group by CONS_APPEAL.[CONSTITUENTDIMID]
--select * from 	#APPEAL  where #APPEAL.CONSTITUENTDIMID='820'
------------------------------------------------------------------------------
Print ('Creating Table REV')
IF OBJECT_ID('tempdb..#REV') IS NOT NULL DROP TABLE #REV  --Remove dbo here 
SELECT min(CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)) AS FIRST_REV_DATE,
	max(CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)) AS LAST_REV_DATE,
	CO.CONSTITUENTLOOKUPID, 
	CODES.REVENUETRANSACTIONTYPE AS TRAN_TYPE 
	, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
    ,sum(REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT) AS SUM_AMOUNT, '--------' as REV_TYPE
     INTO #REV
     FROM  [ECSKF_RPT_BBDW].[BBDW].FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where 
(codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --Donation
or (codes.REVENUETRANSACTIONTYPECODE = 0 --payment
and (codes.REVENUETRANSACTIONTYPECODE = 1  --Pledge
or  codes.REVENUETRANSACTIONTYPECODE = 2   --RG
or codes.REVENUETRANSACTIONTYPECODE = 4   ))   --planned gift
--and co.CONSTITUENTLOOKUPID='174572'
group by CO.CONSTITUENTLOOKUPID,CODES.REVENUETRANSACTIONTYPE,CODES.REVENUEAPPLICATION

update #REV set REV_TYPE='P_DON' where TRAN_TYPE='Payment' and APPLICATION_TYPE='Donation'
update #REV set REV_TYPE='P_RG' where TRAN_TYPE='Payment' and APPLICATION_TYPE='Recurring gift'
update #REV set REV_TYPE='P_PLG' where TRAN_TYPE='Payment' and APPLICATION_TYPE='Pledge'
update #REV set REV_TYPE='H_RG' where TRAN_TYPE='Recurring gift' and APPLICATION_TYPE='Donation'
update #REV set REV_TYPE='H_PLG' where TRAN_TYPE='Pledge' and APPLICATION_TYPE='Donation'
update #REV set REV_TYPE='H_PG' where TRAN_TYPE='Planned gift' and APPLICATION_TYPE='Donation'
------
IF OBJECT_ID('tempdb..#REVEN') IS NOT NULL DROP TABLE #REVEN  --Remove dbo here 
select *,0 as 'T_REV'
into #REVEN
from  (select CONSTITUENTLOOKUPID,REV_TYPE, sum_amount from #REV) as sourcetable
PIVOT 
(
 max(sum_amount)
FOR REV_TYPE IN (P_DON,P_RG,P_PLG,H_RG,H_PLG,H_PG)
) as pivot_table

update #REVEN set T_REV=(isnull(P_DON,0) + isnull(P_RG,0)  + isnull(P_PLG,0))

--select * from #REVEN where CONSTITUENTLOOKUPID='70434'

-------
IF OBJECT_ID('tempdb..#REVDATE') IS NOT NULL DROP TABLE #REVDATE  --Remove dbo here 
select CONSTITUENTLOOKUPID,min(FIRST_REV_DATE) as FIRST_REV_DATE, max(LAST_REV_DATE) as LAST_REV_DATE
	, YEAR(max(LAST_REV_DATE))-YEAR (min(FIRST_REV_DATE)) as PAYLENGTH
into #REVDATE
from  #REV
group by CONSTITUENTLOOKUPID

--select * from #REVEN where CONSTITUENTLOOKUPID='70434'
-----Consistency----------------------------------------------------------------------
Print ('Creating Table CONSISTENCY')
IF OBJECT_ID('tempdb..#CONSTITUENCY') IS NOT NULL DROP TABLE #CONSTITUENCY ;

WITH CTE AS 
(
SELECT  CONSTITUENTS.CONSTITUENTDIMID, CONSTITUENTS.CONSTITUENTLOOKUPID
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 16 THEN 1 ELSE 0 END AS [IsFormerTrustee]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 28 THEN 1 ELSE 0 END AS [IsTrustee]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 6 THEN 1 ELSE 0 END AS [IsChairsCouncil]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 46 THEN 1 ELSE 0 END AS [IsParentofPatient]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 47 THEN 1 ELSE 0 END AS [IsGrandparentOfPatient]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 48 THEN 1 ELSE 0 END AS [IsFriendFamilyOfPatient]
      ,CASE WHEN CONSTITUENCY.CONSTITUENCY LIKE '%Committee%' THEN 1 ELSE 0 END AS [IsCommiteeMember]      
      ,CASE WHEN CONSTITUENCY.CONSTITUENCYDIMID = 26 THEN 1 ELSE 0 END AS [IsCampaignCabinet]
      ,CONSTITUENCIES.FROMDATE
      ,ROW_NUMBER() OVER (PARTITION BY CONSTITUENTS.CONSTITUENTDIMID, CONSTITUENTS.CONSTITUENTLOOKUPID ORDER BY CONSTITUENCIES.FROMDATE DESC) AS ROWNUMBER
      FROM  [ECSKF_RPT_BBDW].[BBDW].DIM_CONSTITUENT AS CONSTITUENTS
            INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].FACT_CONSTITUENCY AS CONSTITUENCIES
                  ON CONSTITUENTS.CONSTITUENTDIMID = CONSTITUENCIES.CONSTITUENTDIMID
            INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].DIM_CONSTITUENCY AS CONSTITUENCY
                  ON    CONSTITUENCY.CONSTITUENCYDIMID = CONSTITUENCIES.CONSTITUENCYDIMID
            INNER JOIN [ECSKF_RPT_BBDW].dbo.SKF_RPT_ConstituentType_EXT AS CONSTITUENTTYPE
                  ON CONSTITUENTS.CONSTITUENTSYSTEMID = CONSTITUENTTYPE.ConstituentSystemId
      WHERE       CONSTITUENTTYPE = 'Individual'
)
SELECT CONSTITUENTDIMID,CONSTITUENTLOOKUPID, [IsFormerTrustee],[IsTrustee],[IsChairsCouncil],[IsParentofPatient],[IsGrandparentOfPatient],[IsFriendFamilyOfPatient],[IsCommiteeMember],[IsCampaignCabinet]
      , CASE WHEN [IsFormerTrustee]+[IsTrustee]+[IsChairsCouncil]+[IsParentofPatient]+[IsGrandparentOfPatient]+[IsFriendFamilyOfPatient]+[IsCommiteeMember]+[IsCampaignCabinet] > 0 THEN 1 ELSE 0 END AS [HasRelationship]
      into #CONSTITUENCY
	  FROM CTE
      WHERE ROWNUMBER = 1


--select count(*) from #Rel where #Rel.CONSTITUENTLOOKUPID='70434'

--------BU------------------------------------------------------------------
Print ('Creating Table BU')
IF OBJECT_ID('tempdb..#CONS_BU') IS NOT NULL DROP TABLE #CONS_BU ;
Select CONSTITUENT.CONSTITUENTLOOKUPID,BUSINESSUNIT
INTO #CONS_BU
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
and
((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --donation
or (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 3)  -- Rec Gift payment
or (codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 2)  -- Pledge Payment
)  
group by CONSTITUENT.CONSTITUENTLOOKUPID,BUSINESSUNIT

--select distinct(BUSINESSUNIT) from #CONS_BU

IF OBJECT_ID('tempdb..#CONS_BUnit') IS NOT NULL DROP TABLE #CONS_BUni  --Remove dbo here 
select *
into #CONS_BUni
from  (select CONSTITUENTLOOKUPID,BUSINESSUNIT from #CONS_BU) as sourcetable
PIVOT 
(
 count(BUSINESSUNIT)
FOR BUSINESSUNIT IN ([Major Gifts],[SKF],[Corporate Partnerships],[Direct Marketing],[Events])
) as pivot_table
-----MG---------------------------------------------------------------------
Print ('Creating Table MG')
IF OBJECT_ID('tempdb..#MG') IS NOT NULL DROP TABLE #MG  --Remove dbo here 
SELECT DT.FISCALYEAR,
	CO.CONSTITUENTLOOKUPID, 
	sum(REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT) AS SUM_AMOUNT
     INTO #MG
     FROM  [ECSKF_RPT_BBDW].[BBDW].FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN  [ECSKF_RPT_BBDW].[BBDW].DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
					inner join [ECSKF_RPT_BBDW].[BBDW].DIM_DATE DT
						ON   REVENUE.FINANCIALTRANSACTIONDATEDIMID= DT.DATEDIMID 
where 
(codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --Donation
or (codes.REVENUETRANSACTIONTYPECODE = 0 --payment
and (codes.REVENUETRANSACTIONTYPECODE = 1  --Pledge
or  codes.REVENUETRANSACTIONTYPECODE = 2   ))   --RG
--and co.CONSTITUENTLOOKUPID='174572'
group by CO.CONSTITUENTLOOKUPID,DT.FISCALYEAR
order by CO.CONSTITUENTLOOKUPID,DT.FISCALYEAR

IF OBJECT_ID('tempdb..#ISMG') IS NOT NULL DROP TABLE #ISMG  --Remove dbo here 
SELECT 	CONSTITUENTLOOKUPID, min(FISCALYEAR) as F_MGIFT_DATE, max(FISCALYEAR) as L_MGIFT_DATE,
	count(SUM_AMOUNT) as MGCOUNT, max(SUM_AMOUNT) as MGMAX 
     INTO #ISMG
     FROM  #MG
WHERE SUM_AMOUNT>9999
group by CONSTITUENTLOOKUPID

--select * from #MG where CONSTITUENTLOOKUPID='91792'
--select * from #ISMG where CONSTITUENTLOOKUPID='91792'
---------------------------------------------------------------------------
Print ('Joining')
--IF OBJECT_ID('tempdb..[saeed_Constituents]') IS NOT NULL 
DROP TABLE [ConversionMapping].[dbo].[saeed_Constituents]
Select 
#Bio.CONSTITUENTLOOKUPID,
#Bio.CONSTITUENTDIMID,
#Bio.[AGE],
#Bio.[TITLE],
#Bio.[GENDER],
#Bio.[DONOTMAIL]
,#Bio.[GIVESANONYMOUSLY]
,#Bio.[ISACTIVE]
--,#Bio.[ISCONSTITUENT]
,#Bio.[ISDECEASED]
--,#Bio.[ISGROUP]
--,#Bio.[ISORGANIZATION]
,#Bio.[ISNETCOMMUNITYMEMBER]
,#Bio.[ISACTIVEBOARDMEMBER]
,#Bio.[ISACTIVECOMMITTEE]
,#Bio.[ISACTIVEFUNDRAISER]
,#Bio.[ISACTIVEPROSPECT]
,#Bio.[ISACTIVESTAFF]
--,#Bio.[ISACTIVESPONSOR]
,#Bio.[ISACTIVEVOLUNTEER]
,#Bio.MARITALSTATUS
,#Add.[PRIMARYADDRESSCITY]
,#Add.[PRIMARYADDRESSSTATE]
,#Add.[ISCONFIDENTIAL]
--,#Add.[ISPRIMARY]
,#Add.[CONSTITUENTADDRESSTYPE]
,#Add.AFFLUENCEINDICATORNUMBER
,#AddDet.Home
,#AddDet.Business
,#intr.Interest
,#APPEAL.APEAL_COUNT
,#APPEAL.APEAL_COUNT_CP
,#APPEAL.APEAL_COUNT_DM
,#APPEAL.APEAL_COUNT_DTD
,#APPEAL.APEAL_COUNT_GenDon
,#APPEAL.APEAL_COUNT_lotry
,#REVEN.H_PG
,#REVEN.H_PLG
,#REVEN.H_RG
,#REVEN.P_DON
,#REVEN.P_PLG
,#REVEN.P_RG
,#REVEN.T_REV
,#REVDATE.FIRST_REV_DATE
,#REVDATE.LAST_REV_DATE
,#REVDATE.PAYLENGTH
,#CONSTITUENCY.IsCampaignCabinet
,#CONSTITUENCY.IsChairsCouncil
,#CONSTITUENCY.[IsCommiteeMember]
,#CONSTITUENCY.IsFormerTrustee
,#CONSTITUENCY.IsFriendFamilyOfPatient
,#CONSTITUENCY.IsGrandparentOfPatient
,#CONSTITUENCY.IsParentofPatient
,#CONS_BUni.[Corporate Partnerships]
,#CONS_BUni.[Direct Marketing]
,#CONS_BUni.[Events]
,#CONS_BUni.[Major Gifts]
,#CONS_BUni.SKF
,#ISMG.MGCOUNT
,#ISMG.MGMAX
,CASE WHEN ISNUMERIC(#ISMG.MGCOUNT)>0 THEN 'Yes' ELSE 'No' END as ISMG
into  [ConversionMapping].[dbo].[saeed_Constituents]
from #Bio
left outer join #Add
on #Bio.CONSTITUENTLOOKUPID=#Add.CONSTITUENTLOOKUPID
left outer join #AddDet
on #Bio.CONSTITUENTDIMID=#AddDet.CONSTITUENTDIMID
Left outer join #intr
on #Bio.CONSTITUENTLOOKUPID=#intr.CONSTITUENTLOOKUPID
Left outer join #APPEAL
on #Bio.CONSTITUENTDIMID=#APPEAL.CONSTITUENTDIMID
Left outer join #REVEN
on #Bio.CONSTITUENTLOOKUPID=#REVEN.CONSTITUENTLOOKUPID
Left outer join #REVDATE
on #Bio.CONSTITUENTLOOKUPID=#REVDATE.CONSTITUENTLOOKUPID
Left outer join #CONSTITUENCY
on #Bio.CONSTITUENTLOOKUPID=#CONSTITUENCY.CONSTITUENTLOOKUPID
left outer join #CONS_BUni
on #Bio.CONSTITUENTLOOKUPID=#CONS_BUni.CONSTITUENTLOOKUPID
left outer join #ISMG
on #Bio.CONSTITUENTLOOKUPID= #ISMG.CONSTITUENTLOOKUPID
where FIRST_REV_DATE>'1990-01-01'
and FIRST_REV_DATE<'2015-06-01'
and LAST_REV_DATE>'2000-01-01'
and LAST_REV_DATE<'2015-06-01'


update  [ConversionMapping].[dbo].[saeed_Constituents]
set age=null where age<10 or age>100
update  [ConversionMapping].[dbo].[saeed_Constituents]
set [Major Gifts]=0 where [Major Gifts] is null
update  [ConversionMapping].[dbo].[saeed_Constituents]
set [Corporate Partnerships]=0 where [Corporate Partnerships] is null
update  [ConversionMapping].[dbo].[saeed_Constituents]
set [Direct Marketing]=0 where [Direct Marketing] is null
update  [ConversionMapping].[dbo].[saeed_Constituents]
set [Events]=0 where [Events] is null
update  [ConversionMapping].[dbo].[saeed_Constituents]
set SKF=0 where SKF is null


--------------------------------------------------------------------
select distinct(AFFLUENCEINDICATORNUMBER) from [ConversionMapping].[dbo].[saeed_Constituents]
select distinct([Direct Marketing]) from [ConversionMapping].[dbo].[saeed_Constituents]

select * from [ConversionMapping].[dbo].[saeed_Constituents]
where CONSTITUENTLOOKUPID='70434'

select count(*) from [ConversionMapping].[dbo].[saeed_Constituents]
where CONSTITUENTLOOKUPID='70434'

----------------------------------------------------


