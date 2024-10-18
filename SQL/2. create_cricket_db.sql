-- Create or select the database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'CricketDB')
BEGIN
    CREATE DATABASE CricketDB;
END;
GO

-- Select the database
USE CricketDB;
GO

-- Drop existing tables if they exist (for a fresh start)
IF OBJECT_ID('MatchTeamBridge', 'U') IS NOT NULL DROP TABLE MatchTeamBridge;
IF OBJECT_ID('MatchPlayerBridge', 'U') IS NOT NULL DROP TABLE MatchPlayerBridge;
IF OBJECT_ID('MatchDateBridge', 'U') IS NOT NULL DROP TABLE MatchDateBridge;
IF OBJECT_ID('MatchInningsBridge', 'U') IS NOT NULL DROP TABLE MatchInningsBridge;
IF OBJECT_ID('FactMatch', 'U') IS NOT NULL DROP TABLE FactMatch;
IF OBJECT_ID('DimDate', 'U') IS NOT NULL DROP TABLE DimDate;
IF OBJECT_ID('DimCity', 'U') IS NOT NULL DROP TABLE DimCity;
IF OBJECT_ID('DimWicket', 'U') IS NOT NULL DROP TABLE DimWicket;
IF OBJECT_ID('DimDeliveries', 'U') IS NOT NULL DROP TABLE DimDeliveries;
IF OBJECT_ID('DimOvers', 'U') IS NOT NULL DROP TABLE DimOvers;
IF OBJECT_ID('DimInnings', 'U') IS NOT NULL DROP TABLE DimInnings;
IF OBJECT_ID('DimPlayer', 'U') IS NOT NULL DROP TABLE DimPlayer;
IF OBJECT_ID('DimTeam', 'U') IS NOT NULL DROP TABLE DimTeam;
GO


-- Create DimDate
CREATE TABLE DimDate (
    date_id INT PRIMARY KEY IDENTITY(1,1),
    date DATE NOT NULL,
    day_of_week INT NOT NULL,
    day_of_month INT NOT NULL,
    month INT NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    is_weekend BIT NOT NULL
);
GO

-- Create DimTeam
CREATE TABLE DimTeam (
    team_id INT PRIMARY KEY IDENTITY(1,1),
    team_name VARCHAR(255) NOT NULL
);
GO

-- Create DimPlayer
CREATE TABLE DimPlayer (
    player_id INT PRIMARY KEY IDENTITY(1,1),
    player_name VARCHAR(255) NOT NULL
);
GO

-- Create DimVenue
CREATE TABLE DimCity (
    city_id INT PRIMARY KEY IDENTITY(1,1),
    city VARCHAR(255) NOT NULL,
);
GO

-- Create DimInnings
CREATE TABLE DimInnings (
    innings_id INT PRIMARY KEY,
    innings_number INT NOT NULL,   -- 1st innings, 2nd innings, etc.
    team_id INT NOT NULL,          -- Batting team
    FOREIGN KEY (team_id) REFERENCES DimTeam(team_id)
);
GO

-- Create DimOver
CREATE TABLE DimOvers (
    over_id INT PRIMARY KEY,
    innings_id INT NOT NULL,
    over_number INT NOT NULL,
    FOREIGN KEY (innings_id) REFERENCES DimInnings(innings_id)
);
GO

-- Create DimDelivery
CREATE TABLE DimDeliveries (
    delivery_id INT PRIMARY KEY,
    over_id INT NOT NULL,
    delivery_number INT NOT NULL,
    bowler_id INT NOT NULL,
    batsman_id INT NOT NULL,
	non_striker_id INT NOT NULL,
    total_runs INT NOT NULL,
	batter_runs INT NOT NULL,
    extras INT DEFAULT 0,    -- Byes, leg-byes, no-balls, etc.
	wicket_taken BIT DEFAULT 0,
    FOREIGN KEY (over_id) REFERENCES DimOvers(over_id),
    FOREIGN KEY (bowler_id) REFERENCES DimPlayer(player_id),
    FOREIGN KEY (batsman_id) REFERENCES DimPlayer(player_id),
	FOREIGN KEY (non_striker_id) REFERENCES DimPlayer(player_id)
);
GO

-- Create DimWicket
CREATE TABLE DimWicket (
    wicket_id INT PRIMARY KEY,
    delivery_id INT NOT NULL,
    batsman_out_id INT NOT NULL,
    kind VARCHAR(50),    -- Caught, Bowled, LBW, etc.
    FOREIGN KEY (delivery_id) REFERENCES DimDeliveries(delivery_id),
    FOREIGN KEY (batsman_out_id) REFERENCES DimPlayer(player_id)
);
GO

-- Create FactMatch
CREATE TABLE FactMatch (
    match_id INT PRIMARY KEY,
    city_id INT NOT NULL,
	match_type NVARCHAR(50),
	result NVARCHAR(50),
    team1_id INT NOT NULL,
    team2_id INT NOT NULL,
    total_overs INT,
    total_runs INT,
    winning_team_id INT,
	win_type NVARCHAR(50),
	win_margin INT,
	event_name NVARCHAR(MAX),
    FOREIGN KEY (city_id) REFERENCES DimCity(city_id),
    FOREIGN KEY (winning_team_id) REFERENCES DimTeam(team_id)
);
GO

-- Create MatchPlayerBridge
CREATE TABLE MatchPlayerBridge (
    player_id INT NOT NULL,
	match_id INT NOT NULL,
	team_id INT NOT NULL,
	PRIMARY KEY (match_id, player_id, team_id),
	FOREIGN KEY (match_id) REFERENCES FactMatch(match_id),
	FOREIGN KEY (team_id) REFERENCES DimTeam(team_id),
	FOREIGN KEY (player_id) REFERENCES DimPlayer(player_id)
);
GO

-- Create MatchDateBridge
CREATE TABLE MatchDateBridge (
    match_id INT NOT NULL,
    date_id INT NOT NULL,
    PRIMARY KEY (match_id, date_id),
    FOREIGN KEY (match_id) REFERENCES FactMatch(match_id),
    FOREIGN KEY (date_id) REFERENCES DimDate(date_id)
);
GO

-- Create MatchDateBridge
CREATE TABLE MatchInningsBridge (
    match_id INT NOT NULL,
    innings_id INT NOT NULL,
    PRIMARY KEY (match_id, innings_id),
    FOREIGN KEY (match_id) REFERENCES FactMatch(match_id),
    FOREIGN KEY (innings_id) REFERENCES DimInnings(innings_id)
);
GO

