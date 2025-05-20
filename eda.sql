-- Let's look at the first and last hire
SELECT MAX(Hiredate), MIN(Hiredate)
FROM hr_staging;

-- Last Hire     First Hire
-- 2024-12-29    2015-01-01

-- We have almost 10 year range of data

-- Total number of hired employees by year
SELECT YEAR(Hiredate), COUNT(*) FROM hr_staging
GROUP BY YEAR(Hiredate)
ORDER BY YEAR(Hiredate);

-- Year         Amount of Hired
--2015          472
--2016          729
--2017          1560
--2018          850
--2019          902
--2020          968
--2021          422
--2022          1042
--2023          1201
--2024          804

-- MAX : 2017 (1560)
-- MIN: 2021 (422)


-- Total amount of active employees by year
SELECT YEAR(Hiredate), COUNT(*) FROM hr_staging
WHERE Termdate IS NULL
GROUP BY YEAR(Hiredate)
ORDER BY YEAR(Hiredate);

-- Year         Amount of Active
--2015          430
--2016          653
--2017          1355
--2018          709
--2019          804
--2020          858
--2021          382
--2022          907
--2023          1134
--2024          752

-- MAX : 2017 (1355)
-- MIN : 2021 (382)

-- Total amount of terminated employees by year
SELECT YEAR(Termdate), COUNT(*) FROM hr_staging
WHERE Termdate IS NOT NULL
GROUP BY YEAR(Termdate)
ORDER BY YEAR(Termdate);

--Year          Amount of Terminated
--2015          1
--2016          11
--2017          8
--2018          120
--2019          125
--2020          98
--2021          162
--2022          125
--2023          174
--2024          142

-- MAX : 2023 (174)
-- MIN : 2015 (1)


-- Let's look at the highest paid employee at each department and rank them based on salary

WITH max_salary AS (
    SELECT Department, MAX(Salary) AS max_sal
FROM hr_staging WHERE Termdate = ''
GROUP BY Department
)

SELECT
DENSE_RANK() OVER( ORDER BY max_sal DESC) AS Ranking,
hr_staging2.Department,
'First Name',
'Last Name',
'Job Title',
'Education Level',
Hiredate,
Salary
FROM max_salary
LEFT JOIN hr_staging AS hr_staging2
ON max_sal = hr_staging2.Salary AND max_salary.Department = hr_staging2.Department
ORDER BY SALARY DESC;

-- Ranking, Department, First Name, Last Name, Job Title, Education Level, Hiredate, Salary
-- 1, Finance, Kristina Gardner, Finance Manager, PhD, 11/03/2017, 149377
-- 2, Sales, Michelle Ayers, Sales Manager, PhD, 11/02/2018, 135055
-- 3, IT, Holly Gray, IT Manager, Master, 05/09/2017, 133425
-- 4, Operations, Brian Vazquez, Operations Manager, Bachelor, 27/10/2016, 115534
-- 5, Marketing, Douglas Stevens, Marketing Manager, Bachelor, 03/10/2024, 110729
-- 6, Customer Service, Daniel James, Customer Service Manager, Bachelor, 29/10/2017, 104359
-- 7, HR, Wendy Moreno, HR Manager, Master, 16/04/2018, 82203

-- Let's check if average salary by department matches max salary rank

SELECT Department , AVG(Salary) FROM hr_staging GROUP BY Department
ORDER BY AVG(Salary) DESC;

--Department, AVG(Salary)
-- IT, 81925.6078
-- Finance, 76451.1438
-- Sales, 76204.9477
-- Marketing, 67659.0237
-- Customer Service, 65837.7286
-- Operations, 65400.2502
-- HR, 64145.0349

-- For the average salary the Ranking of departments is different different

-- Explore termination ratios across education levels
WITH Education_Hired
AS (
SELECT `Education Level`, COUNT(*) AS hired,
(COUNT(*) / (select count(*) from hr_staging WHERE Termdate IS NULL) * 100) AS Percentage_Hired
FROM hr_staging
WHERE Termdate IS NULL
GROUP BY `Education Level`),
Education_Terminated AS
(
SELECT `Education Level`, COUNT(*) AS term,
(COUNT(*) / (select count(*) from hr_staging WHERE Termdate IS NOT NULL) * 100) AS Percentage_Terminated
FROM hr_staging
WHERE Termdate IS NOT NULL
GROUP BY `Education Level`)

SELECT eh.`Education Level` ,
eh.hired, et.term,
ROUND(CAST(et.term AS FLOAT) / eh.hired, 3) AS termination_ratio
FROM Education_Hired eh
JOIN Education_Terminated et ON eh.`Education Level` = et.`Education Level` ORDER BY termination_ratio DESC;

-- Bachelor’s degree holders have the highest termination-to-hire ratio (12.6%),
 -- while PhD holders have the lowest (10.4%)
 -- Masters and High School education holders have moderate ration at about 11.5%

