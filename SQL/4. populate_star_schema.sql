-- ##########################################################
-- Script Name: Cricket Star Schema Load
-- Author: Chris Rodgers
-- Date: 2024-10-19
-- Purpose: Load data from staging to the star schema
-- ##########################################################



BEGIN TRANSACTION;

-- Clear existing star schema data
DELETE FROM [CricketDB].[dbo].[MatchPlayerBridge];
DELETE FROM [CricketDB].[dbo].[MatchDateBridge];
DELETE FROM [CricketDB].[dbo].[MatchInningsBridge];
DELETE FROM [CricketDB].[dbo].[FactMatch];
DELETE FROM [CricketDB].[dbo].[DimWicket];
DELETE FROM [CricketDB].[dbo].[DimDeliveries];
DELETE FROM [CricketDB].[dbo].[DimOvers];
DELETE FROM [CricketDB].[dbo].[DimInnings];
DELETE FROM [CricketDB].[dbo].[DimTeam];
DELETE FROM [CricketDB].[dbo].[DimPlayer];
DELETE FROM [CricketDB].[dbo].[DimCity];


-- Clear temporary tables if they exist
IF OBJECT_ID('tempdb..#temp_players') IS NOT NULL
    DROP TABLE #temp_players;

IF OBJECT_ID('tempdb..#temp_team1_players') IS NOT NULL
    DROP TABLE #temp_team1_players;

IF OBJECT_ID('tempdb..#temp_team2_players') IS NOT NULL
    DROP TABLE #temp_team2_players;

IF OBJECT_ID('tempdb..#temp_dates') IS NOT NULL
    DROP TABLE #temp_dates;

-- Populate DimDate

-- Declare the date range you want to seed
DECLARE @StartDate DATE = '2000-01-01';
DECLARE @EndDate DATE = '2030-12-31';

-- Create a temporary table to hold all dates in the range
-- Uses a Recursive CTE which creates a temporary table that is populated with date values until the end date is reached
WITH DateSequence AS (
    SELECT @StartDate AS DateValue
    UNION ALL
    SELECT DATEADD(DAY, 1, DateValue)
    FROM DateSequence
    WHERE DateValue < @EndDate
)

-- Insert into DimDate
INSERT INTO [CricketDB].[dbo].[DimDate] (date, day_of_week, day_of_month, month, year, quarter, day_name, month_name, is_weekend)
SELECT
    DateValue AS date,                                -- Date
    DATEPART(WEEKDAY, DateValue) AS day_of_week,      -- Day of the week (1=Sunday, 7=Saturday)
    DATEPART(DAY, DateValue) AS day_of_month,         -- Day of the month (1-31)
    DATEPART(MONTH, DateValue) AS month,              -- Month (1-12)
    DATEPART(YEAR, DateValue) AS year,                -- Year
    DATEPART(QUARTER, DateValue) AS quarter,          -- Quarter (1-4)
    DATENAME(WEEKDAY, DateValue) AS day_name,         -- Day name (e.g., 'Monday')
    DATENAME(MONTH, DateValue) AS month_name,         -- Month name (e.g., 'January')
    CASE
        WHEN DATEPART(WEEKDAY, DateValue) IN (1, 7) THEN 1  -- Weekend (1 for weekend, 0 for weekday)
        ELSE 0
    END AS is_weekend
FROM DateSequence
OPTION (MAXRECURSION 0);  -- Remove recursion limit




-- Populate DimTeam from staging
INSERT INTO [CricketDB].[dbo].[DimTeam] (team_name)
	SELECT DISTINCT team1
		FROM [CricketDBStaging].[dbo].[stg_matches]
	UNION 
	SELECT DISTINCT team2
		FROM [CricketDBStaging].[dbo].[stg_matches]
		WHERE team1 NOT IN (SELECT team_name FROM [CricketDB].[dbo].[DimTeam]) AND team2 NOT IN (SELECT team_name FROM [CricketDB].[dbo].[DimTeam]);


-- Populate DimPlayer from staging
SELECT team1_players
INTO #temp_players
FROM
(SELECT DISTINCT team1_players
		FROM [CricketDBStaging].[dbo].[stg_matches]
	UNION 
	SELECT DISTINCT team2_players
		FROM [CricketDBStaging].[dbo].[stg_matches]) AS players_combined

