/*
DATA 607 WEEK 3 HOMEWORK
SQL CODE INSERT
BY ARMENOUSH ASLANIAN-PERSICO

*/
-- 0. Check file location.
SHOW VARIABLES LIKE 'secure_file_priv';

-- 1. If the schema does not exist, create it.
CREATE SCHEMA IF NOT EXISTS tb;

-- 2. Load tuberculosis data.
-- 2a. Create a temporary CSV holding table for tb.
DROP TABLE IF EXISTS tb;
CREATE TABLE tb 
(
  country varchar(100) NOT NULL,
  year int NOT NULL,
  sex varchar(6) NOT NULL,
  child int NULL,
  adult int NULL,
  elderly int NULL
);
-- 2b. Load the CSV file.
LOAD DATA LOCAL INFILE 'C:/data/tb.csv' 
	INTO TABLE tb
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
	(country, year, sex, @child, @adult, @elderly)
	SET
-- 2c. Assign a null value to any negative values.
	child = nullif(@child,-1),
	adult = nullif(@adult,-1),
	elderly = nullif(@elderly,-1)
	;

-- 3. View the head of the temporary table, selecting all columns.
SELECT * 
FROM tb
ORDER BY year ASC, country ASC 
LIMIT 10;


-- 4. Load population data.
-- 4a. Create a temporary CSV holding table for pop.
DROP TABLE IF EXISTS pop;
CREATE TABLE pop
(
  country varchar(100) NOT NULL,
  year int NOT NULL,
  population int NOT NULL
);
-- 4b. Load the CSV file.
LOAD DATA LOCAL INFILE 'C:/data/population.csv' 
	INTO TABLE pop
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\n'
-- 4c. Ignore the column header row.
	IGNORE 1 LINES
	(country, year, population);

-- 5. View the head of the temporary table, selecting all columns.
SELECT * 
FROM pop
ORDER BY year ASC, country ASC LIMIT 10;

-- 6. Check for duplicates before creating join.
-- 6a. Compare countries in both tables. 
SELECT country AS Unmatching_Country_TbTable 
FROM tb 
WHERE (country) NOT IN 
(SELECT country FROM pop);
SELECT country AS Unmatching_Country_PopTable 
FROM pop
WHERE (country) NOT IN 
(SELECT country FROM tb );
-- 6b. Compare years in both tables.
SELECT year AS Unmatching_Year_TbTable 
FROM tb 
WHERE (year) NOT IN 
(SELECT year FROM pop);
SELECT year AS Unmatching_Year_PopTable FROM pop
WHERE (year) NOT IN 
(SELECT year FROM tb );
      
-- 7. Import temporary tables into working tables.
-- 7a. Create a working table for tb data.
DROP TABLE IF EXISTS tb1;
CREATE TABLE tb1
	(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	combocy VARCHAR(100) NOT NULL,
	combocys VARCHAR(100) NOT NULL,
	country VARCHAR(100) NOT NULL,
	year INT NOT NULL,
	sex varchar(6) NOT NULL,
	child INT NULL,
	adult INT NULL,
	elderly INT NULL,
	d_total INT NULL
	);
-- 7b. Create a working table for population data.
DROP TABLE IF EXISTS pop1;
CREATE TABLE pop1
	(
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	combocy VARCHAR(100) NOT NULL,
	country VARCHAR(100) NOT NULL,
	year INT NOT NULL,
	population INT NOT NULL
	);
-- 7c. Paste the temporary table information into the working table tb1.
INSERT INTO tb1 
	(
	combocy, 
	combocys, 
	country, 
	year, 
	sex, 
	child, 
	adult, 
	elderly, 
	d_total)  
SELECT 
	CONCAT(country,'_',year), 
	CONCAT(country,'_',year,'_',sex), 
	country, 
	year, 
	sex, 
	child, 
	adult, 
	elderly, 
	child+adult+elderly
FROM tb;
-- 7d. Paste the temporary table information into the working table pop1.
INSERT INTO pop1 
(
	combocy, 
	country, 
	year, 
	population
)  
SELECT 
	CONCAT(country,'_',year), 
	country, 
	year, 
	population
FROM pop;
  
  -- 8a. View the head of the tb working table, selecting all columns.
SELECT *
FROM tb1
ORDER BY id ASC
LIMIT 30;
-- 8b. View the head of the pop working table, selecting all columns.
SELECT *
FROM pop1
ORDER BY id ASC 
LIMIT 30;

-- 9a. Check for combocy duplicates in pop1.
SELECT combocy, COUNT(combocy) AS Duplicate_Combo_Names_pop1
FROM pop1
GROUP BY combocy
HAVING ( COUNT(combocy) > 1 )
LIMIT 30;
-- 9b. Check that each combocy appears only twice in tb1.
SELECT combocy, COUNT(combocy) AS Duplicate_Combo_Names_tb1
FROM tb1
GROUP BY combocy
HAVING (COUNT(combocy) > 2 OR COUNT(combocy) < 2)
LIMIT 30;
-- 9c. Check for combocys duplicates in tb1.
SELECT combocys, COUNT(combocys) Duplicate_Combo_Names_2_tb1
FROM tb1
GROUP BY combocys
HAVING (COUNT(combocys) > 1)
LIMIT 30;

-- 10. View male and female cases on separate rows.
SELECT * FROM tb1
ORDER BY year ASC, country ASC
LIMIT 100;

-- 11. Create a table for male and female cases combined.
DROP TABLE IF EXISTS tb2;
CREATE TABLE tb2 AS
SELECT 
	combocy AS cid,
	country AS loc,
	year AS yr,
	SUM(child) AS d1,
	SUM(adult) AS d2,
	SUM(elderly) AS d3,
	SUM(d_total) AS dt
FROM tb1
GROUP BY combocy;

SELECT *
FROM tb2
ORDER BY yr ASC, loc ASC
LIMIT 30;

-- 12. Join with population table.
-- 12a. View highest rates.
SELECT
	tb2.cid,
	tb2.loc,
	tb2.yr,
	tb2.d1,
	tb2.d2,
	tb2.d3,
	tb2.dt,
	pop1.population,
	tb2.dt/pop1.population AS rate
FROM tb2
LEFT JOIN pop1
ON tb2.cid=pop1.combocy
ORDER BY rate DESC;
-- 12b. View total cases by year.
SELECT
	tb2.yr,
	SUM(tb2.dt)
FROM tb2
GROUP BY tb2.yr
ORDER BY tb2.yr ASC;

-- 13. Create table for export.
DROP TABLE IF EXISTS tb3;
CREATE TABLE tb3 AS
SELECT
	tb2.cid,
	tb2.loc,
	tb2.yr,
	tb2.d1,
	tb2.d2,
	tb2.d3,
	tb2.dt,
	pop1.population,
	tb2.dt/pop1.population AS rate
FROM tb2
LEFT JOIN pop1
ON tb2.cid=pop1.combocy;
-- 13a. View table head.
SELECT *
FROM tb3
ORDER BY yr ASC, loc ASC
LIMIT 30;

-- 14. Export into CSV file.
SELECT * 
FROM tb3
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 5.7/Uploads/tb3.csv' 
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\n'
