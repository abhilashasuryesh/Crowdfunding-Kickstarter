Use project;

describe projects; 

select * from projects; 

----# 1) Create date 
alter table projects add column created_date date after created_at;

UPDATE projects
SET created_date = DATE(FROM_UNIXTIME(created_at));

SELECT created_at, created_date
FROM projects
LIMIT 10;

SET sql_safe_updates=0;

-------# ----Finding first date and last date of project 
SELECT 
    MIN(created_date) AS min_date,
    MAX(created_date) AS max_date
FROM projects;

2)  Build a Calendar Table using the Date Column Created Date ( Which has Dates from Minimum Dates and Maximum Dates)

CREATE TABLE calendar (
    calendar_date DATE PRIMARY KEY);
  
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO calendar (calendar_date)
WITH RECURSIVE date_series AS (
    SELECT MIN(created_date) AS calendar_date
    FROM projects
    UNION ALL
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM date_series
    WHERE calendar_date < (SELECT MAX(created_date) FROM projects)
)
SELECT calendar_date
FROM date_series;
    
SELECT COUNT(*) FROM calendar;

SELECT MIN(calendar_date), MAX(calendar_date)
FROM calendar;

2)   Add all the below Columns in the Calendar Table using the Formulas.

ALTER TABLE calendar
ADD COLUMN year INT,
ADD COLUMN monthno INT,
ADD COLUMN monthfullname VARCHAR(20),
ADD COLUMN quarter VARCHAR(2),
ADD COLUMN yearmonth VARCHAR(10),
ADD COLUMN weekdayno INT,
ADD COLUMN weekdayname VARCHAR(10),
ADD COLUMN financial_month VARCHAR(5),
ADD COLUMN financial_quarter VARCHAR(5);

describe calendar;

UPDATE calendar
SET
    year = YEAR(calendar_date),
    monthno = MONTH(calendar_date),
    monthfullname = MONTHNAME(calendar_date),
    quarter = CONCAT('Q', QUARTER(calendar_date)),
    yearmonth = DATE_FORMAT(calendar_date, '%Y-%b'),
    weekdayno = DAYOFWEEK(calendar_date),
    weekdayname = DAYNAME(calendar_date),

    financial_month =
        CASE
            WHEN MONTH(calendar_date) >= 4
            THEN CONCAT('FM', MONTH(calendar_date) - 3)
            ELSE CONCAT('FM', MONTH(calendar_date) + 9)
        END,

    financial_quarter =
        CASE
            WHEN MONTH(calendar_date) BETWEEN 4 AND 6 THEN 'FQ1'
            WHEN MONTH(calendar_date) BETWEEN 7 AND 9 THEN 'FQ2'
            WHEN MONTH(calendar_date) BETWEEN 10 AND 12 THEN 'FQ3'
            ELSE 'FQ4'
        END;

SELECT * FROM calendar
LIMIT 10;
---------------------------------------------------------------------------------------------------------------------------------

 3) --- Build the Data Model using the attached Excel Files---
 
 SELECT
    p.ProjectID,
    p.name,
    p.created_date,
    c.year,
    c.monthfullname,
    c.financial_quarter
FROM projects p
JOIN calendar c
    ON p.created_date = c.calendar_date
LIMIT 10;

-------------------------------------

4. Convert the Goal amount into USD using the Static USD Rate.

SELECT DISTINCT currency
FROM projects;

ALTER TABLE projects
ADD COLUMN goal_usd_currency DECIMAL(15,2) after currency;

Setting goal amount in usd 

select * from projects;

UPDATE projects
SET goal_usd_currency =
    CASE
        WHEN currency = 'USD' THEN goal
        WHEN currency = 'INR' THEN goal / 90
        ELSE goal
    END;

#Test senorio 
 SELECT
    goal,
    currency,
    goal_usd_currency
FROM projects
LIMIT 10;


5) Total Number of Projects based on Outcome
SELECT state, COUNT(*) AS total_projects
FROM projects
GROUP BY state with rollup
ORDER BY total_projects DESC;

5) Total Number of Projects Based on Locations (country)--
SELECT country, COUNT(*) AS total_projects_countrywise
FROM projects
GROUP BY country
ORDER BY total_projects_countrywise DESC;

5) Total Number of Projects Based on Category --
SELECT
    category_id, 
    COUNT(*) AS total_projects
FROM projects
GROUP BY category_id
ORDER BY total_projects DESC; 

5) Total Number of Projects created by Year , Quarter , Month-----
a) Project By Year
SELECT
    c.year,
    COUNT(p.ProjectID) AS total_projects
FROM projects p
JOIN calendar c
    ON p.created_date = c.calendar_date
GROUP BY c.year
ORDER BY c.year;

b) Projects by Year & Quarter
SELECT
    c.year,
    c.quarter,
    COUNT(p.ProjectID) AS total_projects
FROM projects p
JOIN calendar c
    ON p.created_date = c.calendar_date
GROUP BY c.year, c.quarter
ORDER BY c.year, c.quarter;

c) Projects by Year & Month
SELECT
    c.year,
    c.monthfullname,
    COUNT(p.ProjectID) AS total_projects
FROM projects p
JOIN calendar c
    ON p.created_date = c.calendar_date
GROUP BY c.year, c.monthfullname
ORDER BY c.year, MIN(c.monthno);

6) ----Successful Projects-------
a) ---Total Amount Raised
SELECT
    SUM(usd_pledged) AS total_amount_raised
FROM projects
WHERE state = 'successful';

b) ---Total Backers
SELECT
    SUM(backers_count) AS total_backers
FROM projects
WHERE state = 'successful';

c) --- Average Campaign Duration (Days)--
SELECT
    AVG(
        DATEDIFF(
            FROM_UNIXTIME(deadline),
            FROM_UNIXTIME(launched_at)
        )
    ) AS avg_campaign_days
FROM projects
WHERE state = 'successful';

7) ----Top Successful Projects :
a) -------Based on Number of Backers----
SELECT
    ProjectID,
    name,
    backers_count
FROM projects
WHERE state = 'successful'
ORDER BY backers_count DESC
LIMIT 10;

b) ----Top by Amount Raised--
SELECT
    ProjectID,
    name,
    usd_pledged
FROM projects
WHERE state = 'successful'
ORDER BY usd_pledged DESC
LIMIT 10;


8) -----Overall Success Percentage ------
SELECT
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*) * 100
        AS success_percentage
FROM projects;

8) ------Success Percentage by Category-----
SELECT
    category_id,
    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*) *100 
        AS success_percentage
FROM projects
GROUP BY category_id;

8) --------Success Percentage by Year & Month----
SELECT
    c.year,
    c.monthfullname,
    SUM(CASE WHEN p.state = 'successful' THEN 1 ELSE 0 END) / COUNT(*) *100
        AS success_percentage
FROM projects p
JOIN calendar c
    ON p.created_date = c.calendar_date
GROUP BY c.year, c.monthfullname
ORDER BY c.year, MIN(c.monthno);

8) ---- Success Percentage by Goal Range (USD)-------
SELECT
    CASE
        WHEN goal_usd_currency < 5000 THEN 'Low Goal'
        WHEN goal_usd_currency BETWEEN 5000 AND 20000 THEN 'Medium Goal'
        ELSE 'High Goal'
    END AS goal_range,

    SUM(CASE WHEN state = 'successful' THEN 1 ELSE 0 END) / COUNT(*) * 100
        AS success_percentage
FROM projects
GROUP BY goal_range;

select * crowdfunding_location;

describe * crowdfunding_location;

