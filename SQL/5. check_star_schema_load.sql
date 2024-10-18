-- ##########################################################
-- Script Name: Data Quality Checks for Cricket Matches Star Schema
-- Author: Chris Rodgers
-- Date: 2024-09-29
-- Purpose: Perform sanity checks after loading data from staging to star schema, this includes checking row count consistency, missing data in star schema, duplicate records, foreign key integrity checks
-- ##########################################################

--- ROW COUNT CHECKS
--- Check that row counts between staging and star schema are consistent

-- Check row counts for 'matches' table
SELECT 
    (SELECT COUNT(*) FROM [CricketDBStaging].[dbo].[stg_matches]) AS staging_row_count,
    (SELECT COUNT(*) FROM [CricketDB].[dbo].[FactMatch]) AS star_schema_row_count;

-- Check row counts for 'innings' table
SELECT 
    (SELECT COUNT(*) FROM [CricketDBStaging].[dbo].[stg_innings]) AS staging_row_count,
    (SELECT COUNT(*) FROM [CricketDB].[dbo].[DimInnings]) AS star_schema_row_count;

-- Check row counts for 'overs' table
SELECT 
    (SELECT COUNT(*) FROM [CricketDBStaging].[dbo].[stg_overs]) AS staging_row_count,
    (SELECT COUNT(*) FROM [CricketDB].[dbo].[DimOvers]) AS star_schema_row_count;

-- Check row counts for 'deliveries' table
SELECT 
    (SELECT COUNT(*) FROM [CricketDBStaging].[dbo].[stg_deliveries]) AS staging_row_count,
    (SELECT COUNT(*) FROM [CricketDB].[dbo].[DimDeliveries]) AS star_schema_row_count;

-- Check row counts for 'wickets' table
SELECT 
    (SELECT COUNT(*) FROM [CricketDBStaging].[dbo].[stg_wickets]) AS staging_row_count,
    (SELECT COUNT(*) FROM [CricketDB].[dbo].[DimWicket]) AS star_schema_row_count;



--- CHECK FOR MISSING DATA IN STAR SCHEMA
--- Joins star schema to staging based on ID and returns rows where an entry in staging is missing from the star schema - no rows returned means data loaded correctly

-- Check for missing records in FactMatch
SELECT SM.match_id
FROM [CricketDBStaging].[dbo].[stg_matches] AS SM
LEFT JOIN [CricketDB].[dbo].[FactMatch] AS FM 
ON SM.match_id = FM.match_id
WHERE SM.match_id IS NULL;

-- Check for missing records in DimInnings
SELECT SM.innings_id
FROM [CricketDBStaging].[dbo].[stg_innings] AS SM
LEFT JOIN [CricketDB].[dbo].[DimInnings] AS FM 
ON SM.innings_id = FM.innings_id
WHERE SM.innings_id IS NULL;


--- CHECK FOR DUPLICATE RECORDS
--- Ensure no duplicate records in staging or star schema

SELECT match_id, COUNT(*)
FROM [CricketDBStaging].[dbo].[stg_matches]
GROUP BY match_id
HAVING COUNT(*) > 1;

-- Check for duplicates in the dim_matches table
SELECT match_id, COUNT(*)
FROM [CricketDB].[dbo].[FactMatch]
GROUP BY match_id
HAVING COUNT(*) > 1;


--- CHECK FOR NULL OR MISSING KEY VALUES
--- Ensure foreign keys are not missing

--- Check that Innings are connected to Matches
SELECT COUNT(*) AS null_matches FROM [CricketDB].[dbo].[MatchInningsBridge] WHERE match_id IS NULL;

--- Check that Overs are connnected to Innings
SELECT COUNT(*) AS null_innings FROM [CricketDB].[dbo].[DimOvers] WHERE innings_id IS NULL;

--- Check that Deliveries are connected to Overs
SELECT COUNT(*) AS null_overs FROM [CricketDB].[dbo].[DimDeliveries] WHERE over_id IS NULL;


--- INTEGRITY CHECK FOR FACT AND DIMENSION TABLES
--- Check referential integrity between Matches, Innings, Overs and Deliveries

--- Check every match is joined to an innings
SELECT *
FROM [CricketDB].[dbo].[FactMatch] AS FM
LEFT JOIN [CricketDB].[dbo].[MatchInningsBridge] AS MIB ON FM.match_id = MIB.match_id
WHERE MIB.innings_id IS NULL;

--- Check innings are joined to overs, some may not be joined due to no overs being bowled
SELECT *
FROM [CricketDB].[dbo].[DimInnings] AS DI
LEFT JOIN [CricketDB].[dbo].[DimOvers] AS DO ON DI.innings_id = DO.innings_id
WHERE DO.over_id IS NULL;

