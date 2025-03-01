-- DATA CLEANING

SELECT *
FROM layoffs;

-- 1. REMOVE DUPLICATES
-- 2. STANDARDIZE THE DATA
-- 3. NULL VALUES OR BLANK VALUES
-- 4. REMOVE ANY UNNEEDED COLUMNS

-- A COPY OF THE RAW DATA:
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- FIND THE DUPLICATES:
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- THESE ROWS ARE THE DUPLICATES:
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- REMOVING THE DUPLICATES

-- CREATING NEW TABLE 
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging2;

-- INSERT THE INFO FROM CTE 
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- DELETE THESE
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- STANDARDIZING DATA
-- FIND ISSUES AND FIX

-- FIX SPACING
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT *
FROM layoffs_staging2;

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1; -- THERE ARE BLANK AND NULL VALUES, AND MULTIPLE CRYPTO NAMED DIFFERENTLY

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'; -- THERE IS MORE CRYPTO

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; -- UNITED STATES HAS 2 DIFFERENT NAMES

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- DATE NEEDS TO BE A DIFFERENT DATA TYPE
SELECT `date`,
str_to_date(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- NULL AND BLANK FIXES

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;
    
SELECT DISTINCT industry
FROM layoffs_staging2; 

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
	OR industry = ''; -- one null and three blanks
    
SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
	AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL;
-- NOW I KNOW WHICH COMPANY BELONGS TO WHICH INDUSTRY

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = ''; -- TURNING BLANK TO NULL

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2 
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%'; -- ONLY ONE SO NOTHING HERE

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;

-- WITH NUMERIC NULL VALUES I CAN EITHER PERFORM:
-- 1. DELETE (DATA NOT IMPORTANT)
-- 2. UPDATE THEM WITH ANOTHER VALUE (0) (IF I NEED THE DATA) - SAFER
-- 3. FILL THEM WITH THE MEDIAN (AVG VALUE) LIKE IN R

-- I'M DELETING THEM HERE WHERE BOTH COLUMNS ARE NULL
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;


SELECT *
FROM layoffs_staging2;    

-- DELETE ROW_NUM COLUMN:
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
