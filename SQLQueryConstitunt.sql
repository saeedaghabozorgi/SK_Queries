-- list of constituent and revenues

select top 100 c.CONSTITUENTLOOKUPID,c.AGE, 
	sum(case when codes.REVENUETRANSACTIONTYPECODE = 0 then revenue.REVENUEAPPLICATIONAMOUNT else 0 end) as Total_revenue, -- all payments
	sum(case when (codes.REVENUEAPPLICATIONCODE=2) then revenue.REVENUEAPPLICATIONAMOUNT else 0 end) as pledge_header, -- pledge header
	sum(case when codes.REVENUETRANSACTIONTYPECODE = 0 then revenue.REVENUEAPPLICATIONAMOUNT else 0 end) as pledge_payment, -- pledge payment
	sum(revenue.REVENUEAPPLICATIONAMOUNT) as allTransaction, -- all transaction types
	sum(case when codes.REVENUEAPPLICATIONCODE =2 then revenue.REVENUEAPPLICATIONAMOUNT else 0 end) as payments2
	from bbdw.v_FACT_REVENUE as revenue
	inner join [BBDW].[DIM_REVENUECODE] as codes
		on revenue.REVENUECODEDIMID = codes.REVENUECODEDIMID
	inner join [BBDW].DIM_CONSTITUENT c 
		on revenue.CONSTITUENTDIMID = c.CONSTITUENTDIMID 
	where  c.CONSTITUENTLOOKUPID='4026364' 
group by c.CONSTITUENTLOOKUPID,c.AGE

