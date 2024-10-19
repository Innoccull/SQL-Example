-- ##########################################################
-- Script Name: Cricket Data Statistics
-- Author: Chris Rodgers
-- Date: 2024-10-19
-- Purpose: Variety of SQL queries on Cricket star schema to demonstrate range of SQL skills
-- ##########################################################

--- Includes the following queries
--- QUERY 1: List all matches played in Sydney
--- QUERY 2: Total wickets taken in each match
--- QUERY 3: List all players who have played for Pakistan
--- QUERY 4: Total wickets taken by each bowler in a given year
--- QUERY 5: Top scorer for each match
--- QUERY 6: Average runs per over for each bowler
--- QUERY 7: List all centuries scored by all players
--- QUERY 8: Highest win margin for each team
--- QUERY 9: The player(s) who took the most wickets in an event (e.g. world cup, test series)
--- QUERY 10: List all high scoring matches (matches where the total runs is 1.5 times the average runs for that match type)

------------------------------------------------------------------------------------
--- QUERY 1
--- List all matches played in Sydney
--- Demonstrates simple SELECT query with WHERE clause
SELECT 
	*
FROM
	FactMatch FM
INNER JOIN
	DimCity DC
	ON FM.city_id = DC.city_id
WHERE
	DC.city = 'Sydney'

--- QUERY 2
--- Total wickets taken in a match
--- Demonstrates use of SUM() with GROUP BY and CAST
SELECT 
	FM.match_id, SUM(CAST(DD.wicket_taken AS INT)) AS TotalWicketsTaken
FROM
	FactMatch FM
INNER JOIN
	MatchInningsBridge MIB
	ON FM.match_id = MIB.match_id
INNER JOIN
	DimInnings DI
	ON MIB.innings_id = DI.innings_id
INNER JOIN
	DimOvers DO
	ON DI.innings_id = DO.innings_id
INNER JOIN 
	DimDeliveries DD
	ON DO.over_id = DD.over_id
GROUP BY FM.match_id


--- QUERY 3 
--- Find all the players who played for Pakistan
--- Demonstrates basic joins and filtering with DISTINCT
SELECT 
	DISTINCT(player_name)
FROM
	FactMatch FM
INNER JOIN
	MatchPlayerBridge MPB
	ON FM.match_id = MPB.match_id
INNER JOIN
	DimPlayer DP
	ON MPB.player_id = DP.player_id
INNER JOIN
	DimTeam DT
	ON MPB.team_id = DT.team_id
WHERE DT.team_name = 'Pakistan'


--- QUERY 4 
--- Total wickets taken by each bowler in a year
--- Demonstrates joins, SUM() and filtering with WHERE
SELECT 
	player_name, COUNT(*) AS TotalWicketsTaken
FROM
	DimDeliveries DD
INNER JOIN 
	DimWicket DW
	ON DD.delivery_id = DW.delivery_id
INNER JOIN
	DimOvers DO
	ON DD.over_id = DO.over_id
INNER JOIN
	DimInnings DI
	ON DO.innings_id = DI.innings_id
INNER JOIN
	MatchInningsBridge MIB
	ON DO.innings_id = MIB.innings_id
INNER JOIN 
	FactMatch FM
	ON MIB.match_id = FM.match_id
INNER JOIN 
	MatchDateBridge MDB
	ON FM.match_id = MDB.match_id
INNER JOIN
	DimDate DDT
	ON MDB.date_id = DDT.date_id
INNER JOIN 
	DimPlayer DP
	ON DD.bowler_id = DP.player_id
WHERE DW.kind NOT IN ('retired hurt', 'run out', 'retired not out') AND ddt.date BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY player_name
ORDER BY COUNT(*) DESC



--- QUERY 5
--- Top scorers from each match
--- Demonstrate use of GROUP BY and PARTITION BY

