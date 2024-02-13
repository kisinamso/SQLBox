/*
-----------------------------------------------@kisinamso-----------------------------------------------
|This script gives you all the indexes in a database which you assert below in 'DB_NAME'.              |
-----------------------------------------------@kisinamso-----------------------------------------------
*/
USE [DB_NAME]
GO
SELECT	DISTINCT 
    s.name			  AS SchemaName, 
		t.name			  AS TableName, 
		i.name			  AS IndexName, 
		c.name			  AS ColumnName,
		i.type_desc		AS IndexType,
		i.is_disabled	AS Active
FROM sys.tables t
INNER JOIN sys.schemas s         ON t.schema_id = s.schema_id
INNER JOIN sys.indexes i         ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic  ON ic.object_id = t.object_id
INNER JOIN sys.columns c         ON c.object_id = t.object_id and
        ic.column_id = c.column_id

WHERE i.index_id > 0    
 AND i.type in (1, 2) -- clustered & nonclustered only
 AND i.is_primary_key = 0 -- do not include PK indexes
 AND i.is_unique_constraint = 0 -- do not include UQ
 AND i.is_disabled = 0
 AND i.is_hypothetical = 0
 AND ic.key_ordinal > 0

