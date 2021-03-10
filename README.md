# PerfCompare
We found in many cases that we have different performance for same databases running in different SQL Instance. In multiple situations we could find that the differences are coming from different configuration, missing indexes, different workload, statistics, etc.. 
The main idea is to collect the results of relevant queries and save them in CSV file to compare the results.

# PERF_Instruct.SQL

This file contains the queries to be executed. 
The format needs to be the following:

## First Line needs to contains the text -- and not more of 20 characters that will use for the CSV file name
## Second line will be the TSQL query to be executed that needs to be finished by the delimiter # . Following you have some examples:
  --ConfINSLevel  
   select * from sys.configurations#
  --ConfDBLEVEL
     select * from sys.databases#
   --RowsAndSizePerTable
   SELECT 
      t.NAME AS TableName,
      s.Name AS SchemaName,
      p.rows AS RowCounts,
      SUM(a.total_pages) * 8 AS TotalSpaceKB, 
      SUM(a.used_pages) * 8 AS UsedSpaceKB, 
      (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB
   FROM 
    sys.tables t
    INNER JOIN      
      sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN 
       sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN 
       sys.allocation_units a ON p.partition_id = a.container_id
    LEFT OUTER JOIN 
       sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
    GROUP BY 
       t.Name, s.Name, p.Rows 
    ORDER BY 
       t.Name#