WITH GroupSums As (
	SELECT 
	FM.match_id, DI.innings_id, batsman_id, SUM(batter_runs) AS TotalRuns
	FROM
		FactMatch FM
	INNER JOIN
		MatchInningsBridge MIB
		ON FM.match_id = MIB.match_id
	INNER JOIN
		DimInnings DI
		ON MIB.innings_id = DI.innings_id
	INNER JOIN
		DimOvers DO
		ON DI.innings_id = DO.innings_id
	INNER JOIN 
		DimDeliveries DD
		ON DO.over_id = DD.over_id
	GROUP BY FM.match_id, DI.innings_id, DD.batsman_id
),
RankedGroups AS (
	SELECT
	match_id, innings_id, batsman_id, TotalRuns,
	ROW_NUMBER() OVER (PARTITION BY match_id, innings_id ORDER BY TotalRuns DESC) AS RowNum
	FROM
		GroupSums
)
SELECT
	match_id, innings_id, batsman_id, TotalRuns
FROM 
	RankedGroups
WHERE
	RowNum = 1;


--- QUERY 6
--- Average runs per over for each bowler
--- Demonstrate use of several calculated columns

SELECT 
	player_name, 
	COUNT(DISTINCT(over_id)) AS TotalOvers, 
	SUM(total_runs) AS TotalRunsConceded, 
	((SUM(total_runs))/COUNT(DISTINCT(over_id))) AS AverageRPO
FROM 
	DimDeliveries DD
INNER JOIN 
	DimPlayer DP ON DD.bowler_id = DP.player_id
GROUP BY player_name



--- QUERY 7
--- Identify all centuries scored by players
--- Demonstrates using HAVING and SUM() to find all players that meet an aggregated condition

SELECT 
	FM.match_id, 
	DI.innings_id, 
	player_name, 
	SUM(batter_runs) AS TotalRuns
FROM
	FactMatch FM
INNER JOIN
	MatchInningsBridge MIB 
	ON FM.match_id = MIB.match_id
INNER JOIN
	DimInnings DI 
	ON MIB.innings_id = DI.innings_id
INNER JOIN 
	DimOvers DO 
	ON DI.innings_id = DO.innings_id
INNER JOIN 
	DimDeliveries DD 
	ON DO.over_id = DD.over_id
INNER JOIN
	DimPlayer DP
	ON DD.batsman_id = DP.player_id
GROUP BY FM.match_id, DI.innings_id, DP.player_name
HAVING SUM(batter_runs) > 100
ORDER BY SUM(batter_runs) DESC


--- QUERY 8
--- Highest win margin for each team
--- Use of window function, filtering and joins


SELECT 
	team_name, win_type, win_margin, event_name
FROM (
	SELECT
		*,
		RANK() OVER (PARTITION BY winning_team_id, win_type ORDER BY win_margin DESC) AS rank
	FROM
		FactMatch FM
	WHERE
		winning_team_id is not NULL 
) ranked
INNER JOIN
	DimTeam DT
	ON ranked.winning_team_id = DT.team_id
WHERE 
	rank = 1
AND 
	win_type IN ('runs', 'wickets')


--- QUERY 9
--- The player(s) who took the highest amount of wickets in an event
--- Use of window function, subquery and basic filter

SELECT
	*
FROM (
	SELECT 
		FM.event_name, 
		DP.player_name, 
		COUNT(*) As wickets_taken,
		DENSE_RANK() OVER (PARTITION BY event_name ORDER BY COUNT(*) DESC) AS rank
	FROM
		FactMatch FM
	INNER JOIN
		MatchInningsBridge MIB 
		ON FM.match_id = MIB.match_id
	INNER JOIN
		DimInnings DI 
		ON MIB.innings_id = DI.innings_id
	INNER JOIN 
		DimOvers DO 
		ON DI.innings_id = DO.innings_id
	INNER JOIN 
		DimDeliveries DD 
		ON DO.over_id = DD.over_id
	INNER JOIN
		DimPlayer DP
		ON DD.bowler_id = DP.player_id
	WHERE 
		wicket_taken = 1
		AND
		event_name is not NULL
	GROUP BY event_name, player_name
) AS ranked_wickets
WHERE
	rank = 1


--- Query 10
--- Matches that score well above (1.5 times) the average number of runs
--- Uses aggregate functions, subquery and where filter

SELECT 
	match_id, FM.match_type, total_runs, event_name
FROM FactMatch FM
INNER JOIN
	(
		SELECT match_type, SUM(total_runs)/COUNT(*) AS avg_runs_per_match
		FROM FactMatch
		GROUP BY match_type
	) AS AvgScore
ON FM.match_type = AvgScore.match_type
WHERE total_runs > (avg_runs_per_match * 1.5)
ORDER BY match_type, total_runs