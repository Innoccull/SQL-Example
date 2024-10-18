# SQL and Python for Loading and Querying Cricket Data

This repository includes Python and SQL code that demonstrates competency in loading data to a star schema in SQL and performing queries on that data. 

JSON data on cricket matches spanning the past 20 years was obtained from https://cricsheet.org/ (approximately 17,700 JSON files, each file representing a single match). Python was used to read, process and load those JSON files to SQL server, SQL was used to create databases, load, transform and query the cricket match data.

Collectively, this demonstrates an end-to-end load, transformation and use of data. The specific compentencies displayed include:
- Utilising Python to load and flatten JSON files and load them to a SQL database
- Data modelling a star schema database to support querying information
- SQL for creating databases 
- SQL for data extraction, transforming and loading to databases
- SQL for information querying utilising various techniques (e.g. JOINS, FILTERS, GROUPING, RANKING)



The table below shows the files included in this respository.

| File name                         | Type   | Purpose                                                                                      |
|-----------------------------------|--------|----------------------------------------------------------------------------------------------|
| 1. create_cricket_db_staging      | SQL    | Create staging database - JSON is loaded here with Python script                             |
| 2. create_cricket_db              | SQL    | Create star schema database - populated from staging database                                |
| 3. tidy_staging                   | SQL    | Performs some basic data cleansing of data in staging                                        |
| 4. populate_dim_date              | SQL    | Populates the date dimension in the star schema                                              |
| 4. populate_star_schema           | SQL    | Populates all Fact, Bridge and Dimension tables in the star schema from staging data         |
| 5. check_star_schema_load         | SQL    | Performs several data quality checks of staging to identify any potential errors             |
| 6. information_extraction_queries | SQL    | Several queries to extract information on cricket matches from the newly created star schema |
| load_json_staging                 | Python | Loads JSON source files to the staging database                                              |