INSERT INTO [CricketDB].[dbo].[DimPlayer] (player_name)
	SELECT DISTINCT(REPLACE(REPLACE(REPLACE(TRIM(value), '"', ''), '[', ''), ']', '')) AS player
	FROM #temp_players
	CROSS APPLY STRING_SPLIT(team1_players, ',')
	UNION
	SELECT DISTINCT(player_out) FROM [CricketDBStaging].[dbo].[stg_wickets]
	UNION
	SELECT DISTINCT(batter) FROM [CricketDBStaging].[dbo].[stg_deliveries]
	UNION
	SELECT DISTINCT(bowler) FROM [CricketDBStaging].[dbo].[stg_deliveries]
	UNION
	SELECT DISTINCT(non_striker) FROM [CricketDBStaging].[dbo].[stg_deliveries]



-- Populate DimCity from staging
INSERT INTO [CricketDB].[dbo].[DimCity](city)
	SELECT DISTINCT(city)
	FROM [CricketDBStaging].[dbo].[stg_matches];


-- Populate DimInnings from staging
INSERT INTO [CricketDB].[dbo].[DimInnings](innings_id, innings_number, team_id)
	SELECT innings_id, innings_number, team_id
	FROM [CricketDBStaging].[dbo].[stg_innings] AS SI
	INNER JOIN [CricketDB].[dbo].[DimTeam] AS DT
	ON SI.team = DT.team_name


-- Popultae DimOvers from staging
INSERT INTO [CricketDB].[dbo].[DimOvers](over_id, innings_id, over_number)
	SELECT over_id, innings_id, over_number
	FROM [CricketDBStaging].[dbo].[stg_overs]


-- Popultae DimDeliveries from staging
INSERT INTO [CricketDB].[dbo].[DimDeliveries](delivery_id, over_id, delivery_number, bowler_id, batsman_id, non_striker_id, total_runs, batter_runs, extras, wicket_taken)
	SELECT SD.delivery_id, SD.over_id, SD.delivery_number, DP1.player_id, DP2.player_id, DP3.player_id, SD.total_runs, SD.batter_runs, SD.extras, SD.wicket_taken
	FROM [CricketDBStaging].[dbo].[stg_deliveries] AS SD
		INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP1
		ON SD.bowler = DP1.player_name
		INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP2
		ON SD.batter = DP2.player_name
		INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP3
		ON SD.non_striker = DP3.player_name


-- Popultae DimWicket from staging
INSERT INTO [CricketDB].[dbo].[DimWicket](wicket_id, delivery_id, batsman_out_id, kind)
	SELECT wicket_id, delivery_id, DP1.player_id, kind
	FROM [CricketDBStaging].[dbo].[stg_wickets] AS SW
		INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP1
		ON SW.player_out = DP1.player_name


-- Popultae FactMatch from staging
INSERT INTO [CricketDB].[dbo].[FactMatch](match_id, city_id, match_type, result, team1_id, team2_id, winning_team_id, win_type, win_margin, event_name)
	SELECT match_id, CT1.city_id, match_type, result, TE1.team_id, TE2.team_id, TE3.team_id, win_type, win_margin, event_name
	FROM [CricketDBStaging].[dbo].[stg_matches] AS MA
		LEFT OUTER JOIN [CricketDB].[dbo].[DimCity] AS CT1
		ON MA.city = CT1.city
		LEFT OUTER JOIN [CricketDB].[dbo].[DimTeam] AS TE1
		ON MA.team1 = TE1.team_name
		LEFT OUTER JOIN [CricketDB].[dbo].[DimTeam] AS TE2
		ON MA.team2 = TE2.team_name
		LEFT OUTER JOIN [CricketDB].[dbo].[DimTeam] AS TE3
		ON MA.winning_team = TE3.team_name


-- Populate MatchDateBridge
SELECT match_id, date
INTO #temp_dates
FROM
	(SELECT match_id, REPLACE(REPLACE(REPLACE(TRIM(value), '"', ''), '[', ''), ']', '') AS date
	FROM [CricketDBStaging].[dbo].[stg_matches] AS MA
	CROSS APPLY STRING_SPLIT(match_date, ',')) AS temp_stuff

