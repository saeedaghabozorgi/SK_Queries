delete  from states
delete  from constituents


DECLARE
    @i  int,
    @id   int,
	@ConsID int,
	@state varchar(20),
	@seqCount int,
	@seqID int,
	@prob int;


SET @i =1;
SET @ConsID=1;
SET @seqID=1;

DECLARE 	@tIntraction TABLE (Name VARCHAR(20) NOT NULL);
INSERT INTO @tIntraction VALUES
('Email'),
('InPerson'),
('Phone'),
('noInteraction');

DECLARE 	@tDonate TABLE (Name VARCHAR(20) NOT NULL);
INSERT INTO @tDonate VALUES
('Donation'),
('Pledge');



WHILE @ConsID < 101
BEGIN
	SET @seqCount=4 --ROUND(((10-2)*RAND()+2),0)
	while @seqID<@seqCount
	BEGIN
		SET @prob=ROUND(((10-0)*RAND()+0),0)
		if (@prob<3 and @seqID>@seqCount*0.6)
			set @state=(SELECT TOP 1 * FROM @tDonate ORDER BY NEWID());
		else 
			set @state=(SELECT TOP 1 * FROM @tIntraction ORDER BY NEWID());

		if (@ConsID>0 and @ConsID<11 and @seqID<2)  set @state='Email';--new condition for clustering of cons
		if (@ConsID>10 and @ConsID<21 and @seqID<2)  set @state='Phone';--new condition for clustering of cons
		if (@ConsID>20 and @seqID<30 and @seqID<3)  set @state='InPerson';--new condition for clustering of cons
		INSERT INTO states  VALUES  (@i,@ConsID,@seqID, @state);
		SET @seqID = @seqID + 1;
		SET @i = @i + 1;
	END
	SET @ConsID = @ConsID + 1;
	SET @seqID=1;
    --SET @id = ROUND(((10000-5000)*RAND()+5000),0)
END


Insert into constituents
select distinct ConsID 
from states 

select * from  states order by id

update states set state='Email'
where consid <= 100 and seq=1
update states set state='Phone'
where consid <= 50 and seq=1
update states set state='InPerson'
where consid <= 20 and seq=1


------------------------------------------------------------------------------------------------
------------------------ statistics on generated data ------------------------------------------
------------------------------------------------------------------------------------------------

select state,count(state) as sc,sum(case when seq=1 then 1 else 0 end) start_ from  states 
group by state
----------------
select state
from  states 
where (state='email' and seq=1) and (state='email' and seq=2)
----------------
with xxx as
(
select consid as cons,[1] as seq1,[2] as seq2,[3] as seq3 
from (select consid,seq,state from states ) as sourcetable
pivot 
(
max(state) for seq in ([1],[2],[3]  )
) as pivottable) 
select * from xxx where (seq1='Email' and  seq2='Email') or  (seq2='Email' and  seq3='Email')

----------------
with xxx as
(
select consid as cons,[1] as seq1,[2] as seq2,[3] as seq3 
from (select consid,seq,state from states ) as sourcetable
pivot 
(
max(state) for seq in ([1],[2],[3]  )
) as pivottable) 
select 
sum (case when (seq1='Email' and seq2='Email') or (seq2='Email' and seq3='Email') then 1 else 0 end ) as email_email,
sum (case when (seq1='Email' and seq2='phone') or (seq2='Email' and seq3='Phone') then 1 else 0 end ) as email_phone,
sum (case when (seq1='Email' and seq2='InPerson') or (seq2='Email' and seq3='InPerson') then 1 else 0 end ) as email_InPerson,
sum (case when (seq1='Email' and seq2='noInteraction') or (seq2='Email' and seq3='noInteraction') then 1 else 0 end ) as email_noInteraction,
sum (case when (seq1='Email' and seq2='Pledge') or (seq2='Email' and seq3='Pledge') then 1 else 0 end ) as email_Pledge,
sum (case when (seq1='Email' and seq2='Donation') or (seq2='Email' and seq3='Donation') then 1 else 0 end ) as email_Donation
from xxx