-- Explore termination ratios across departments
WITH Department_Hired
AS (
SELECT Department, COUNT(*) AS hired,
(COUNT(*) / (select count(*) from hr_staging WHERE Termdate IS NULL) * 100) AS Percentage_Hired
FROM hr_staging
WHERE Termdate IS NULL
GROUP BY Department),
Department_Terminated AS
(
SELECT Department, COUNT(*) AS term,
(COUNT(*) / (select count(*) from hr_staging WHERE Termdate IS NOT NULL) * 100) AS Percentage_Terminated
FROM hr_staging
WHERE Termdate IS NOT NULL
GROUP BY Department)

SELECT dh.Department ,
dh.hired, dt.term,
ROUND(CAST(dt.term AS FLOAT) / dh.hired, 3) AS termination_ratio
FROM Department_Hired dh
JOIN Department_Terminated dt on dh.Department = dt.Department ORDER BY termination_ratio DESC;

-- The Finance department has the highest termination-to-hiring ratio at 16.2%,
-- followed by HR (13.2%) and Customer Service (12.4%).
-- Interestingly, Marketing (10.8%) and IT (11.2%) show the lowest termination ratios
-- While Operations and Sales have large headcounts,
-- their ratios remain moderate at around 12%

-- Explore relationship between age and performance rating
WITH Age_Group_cte AS (
    SELECT `Performance Rating`, CASE WHEN timestampdiff(year, Birthdate, CURRENT_DATE()) < 25 THEN  '<25'
WHEN timestampdiff(year, Birthdate, CURRENT_DATE()) BETWEEN 25 AND 34 THEN '25-34'
WHEN timestampdiff(year, Birthdate, CURRENT_DATE()) BETWEEN 35 AND 44 THEN '35-44'
WHEN timestampdiff(year, Birthdate, CURRENT_DATE()) BEtWEEN 45 AND 54 THEN '45-54'
ELSE '55+'
END AS Age_Group from hr_staging
),
Age_Group_Totals AS (
    SELECT Age_Group, COUNT(*) AS total
    FROM Age_Group_cte
    GROUP BY Age_Group
)
SELECT
    a.Age_Group,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Excellent' THEN 1 END) / t.total * 100, 1) AS Excellent_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Good' THEN 1 END) / t.total * 100, 1) AS Good_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Satisfactory' THEN 1 END) / t.total * 100, 1) AS Satisfactory_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Needs Improvement' THEN 1 END) / t.total * 100, 1) AS Needs_Improvement_pct
FROM Age_Group_cte a
JOIN Age_Group_Totals t ON a.Age_Group = t.Age_Group
GROUP BY a.Age_Group, t.total
ORDER BY a.Age_Group;

-- Employees under 25 received the lowest percentage of "Excellent" ratings (15.0%)
-- and the highest "Needs Improvement" ratings (14.0%),
-- suggesting younger staff may still be developing key skills
-- or adapting to the work environment.

-- In contrast, employees aged 55 and older had the highest "Excellent" rating (19.9%)
-- and lowest "Needs Improvement" (11.8%).

-- Across all age groups, "Good" is the most common rating..

-- Satisfactory ratings are consistent across age groups.

-- Explore relationship between department and performance rating
WITH Department_Totals AS (
    SELECT Department, COUNT(*) AS total
    FROM hr_staging
    GROUP BY Department
)

SELECT
    hr.Department,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Excellent' THEN 1 END) / dt.total * 100, 1) AS Excellent_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Good' THEN 1 END) / dt.total * 100, 1) AS Good_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Satisfactory' THEN 1 END) / dt.total * 100, 1) AS Satisfactory_pct,
    ROUND(COUNT(CASE WHEN `Performance Rating` = 'Needs Improvement' THEN 1 END) / dt.total * 100, 1) AS Needs_Improvement_pct
FROM hr_staging hr
JOIN Department_Totals dt ON hr.Department = dt.Department
GROUP BY hr.Department;

-- Sales leads with the highest percentage of "Excellent" ratings (23.7%)
-- and the lowest "Needs Improvement" (7.0%).
-- This suggests strong performance and possibly well-defined incentives or targets.
-- Finance also shows strong performance with 21.2% "Excellent" and
-- only 8.6% in "Needs Improvement."

-- Customer Service has the lowest "Excellent" percentage (13.6%)
-- and the highest "Needs Improvement" (19.7%).
-- This may point to issues like burnout, training gaps, or high customer-facing stress.
-- Marketing also has a relatively high "Needs Improvement" percentage (17.3%).

-- IT, Operations, and HR show relatively consistent distributions.

--Explore relationship between gender, education level and salary
SELECT
    Gender,
    ROUND(AVG(CASE WHEN `Education Level` = 'High School' THEN Salary END), 1) AS High_School,
    ROUND(AVG(CASE WHEN `Education Level` = 'Bachelor' THEN Salary END), 1) AS Bachelor,
    ROUND(AVG(CASE WHEN `Education Level` = 'Master' THEN Salary END), 1) AS `Master`,
    ROUND(AVG(CASE WHEN `Education Level` = 'PhD' THEN Salary END), 1) AS PhD
FROM hr_staging
GROUP BY Gender;

-- At lower education levels (High School, Bachelor),
--males earn more on average than females.

-- At higher education levels (Master, PhD),
 -- females earn more than males, with the largest gap at the PhD level (~$13K).

