-- Data Cleaning

-- it was a guided project with Alex the Analyst, then I tried to make it by myself, so you can see my practise below
-- I attached the raw excel file as well

SELECT * 
FROM layoffs;

-- STEPS:
-- 0. Create a workspace
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Handle null or Blank values
-- 4. Remove Unnecessary Columns or Rows

-- 0. create a workspace
CREATE TABLE layoffs_practice
LIKE layoffs;

SELECT *
FROM layoffs_practice;

INSERT layoffs_practice
SELECT *
FROM layoffs;


-- 1. Find and delete duplicate values 

SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_practice; -- by putting all of the column names to the row_num function, we create row number for every distinct rows
-- so if a row did not get a 1 for its row_number, it is because the row has its clone (duplication), with the exact same values so it has a pair

WITH duplicate_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_practice)
SELECT *
FROM duplicate_cte
WHERE row_num > 1; -- if a row is duplicated, the copy of that row will get num 2 or more, so we check these rows with num 2 or more

SELECT *
FROM layoffs_practice
WHERE company = 'yahoo'; -- I have checked all the 5 duplications to be sure that they have their pairs - I'm sure now, they're duplicated

 WITH duplicate_cte AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_practice)
DELETE
FROM duplicate_cte
WHERE row_num > 1; -- yeah, it doesn't work like this..

CREATE TABLE `layoffs_practice2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_number` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci; -- we create a new table with the row_num column

SELECT * 
FROM layoffs_practice2;

INSERT INTO layoffs_practice2
SELECT *, ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_practice; -- copy everything to the new table + the new row_number column values

SELECT *
FROM layoffs_practice2
WHERE `row_number` > 1; -- check again the duplicated rows (realized that the column name was not chosen wisely, but it is okay)

DELETE
FROM layoffs_practice2
WHERE `row_number` > 1; -- now we can delete the duplicated values

SELECT * 
FROM layoffs_practice2;

-- 2. standardizing the data

SELECT company, TRIM(company)
FROM layoffs_practice2; 

UPDATE layoffs_practice2
SET company = TRIM(company); -- remove the spaces before company names

SELECT DISTINCT industry
FROM layoffs_practice2
ORDER BY 1; -- check the industry column, there is one incorrect industry name, we'll correct it
-- and there are empty or null values so we will handle them later

SELECT *
FROM layoffs_practice2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_practice2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%'; -- standardized an industry value 

SELECT DISTINCT location
FROM layoffs_practice2
ORDER BY 1; -- we can find some special characters in some of the city names so we correct them (in the guided project we did not care about them)

SELECT *
FROM layoffs_practice2
WHERE location LIKE 'Florian%';
UPDATE layoffs_practice2
SET location = 'Florianopolis'
WHERE location LIKE 'Florian%';
SELECT *
FROM layoffs_practice2
WHERE location LIKE 'Malm%';
UPDATE layoffs_practice2
SET location = 'Malmo'
WHERE location LIKE 'Malm%';
SELECT *
FROM layoffs_practice2
WHERE location LIKE '%sseldorf';
UPDATE layoffs_practice2
SET location = 'Dusseldorf'
WHERE location LIKE '%sseldorf';

SELECT DISTINCT country
FROM layoffs_practice2
ORDER BY 1; -- we can find 1 incorrect item, so we correct it

UPDATE layoffs_practice2
SET country = 'United States'
WHERE country LIKE 'United States_';

SELECT `date`
FROM layoffs_practice2; -- the date is in text format so we have to change it into date type, but first define the format

SELECT `date`, str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_practice2;
UPDATE layoffs_practice2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y'); -- done

SELECT *
FROM layoffs_practice2;

ALTER TABLE layoffs_practice2
MODIFY COLUMN `date` DATE; -- we changed the type of the column to date now, so it is no longer a text type data


-- 3. Find and handle Null or Blank Values

SELECT *
FROM layoffs_practice2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; -- if these companies haven't got any record here, they do not belong to a table about layoffs actually

