/* *******************  Prepared by Saeed, 11/05/15, ********************/ 
/****************** to find the Trans,BU,apeals,Interac, of donations  ******************/
/*****************************************************************************************/


IF OBJECT_ID('tempdb..#Bio') IS NOT NULL DROP TABLE #Bio  --Remove dbo here 
   
Select CONSTITUENTLOOKUPID,CONSTITUENTDIMID,[AGE],[TITLE],CONSTITUENT.[GENDER],CONSTITUENT.[DONOTMAIL]
      ,CONSTITUENT.[GIVESANONYMOUSLY]
      ,CONSTITUENT.[ISACTIVE]
      ,CONSTITUENT.[ISCONSTITUENT]
      ,CONSTITUENT.[ISDECEASED]
      ,CONSTITUENT.[ISGROUP]
      ,CONSTITUENT.[ISORGANIZATION]
      ,CONSTITUENT.[ISNETCOMMUNITYMEMBER]
      ,[ISACTIVEBOARDMEMBER]
      ,[ISACTIVECOMMITTEE]
      ,[ISACTIVEFUNDRAISER]
      ,[ISACTIVEPROSPECT]
      ,[ISACTIVESTAFF]
      ,[ISACTIVESPONSOR]
      ,[ISACTIVEVOLUNTEER]
	  ,[PRIMARYADDRESSCITY]
      ,[PRIMARYADDRESSSTATE]
      ,ADD_DETAILS.[ISCONFIDENTIAL]
      ,ADD_DETAILS.[ISPRIMARY]
	 ,ADD_TYPE.[CONSTITUENTADDRESSTYPE]
INTO #Bio
from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] AS CONSTITUENT
inner join  [ECSKF_RPT_BBDW].[dbo].[SKF_RPT_ConstituentType_EXT] AS CONSTITUENT_TYPE
on CONSTITUENT_TYPE.[CONSTITUENTSYSTEMID]=CONSTITUENT.[CONSTITUENTSYSTEMID]
left outer join [BBDW].[DIM_CONSTITUENTADDRESSFLAG] as ADD_DETAILS
on ADD_DETAILS.[CONSTITUENTADDRESSFLAGDIMID] = CONSTITUENT.[CONSTITUENTADDRESSFLAGDIMID]
left outer join [BBDW].[DIM_CONSTITUENTADDRESSTYPE] as ADD_TYPE
on ADD_TYPE.[CONSTITUENTADDRESSTYPEDIMID]= CONSTITUENT.[CONSTITUENTADDRESSFLAGDIMID]
where CONSTITUENT_TYPE.CONSTITUENTTYPE='Individual'

update #Bio set gender='Female' where Title  in ('Ms.','Mrs.','Miss','Dr. & Mrs.','Madam','Madame','Sister') and (gender='Unknown' or gender is null)
update #Bio set gender='Male' where Title  in ('Mr.','Brother','Father') and (gender='Unknown' or gender is null)

---------------------------------------------------------------------
IF OBJECT_ID('tempdb..#intr') IS NOT NULL DROP TABLE #intr  --Remove dbo here 

Select CONSTITUENTLOOKUPID, max(INTER.[INTEREST]) as Interest
INTO #intr
from #Bio AS CONSTITUENT
left outer join [BBDW].[DIM_CONSTITUENTINTEREST] as INTER
on INTER.CONSTITUENTDIMID=CONSTITUENT.CONSTITUENTDIMID
group by CONSTITUENTLOOKUPID

select top 100 * from #intr

-----------------------------------------------------------------------
IF OBJECT_ID('tempdb..#APPEAL') IS NOT NULL DROP TABLE #APPEAL  --Remove dbo here 
SELECT CONS_APPEAL.[CONSTITUENTDIMID]
	  ,APPEAL.APPEALCATEGORY
	  ,count(*) as APEAL_COUNT,
	  sum(case when APPEAL.APPEALCATEGORY='Lottery' then 1 else 0 end) as APEAL_COUNT_lotry,
	  sum(case when APPEAL.APPEALCATEGORY='General Donations' then 1 else 0 end) as APEAL_COUNT_GenDon,
	  sum(case when APPEAL.APPEALCATEGORY='Door to Door' then 1 else 0 end) as APEAL_COUNT_DTD,
	  sum(case when APPEAL.APPEALCATEGORY='Corporate Partnerships' then 1 else 0 end) as APEAL_COUNT_CP,
	  sum(case when APPEAL.APPEALCATEGORY='Direct Mail' then 1 else 0 end) as APEAL_COUNT_DM
INTO #APPEAL
  FROM [ECSKF_RPT_BBDW].[BBDW].[FACT_CONSTITUENTAPPEAL] CONS_APPEAL
  inner join [BBDW].[DIM_APPEAL] APPEAL
  on CONS_APPEAL.APPEALDIMID=APPEAL.APPEALDIMID
  group by CONS_APPEAL.[CONSTITUENTDIMID]
	  ,APPEAL.APPEALCATEGORY

------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#REV') IS NOT NULL DROP TABLE #REV  --Remove dbo here 
SELECT min(CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)) AS FIRST_REV_DATE,
	max(CONVERT(DATE,REVENUE.FINANCIALTRANSACTIONDATE)) AS LAST_REV_DATE,
	CO.CONSTITUENTLOOKUPID, 
	CODES.REVENUETRANSACTIONTYPE AS TRAN_TYPE 
	, CODES.REVENUEAPPLICATION AS APPLICATION_TYPE
    ,sum(REVENUE.FINANCIALTRANSACTIONLINEITEMAMOUNT) AS SUM_AMOUNT, '--------' as REV_TYPE

           INTO #REV
            FROM BBDW.FACT_FINANCIALTRANSACTIONLINEITEM AS REVENUE
                  INNER JOIN BBDW.DIM_CONSTITUENT AS CO
                        ON CO.CONSTITUENTDIMID = REVENUE.CONSTITUENTDIMID
                  INNER JOIN BBDW.DIM_REVENUECODE AS CODES
                        ON CODES.REVENUECODEDIMID = REVENUE.REVENUECODEDIMID 
where 
((codes.REVENUETRANSACTIONTYPECODE = 0 and CODES.REVENUEAPPLICATIONCODE = 0) --Donation
or codes.REVENUETRANSACTIONTYPECODE = 0 --payment
or (codes.REVENUETRANSACTIONTYPECODE = 1  --Pledge
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
into #REVDATE
from  #REV
group by CONSTITUENTLOOKUPID

select * from #REVEN where CONSTITUENTLOOKUPID='70434'

---------------------------------------------------------------------------

select count(*) from [ECSKF_RPT_BBDW].[BBDW].[DIM_CONSTITUENT] as CONSTITUENT
inner join  [ECSKF_RPT_BBDW].[dbo].[SKF_RPT_ConstituentType_EXT] AS CONSTITUENT_TYPE
on CONSTITUENT_TYPE.[CONSTITUENTSYSTEMID]=CONSTITUENT.[CONSTITUENTSYSTEMID]
where CONSTITUENT_TYPE.CONSTITUENTTYPE='Individual'
select count(*) from #Bio
select top 100 * from #Bio
select distinct [CONSTITUENTADDRESSTYPE] from #Bio

