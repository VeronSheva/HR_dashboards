-- Copy layoffs table into hr_staging,
-- where most of the processing will take place

CREATE TABLE hr_staging LIKE humanresources;

--Copy over the values

INSERT hr_staging
SELECT * FROM humanresources;


WITH duplicates_cte as(
SELECT *, ROW_NUMBER() OVER(PARTITION BY
                            `First Name`, `Last Name`, Gender,
                            State, City, `Education Level`, Birthdate
                           ORDER by `First Name`)
as row_num FROM hr_staging)
SELECT * FROM duplicates_cte where row_num > 1;

-- No duplicates found

SELECT * FROM hr_staging
WHERE Termdate IS NULL OR Termdate = '';
-- Looks like if the employee is still active the Termdate is equal to ''

-- Let's replace '' with null

UPDATE hr_staging
SET Termdate = NULL
WHERE Termdate = '';

-- Fix Date Formats
UPDATE hr_staging
SET Birthdate =  STR_TO_DATE(Birthdate, '%d/%m/%Y');

UPDATE hr_staging
SET Termdate =  STR_TO_DATE(Termdate, '%d/%m/%Y');

UPDATE hr_staging
SET Hiredate =  STR_TO_DATE(Hiredate, '%d/%m/%Y');