INSERT INTO [CricketDB].[dbo].[MatchDateBridge](match_id, date_id)
	SELECT match_id, date_id
	FROM #temp_dates AS TD
	INNER JOIN [CricketDB].[dbo].[DimDate] AS DD
	ON TD.date = DD.date


-- Populate MatchPlayerBridge
SELECT *
INTO #temp_team1_players
FROM
	(SELECT match_id, REPLACE(REPLACE(REPLACE(TRIM(value), '"', ''), '[', ''), ']', '') AS team1_players
	FROM [CricketDBStaging].[dbo].[stg_matches] AS MA
	CROSS APPLY STRING_SPLIT(team1_players, ',')) AS T1

SELECT *
INTO #temp_team2_players
FROM
	(SELECT match_id, REPLACE(REPLACE(REPLACE(TRIM(value), '"', ''), '[', ''), ']', '') AS team2_players
	FROM [CricketDBStaging].[dbo].[stg_matches] AS MA
	CROSS APPLY STRING_SPLIT(team2_players, ',')) AS T2

INSERT INTO [CricketDB].[dbo].[MatchPlayerBridge](player_id, match_id, team_id)
	SELECT DP.player_id, T1.match_id, team1_id AS team_id
	FROM #temp_team1_players AS T1 
	INNER JOIN [CricketDB].[dbo].[FactMatch] AS FM
	ON FM.match_id = T1.match_id 
	INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP
	ON T1.team1_players = DP.player_name
	UNION
	SELECT DP.player_id, T2.match_id, team2_id AS team_id 
	FROM #temp_team2_players AS T2
	INNER JOIN [CricketDB].[dbo].[FactMatch] AS FM
	ON FM.match_id = T2.match_id 
	INNER JOIN [CricketDB].[dbo].[DimPlayer] AS DP
	ON T2.team2_players = DP.player_name

--- Populate MatchInningsBridge
INSERT INTO [CricketDB].[dbo].[MatchInningsBridge](match_id, innings_id)
	SELECT match_id, innings_id
	FROM [CricketDBStaging].[dbo].[stg_innings]



--- Add in overs and runs totals
UPDATE [CricketDB].[dbo].[FactMatch]
SET [CricketDB].[dbo].[FactMatch].total_overs = RU.total_overs
FROM [CricketDB].[dbo].[FactMatch]
INNER JOIN (
	SELECT FM.match_id, COUNT(*) AS total_overs
	FROM [CricketDB].[dbo].[FactMatch] AS FM
	INNER JOIN [CricketDB].[dbo].[MatchInningsBridge] AS MIB
	ON FM.match_id = MIB.match_id
	INNER JOIN [CricketDB].[dbo].[DimInnings] AS DI
	ON MIB.innings_id = DI.innings_id
	INNER JOIN [CricketDB].[dbo].[DimOvers] AS DO
	ON DI.innings_id = DO.innings_id
	GROUP BY FM.match_id
) AS RU
ON [CricketDB].[dbo].[FactMatch].match_id = RU.match_id


UPDATE [CricketDB].[dbo].[FactMatch]
SET [CricketDB].[dbo].[FactMatch].total_runs = RU.total_runs
FROM [CricketDB].[dbo].[FactMatch]
INNER JOIN (
	SELECT FM.match_id, SUM(DD.total_runs) AS total_runs
	FROM [CricketDB].[dbo].[FactMatch] AS FM
	INNER JOIN [CricketDB].[dbo].[MatchInningsBridge] AS MIB
	ON FM.match_id = MIB.match_id
	INNER JOIN [CricketDB].[dbo].[DimInnings] AS DI
	ON MIB.innings_id = DI.innings_id
	INNER JOIN [CricketDB].[dbo].[DimOvers] AS DO
	ON DI.innings_id = DO.innings_id
	INNER JOIN [CricketDB].[dbo].[DimDeliveries] AS DD
	ON DO.over_id = DD.over_id
	GROUP BY FM.match_id
) AS RU
ON [CricketDB].[dbo].[FactMatch].match_id = RU.match_id

-- Commit the transaction if all operations were successful
COMMIT;