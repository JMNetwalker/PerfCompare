# Background
We found in many cases that we have different performance for same databases running in different SQL Instance. In multiple situations we could find that the differences are coming from different configuration, missing indexes, different workload, statistics, etc.. 

# PerfCompare.Ps1
The main idea is to collect the results of relevant queries and save them in CSV file to compare the results, running this script. 
This PowerShell script will prompt the details of the connection and read the Perf_Instruc.SQL file creating a file per query, log file that contains all the operations and compressing everything in a zip file.

# PERF_Instruct.SQL

This file contains the queries to be executed. 
The format needs to be the following:

- **First Line needs to contains the text -- and not more of 20 characters that will use for the CSV file name**
- **Second line will be the TSQL query to be executed that needs to be finished by the delimiter # . Following you have some examples:**

   --ConfINSLevel  
   select * from sys.configurations#
   
  --ConfDBLEVEL
     select * from sys.databases#
     
  --Statistics
  
   SELECT sp.stats_id, object_name(sp.object_id) as TableName, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter   
   FROM sys.stats AS stat   
   CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp#
   
   
