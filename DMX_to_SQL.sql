EXEC sp_addlinkedserver
@server='DM_LINKED_LOCAL',    -- local SQL name given to the linked server
@srvproduct='',         -- not used (any value will do)
@provider='MSOLAP',     -- Analysis Services OLE DB provider
@datasrc='SKF100539\SKF_MINING',   -- Analysis Server name (machine name)
@catalog='MarkovModel'   -- default catalog/database




drop table #2
select NODE_UNIQUE_NAME as name,[t.ST] as ST,[t.Sequence Probability] as pr
into #2
from  OPENQUERY(DM_LINKED_LOCAL,
 'SELECT flattened  NODE_TYPE,NODE_UNIQUE_NAME,[PARENT_UNIQUE_NAME],
(SELECT ATTRIBUTE_VALUE AS [ST],
[Support] AS [Sequence Support], 
[Probability] AS [Sequence Probability]
FROM NODE_DISTRIBUTION) AS t
from [Donation States Inactive].CONTENT
WHERE NODE_TYPE = 14
AND [PARENT_UNIQUE_NAME] = ''688117''' )




select distinct(ST) from #2

ALTER TABLE #2
ALTER COLUMN name nvarchar(25)





DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)
 
--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(ST)
FROM (SELECT DISTINCT ST FROM #2) AS BUs
 
--Prepare the PIVOT query using the dynamic 
SET @DynamicPivotQuery = 
  N'SELECT name, ' + @ColumnName + '
    FROM #2
    PIVOT(max(pr) 
          FOR ST IN (' + @ColumnName + ')) AS PVTTable'
--Execute the Dynamic Pivot Query
EXEC sp_executesql @DynamicPivotQuery