DELETE 
FROM layoffs_practice2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; -- so we delete these rows

SELECT *
FROM layoffs_practice2
WHERE industry = ''
OR industry IS NULL;
UPDATE layoffs_practice2
SET industry = NULL
WHERE industry = ''; -- standardize the blank industry elements -> null values

SELECT *
FROM layoffs_practice2
WHERE company LIKE 'Bally%'; -- we do not have any other row about this company so we cannot define its industry

SELECT l1.industry, l2.industry
FROM layoffs_practice2 l1
JOIN layoffs_practice2 l2
	ON l1.company = l2.company
WHERE l1.industry IS NULL AND l2.industry != ''; -- but others have other rows so we can standardize the industry names for them

UPDATE layoffs_practice2 l1
JOIN layoffs_practice2 l2
	ON l1.company = l2.company
SET l1.industry = l2.industry
WHERE l1.industry IS NULL AND l2.industry IS NOT NULL;

SELECT *
FROM layoffs_practice2; -- we still have a null value in the industry column (Belly... company) but we leave it 
-- (perhaps we could look for its industry online or something like that in order not to leave it like this)

-- so now we are done. a couple of null values remained: 
-- 1 in the industry column, 
-- a lot in the total_laid_off, percentage_laid_off and fund_raised_millions columns 
-- but we cannot calculate the exact values because we do not have enough information for that.
-- 1 in the date column and 5 in the stage column

-- honestly, if we did not want to look for these missing values but want to use this table for further analysis, I would remove these things:
-- the row where we haven't got the industry title, 
-- the row where we haven't got the date information,
-- the entire funds_raised_millions and stage columns
-- and..

SELECT COUNT(CASE WHEN percentage_laid_off IS NULL THEN 1 END) as null_values,
COUNT(*), ROUND(100 * COUNT(CASE WHEN percentage_laid_off IS NULL THEN 1 END) / COUNT(*),2) as percentage
FROM layoffs_practice2; 
-- alright so 21.2% of the data in the percentage_laid_off column is missing, it is a lot, I would not delete these rows

SELECT COUNT(CASE WHEN total_laid_off IS NULL THEN 1 END) as null_values,
COUNT(*), ROUND(100 * COUNT(CASE WHEN total_laid_off IS NULL THEN 1 END) / COUNT(*),2) as percentage
FROM layoffs_practice2; 
-- and 18.95% of the data in the total_laid_off is also missing. So that is all for now I think.

SELECT 
COUNT(CASE WHEN total_laid_off IS NULL AND percentage_laid_off IS NOT NULL THEN 1 END) as only_total,
COUNT(CASE WHEN total_laid_off IS NULL AND percentage_laid_off IS NULL THEN 1 END) as both_null,
COUNT(CASE WHEN percentage_laid_off IS NULL AND total_laid_off IS NOT NULL THEN 1 END) as only_perc
FROM layoffs_practice2
; -- we can see that there is not any row where both values are missing - it's not so good because it means we have more useless rows 

SELECT 
ROUND(100.0 *
(COUNT(CASE WHEN total_laid_off IS NULL AND percentage_laid_off IS NOT NULL THEN 1 END) +
COUNT(CASE WHEN total_laid_off IS NULL AND percentage_laid_off IS NULL THEN 1 END) +
COUNT(CASE WHEN percentage_laid_off IS NULL AND total_laid_off IS NOT NULL THEN 1 END))
/ COUNT(*),2) AS percentage_of_nulls
FROM layoffs_practice2
; -- it means that 40.15% of our data is missing from these important columns 
-- so I think we have 2 options:
-- to choose only one of these two columns, which one we would like to use in our further analysis
-- or to gather more information and fill the empty cells


-- 4. Remove Unnecessary Columns or Rows

ALTER TABLE layoffs_practice2
DROP COLUMN `row_number`;  

SELECT *
FROM layoffs_practice2;

-- the end -- 
