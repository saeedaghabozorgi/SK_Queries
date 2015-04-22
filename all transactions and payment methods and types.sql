---- all payment methods 

select top 200 codes.REVENUETRANSACTIONTYPE
				,codes.REVENUEAPPLICATION
				,codes.REVENUEAPPLICATIONTYPE
				,count(bbdw.v_FACT_REVENUE.REVENUECODEDIMID) dimcount
				,bbdw.v_FACT_REVENUE.REVENUECODEDIMID
from bbdw.v_FACT_REVENUE 
	inner join [BBDW].[DIM_REVENUECODE] as codes
		on bbdw.v_FACT_REVENUE.REVENUECODEDIMID = codes.REVENUECODEDIMID
group by codes.REVENUETRANSACTIONTYPE
		,codes.REVENUEAPPLICATION
		,bbdw.v_FACT_REVENUE.REVENUECODEDIMID				
		,codes.REVENUEAPPLICATIONTYPE
order by dimcount desc
, bbdw.v_FACT_REVENUE.REVENUECODEDIMID