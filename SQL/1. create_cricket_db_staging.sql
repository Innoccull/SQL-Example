-- Create staging database
-- Create or select the database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CricketDBStaging')
BEGIN
    CREATE DATABASE CricketDBStaging;
END;
GO

-- Select the database
USE CricketDBStaging;
GO

-- Drop existing tables if they exist (for a fresh start)
IF OBJECT_ID('stg_wickets', 'U') IS NOT NULL DROP TABLE stg_wickets;
IF OBJECT_ID('stg_deliveries', 'U') IS NOT NULL DROP TABLE stg_deliveries;
IF OBJECT_ID('stg_overs', 'U') IS NOT NULL DROP TABLE stg_overs;
IF OBJECT_ID('stg_innings', 'U') IS NOT NULL DROP TABLE stg_innings;
IF OBJECT_ID('stg_matches', 'U') IS NOT NULL DROP TABLE stg_matches;
GO


CREATE TABLE stg_matches (
    match_id INT PRIMARY KEY IDENTITY(1,1),
    match_date NVARCHAR(MAX),
    city NVARCHAR(100),
	match_type NVARCHAR(50),
	result NVARCHAR(50),
    team1 NVARCHAR(50),
    team2 NVARCHAR(50),
    winning_team NVARCHAR(50),
	win_type NVARCHAR(50),
	win_margin NVARCHAR(50),
	event_name NVARCHAR(MAX),
	team1_players NVARCHAR(MAX),
	team2_players NVARCHAR(MAX),
	source_filename NVARCHAR(50),
	load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
GO

-- Create table for innings
CREATE TABLE stg_innings (
    innings_id INT PRIMARY KEY IDENTITY(1,1),
    match_id INT,
	innings_number INT,
    team NVARCHAR(100) NOT NULL,
	load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (match_id) REFERENCES stg_matches(match_id),
);
GO

-- Create table for overs
CREATE TABLE stg_overs (
    over_id INT PRIMARY KEY IDENTITY(1,1),
    innings_id INT,
    over_number INT,
	load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (innings_id) REFERENCES stg_innings(innings_id)
);
GO

CREATE TABLE stg_deliveries (
    delivery_id INT PRIMARY KEY IDENTITY(1,1),
    over_id INT,
    batter NVARCHAR(100),
    bowler NVARCHAR(100),
	non_striker NVARCHAR(100),
	delivery_number INT,
    total_runs INT,
	batter_runs INT,
    extras INT,
    wicket_taken BIT DEFAULT 0,
	load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (over_id) REFERENCES stg_overs(over_id)
);
GO

CREATE TABLE stg_wickets (
    wicket_id INT PRIMARY KEY IDENTITY(1,1),
	delivery_id INT,
    player_out NVARCHAR(100),
    kind NVARCHAR(100),
	load_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (delivery_id) REFERENCES stg_deliveries(delivery_id)
);
GO