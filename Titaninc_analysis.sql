-- =============================================================================
-- Titanic Survival Analysis
-- Dataset : Titanic Passenger Dataset (Titanic-Dataset.csv)
-- Source  : https://www.kaggle.com/datasets/yasserh/titanic-dataset
-- Author  : Plinio Durango
-- Date    : 2025
-- =============================================================================
-- TABLE OF CONTENTS
--   PART 1 - Background & Dataset Overview
--   PART 2 - Exploratory Data Analysis (7-Step Framework)
--             Step 1 : Inspect the table
--             Step 2 : What does one row represent?
--             Step 3 : Table dimensions
--             Step 4 : Column value ranges (SibSp, Embarked, Parch, Pclass)
--             Step 5 : Duplicate check
--             Step 6 : Missing value check
--   PART 3 - Data Cleaning View
--   PART 4 - Survival Analysis
--             Query 1 : Overall survival rate
--             Query 2 : Survival by gender
--             Query 3 : Survival by passenger class
--             Query 4 : Survival by gender + class (solo vs. with company)
--             Query 5 : Survival by cabin deck
--             Query 6 : Family size vs. survival
--             Query 7 : Title extraction & survival by title
--   PART 5 - Historical Context
-- =============================================================================


-- =============================================================================
-- PART 1 - BACKGROUND & DATASET OVERVIEW
-- =============================================================================

/*
CONTEXT
-------
The RMS Titanic sank on April 15, 1912, after striking an iceberg
in the North Atlantic Ocean. Of the estimated 2,224 passengers and crew
aboard, more than 1,500 died, making it one of the deadliest maritime
disasters in history.

This case study uses passenger-level data to investigate the factors
that influenced survival. The analysis explores the roles of passenger
class, gender, family structure, cabin location, and social title.

DATASET
-------
Source  : Kaggle - Titanic Dataset
URL     : https://www.kaggle.com/datasets/yasserh/titanic-dataset
Rows    : 714 passengers
Columns : 12

KEY COLUMNS
-----------
  PassengerId - Unique passenger identifier
  Survived    - Survival indicator (0 = No, 1 = Yes)
  Pclass      - Passenger class (1 = First, 2 = Second, 3 = Third)
  Name        - Full passenger name (Last, Title. First)
  Sex         - Gender (male / female)
  Age         - Age in years
  SibSp       - Number of siblings or spouses aboard
  Parch       - Number of parents or children aboard
  Ticket      - Ticket number
  Fare        - Passenger fare
  Cabin       - Cabin number (>70% missing)
  Embarked    - Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton)

RESEARCH QUESTIONS
------------------
  1. What was the overall survival rate?
  2. Did gender affect survival?
  3. Did passenger class affect survival?
  4. Did traveling alone vs. with family affect survival?
  5. Did cabin location influence survival?
  6. Did family size affect survival?
  7. Did social title (Mr., Mrs., Miss., Master.) predict survival?
*/

USE case_study_hmw;

-- =============================================================================
-- PART 2 - EXPLORATORY DATA ANALYSIS (7-STEP FRAMEWORK)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- STEP 1: Inspect the table
-- -----------------------------------------------------------------------------

SELECT *
FROM titanic
LIMIT 100;

/*
OBSERVATIONS:
- Each row corresponds to a single passenger with 12 attributes.
- Most columns are self-explanatory (Name, Sex, Age, Fare, Survived).
- SibSp, Parch, and Embarked require additional context from the
  dataset documentation -- explored in Step 4.
- The Cabin column appears to have many NULL values.
- The Name column follows the pattern: Last, Title. First Middle
  which allows us to extract titles (Mr., Mrs., Miss., etc.) using
  string functions -- explored in Part 4, Query 7.
*/


-- -----------------------------------------------------------------------------
-- STEP 2: What does one row represent?
-- -----------------------------------------------------------------------------

/*
Each row represents a single passenger aboard the Titanic.
The composite identifier (Name, Ticket) can serve as a natural key,
although PassengerId is provided as the explicit unique identifier.

Note: The original full Titanic dataset has 891 rows. This dataset
contains 714 rows, likely filtered to passengers with known Age values.
*/


-- -----------------------------------------------------------------------------
-- STEP 3: Table dimensions
-- -----------------------------------------------------------------------------

SELECT COUNT(*) AS total_rows
FROM titanic;
-- Result: 714 rows

DESCRIBE titanic;
-- Result: 12 columns
-- Dimension: 714 x 12


-- -----------------------------------------------------------------------------
-- STEP 4: What values can each column take?
-- -----------------------------------------------------------------------------

-- SibSp: Number of siblings or spouses aboard
SELECT
    SibSp,
    COUNT(*)                                              AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM titanic) * 100, 1) AS pct
FROM titanic
GROUP BY SibSp
ORDER BY SibSp;
/*
Values range from 0 to 5.
Approximately 66% of passengers were traveling without siblings or spouses.
*/

-- Embarked: Port of embarkation
SELECT
    Embarked,
    COUNT(*)                                              AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM titanic) * 100, 1) AS pct
FROM titanic
GROUP BY Embarked
ORDER BY Embarked;
/*
Possible values: C (Cherbourg), Q (Queenstown), S (Southampton).
Approximately 77.6% of passengers boarded at Southampton.
*/

-- Parch: Number of parents or children aboard
SELECT
    Parch,
    COUNT(*)                                              AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM titanic) * 100, 1) AS pct
FROM titanic
GROUP BY Parch
ORDER BY Parch;
/*
Approximately 73% of passengers had no parents or children on board.
*/

-- Pclass: Passenger class
SELECT
    Pclass,
    COUNT(*)                                              AS count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM titanic) * 100, 1) AS pct
FROM titanic
GROUP BY Pclass
ORDER BY Pclass;
/*
Interestingly, first class had more passengers than second class
in this dataset. This will be revisited in the survival analysis.
*/


-- -----------------------------------------------------------------------------
-- STEP 5: Duplicate check
-- -----------------------------------------------------------------------------

SELECT COUNT(*)          AS total_rows    FROM titanic;
SELECT COUNT(DISTINCT PassengerId) AS distinct_ids FROM titanic;
-- Both return 714: no duplicate passenger records.


-- -----------------------------------------------------------------------------
-- STEP 6: Missing value check
-- -----------------------------------------------------------------------------

SELECT
    SUM(CASE WHEN Pclass   IS NULL THEN 1 ELSE 0 END) AS missing_pclass,
    SUM(CASE WHEN SibSp    IS NULL THEN 1 ELSE 0 END) AS missing_sibsp,
    SUM(CASE WHEN Parch    IS NULL THEN 1 ELSE 0 END) AS missing_parch,
    SUM(CASE WHEN Embarked IS NULL THEN 1 ELSE 0 END) AS missing_embarked,
    SUM(CASE WHEN Age      IS NULL THEN 1 ELSE 0 END) AS missing_age,
    SUM(CASE WHEN Cabin    IS NULL THEN 1 ELSE 0 END) AS missing_cabin,
    COUNT(*)                                          AS total_rows
FROM titanic;
/*
RESULTS:
- Pclass, SibSp, Parch, Embarked: 0 missing values
- Age: some missing values (passengers with unknown age)
- Cabin: >70% missing -- results from cabin-based analysis
  must be interpreted with caution
*/

-- =============================================================================
-- PART 3 - DATA CLEANING VIEW
-- =============================================================================

/*
We create a clean view that:
- Excludes rows with NULL Age (to ensure age-based analysis is valid)
- Derives a traveling_alone flag based on SibSp and Parch
- Extracts the social title from the Name column using SUBSTRING
All survival analysis queries in Part 4 reference titanic_clean.
*/

CREATE OR REPLACE VIEW titanic_clean AS
SELECT
    PassengerId,
    Survived,
    Pclass,
    Name,
    Sex,
    Age,
    SibSp,
    Parch,
    Ticket,
    Fare,
    Cabin,
    Embarked,
    -- Flag: 1 if traveling alone, 0 if with family
    CASE WHEN SibSp = 0 AND Parch = 0 THEN 1 ELSE 0 END AS traveling_alone,
    -- Extract social title from Name (format: Last, Title. First)
    TRIM(SUBSTRING(
        Name,
        LOCATE(',', Name) + 2,
        LOCATE('.', Name) - LOCATE(',', Name) - 1
    )) AS title
FROM titanic
WHERE Age IS NOT NULL;

-- Verify the view
SELECT PassengerId, Name, title, traveling_alone
FROM titanic_clean
LIMIT 10;


-- =============================================================================
-- PART 4 - SURVIVAL ANALYSIS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- QUERY 1: Overall survival rate
-- -----------------------------------------------------------------------------

SELECT
    COUNT(*)                                   AS total_passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic;

/*
RESULT:
  Total passengers : 714
  Survivors        : 290
  Survival rate    : ~40.6%

Nearly 60% of passengers in this dataset did not survive.
The well-known "women and children first" evacuation policy is expected
to be visible in the gender and title breakdowns below.
*/


-- -----------------------------------------------------------------------------
-- QUERY 2: Survival by gender
-- -----------------------------------------------------------------------------

SELECT
    Sex,
    COUNT(*)                                   AS total_passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic
GROUP BY Sex;

/*
RESULT:
  Female : ~75% survival rate
  Male   : ~21% survival rate

Gender was a primary factor in survival. The evacuation policy of
"women and children first" is clearly reflected in this data.
*/


-- -----------------------------------------------------------------------------
-- QUERY 3: Survival by passenger class
-- -----------------------------------------------------------------------------

SELECT
    Pclass,
    COUNT(*)                                   AS total_passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic
GROUP BY Pclass
ORDER BY Pclass;

/*
RESULT:
  1st class : ~66% survival rate
  2nd class : ~47% survival rate
  3rd class : ~24% survival rate

Passenger class was a major factor influencing survival.
First-class passengers had nearly three times the survival rate
of third-class passengers, likely due to cabin proximity to
lifeboat decks and preferential boarding access.
*/


-- -----------------------------------------------------------------------------
-- QUERY 4: Survival by gender, class, and traveling status (solo vs. company)
-- -----------------------------------------------------------------------------

/*
Gender has such a strong effect that comparing solo vs. group survival
without separating by gender produces misleading results. For example,
the high female survival rate would inflate the overall average for
group travelers if gender is not controlled for.

The query below produces a side-by-side comparison per class:
  solo_f_rate    : solo female survival rate
  solo_m_rate    : solo male survival rate
  company_f_rate : female survival rate when traveling with family
  company_m_rate : male survival rate when traveling with family
*/

SELECT
    sf.Pclass,
    ROUND(sf.survival_rate, 1)  AS solo_f_rate,
    ROUND(sm.survival_rate, 1)  AS solo_m_rate,
    ROUND(cf.survival_rate, 1)  AS company_f_rate,
    ROUND(cm.survival_rate, 1)  AS company_m_rate
FROM
    -- Solo females
    (SELECT Pclass,
            SUM(Survived) / COUNT(*) * 100 AS survival_rate
     FROM titanic
     WHERE SibSp = 0 AND Parch = 0 AND Sex = 'female'
     GROUP BY Pclass) sf
JOIN
    -- Solo males
    (SELECT Pclass,
            SUM(Survived) / COUNT(*) * 100 AS survival_rate
     FROM titanic
     WHERE SibSp = 0 AND Parch = 0 AND Sex = 'male'
     GROUP BY Pclass) sm  ON sf.Pclass = sm.Pclass
JOIN
    -- Females with company
    (SELECT Pclass,
            SUM(Survived) / COUNT(*) * 100 AS survival_rate
     FROM titanic
     WHERE (SibSp > 0 OR Parch > 0) AND Sex = 'female'
     GROUP BY Pclass) cf  ON sf.Pclass = cf.Pclass
JOIN
    -- Males with company
    (SELECT Pclass,
            SUM(Survived) / COUNT(*) * 100 AS survival_rate
     FROM titanic
     WHERE (SibSp > 0 OR Parch > 0) AND Sex = 'male'
     GROUP BY Pclass) cm  ON sf.Pclass = cm.Pclass
ORDER BY sf.Pclass;

/*
KEY FINDINGS:
- Solo female passengers in 1st and 2nd class had survival rates above 90%.
- Solo female passengers in 3rd class dropped to ~55%.
- Solo male passengers in 1st class: ~37% survival.
- Solo male passengers in 2nd and 3rd class: ~8-14% survival.
- Traveling alone vs. with company had a modest overall effect,
  with one notable exception: 2nd class males traveling with company
  had a survival rate more than four times higher than solo 2nd class males.
*/

-- -----------------------------------------------------------------------------
-- QUERY 5: Survival by cabin deck
-- -----------------------------------------------------------------------------

/*
The Cabin column encodes both deck letter and room number (e.g., C85, D33).
We extract the first character to get the deck letter and analyze
survival rates per deck.

IMPORTANT CAVEAT:
More than 70% of the Cabin data is missing (NULL). The results below
apply only to the ~30% of passengers with known cabin assignments,
who were disproportionately first-class passengers. All conclusions
should be interpreted with this limitation in mind.
*/

SELECT
    LEFT(Cabin, 1)                             AS cabin_deck,
    COUNT(*)                                   AS passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic
WHERE Cabin IS NOT NULL
GROUP BY cabin_deck
ORDER BY survival_rate_pct DESC;

/*
RESULT:
Decks C, D, and E show the highest survival rates (all above 70%).
These decks were likely located closer to the lifeboat stations,
giving passengers easier and faster access during the evacuation.

Reference: https://www.encyclopedia-titanica.org/cabins.html
*/


-- -----------------------------------------------------------------------------
-- QUERY 6: Family size vs. survival
-- -----------------------------------------------------------------------------

/*
We define family_id as CONCAT(last_name, ticket_number) to group
passengers who share both a surname and a ticket -- a reliable proxy
for traveling as part of the same family unit.

This approach handles cases where unrelated passengers share a surname
or where families have different last names.
*/

-- Step 1: Create working table with family_id
CREATE TABLE IF NOT EXISTS titanic_with_family_id AS
SELECT
    *,
    CONCAT(
        SUBSTRING(Name, 1, LOCATE(',', Name) - 1),
        Ticket
    ) AS family_id
FROM titanic;

-- Step 2: Compute family size per family_id
CREATE TABLE IF NOT EXISTS titanic_family_size AS
SELECT
    family_id,
    COUNT(*) AS family_size
FROM titanic_with_family_id
GROUP BY family_id;

-- Step 3: Join family size back to the passenger table
CREATE TABLE IF NOT EXISTS titanic_with_family_size AS
SELECT t1.*, t2.family_size
FROM titanic_with_family_id t1
JOIN titanic_family_size t2 USING (family_id);

-- Step 4: Analyze survival by family size
SELECT
    family_size,
    COUNT(*)                                   AS passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic_with_family_size
GROUP BY family_size
ORDER BY family_size;

/*
RESULT:
- Solo travelers (family_size = 1) : ~36% survival rate
- Small families (2-4 members)     : >50% survival rate
- Large families (5+ members)      : ~0% survival rate

Small families had the highest survival rates, possibly because
small groups could move and board lifeboats more efficiently.
Very large families may have struggled to stay together during
the chaotic evacuation, resulting in worse outcomes for all members.

Reference: https://www.kaggle.com/code/lperez/titanic-a-deeper-look-on-family-size
*/

-- Solo female passengers
SELECT
    COUNT(*)                                   AS solo_female_passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic_with_family_size
WHERE family_size = 1 AND Sex = 'female';
-- Result: ~80% survival rate for solo female passengers

-- Solo male passengers
SELECT
    COUNT(*)                                   AS solo_male_passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic_with_family_size
WHERE family_size = 1 AND Sex = 'male';
-- Result: ~18% survival rate for solo male passengers
-- The contrast with solo females (80% vs 18%) further confirms
-- that gender was a dominant factor in survival outcomes.


-- -----------------------------------------------------------------------------
-- QUERY 7: Title extraction and survival by title
-- -----------------------------------------------------------------------------

/*
The Name column follows the format: Last, Title. First Middle
We extract the title using LOCATE() and SUBSTRING() to identify
the string between the comma and the first period.

This gives us a social/honorific title for each passenger
(Mr., Mrs., Miss., Master., Dr., Rev., etc.)
*/

-- Create table with extracted title
CREATE TABLE IF NOT EXISTS titanic_with_title AS
SELECT
    *,
    TRIM(SUBSTRING(
        Name,
        LOCATE(',', Name) + 2,
        LOCATE('.', Name) - LOCATE(',', Name) - 1
    )) AS title
FROM titanic;

-- Count passengers per title
SELECT
    title,
    COUNT(*) AS passengers
FROM titanic_with_title
GROUP BY title
ORDER BY passengers DESC;

-- Survival rate by title
SELECT
    title,
    COUNT(*)                                   AS passengers,
    SUM(Survived)                              AS survivors,
    ROUND(SUM(Survived) / COUNT(*) * 100, 1)   AS survival_rate_pct
FROM titanic_with_title
GROUP BY title
ORDER BY survival_rate_pct DESC;

/*
KEY FINDINGS:
- Mrs.    : >80% survival rate
- Miss.   : >70% survival rate
- Master. : ~58% survival rate (young boys -- benefited from
            the "children first" policy)
- Mr.     : ~17% survival rate
- Dr.     :  mixed results due to small sample size
- Rev.    :  0% survival rate in this dataset

The title-based analysis strongly confirms the "women and children first"
evacuation policy. Female titles (Mrs., Miss.) and the male child title
(Master.) all show significantly higher survival rates than adult male
titles (Mr., Rev., Dr.).
*/


-- =============================================================================
-- PART 5 - HISTORICAL CONTEXT
-- =============================================================================

/*
SURVIVAL RATE IN CONTEXT
------------------------
The Titanic dataset shows an overall survival rate of approximately 40.6%,
meaning that roughly 59% of passengers in this dataset did not survive.
To understand the severity of this event, it is useful to compare the
mortality rate against other major disasters from the same era.

SPANISH FLU (1918-1920)
  Infected  : ~500 million people worldwide
  Deaths    : ~50 million
  Mortality : ~10%
  Source    : CDC

WORLD WAR I (1914-1918)
  Mobilized : ~65 million soldiers
  Deaths    : ~9.7 million
  Mortality : ~15%
  Source    : Encyclopaedia Britannica

COMPARISON
  The Titanic disaster had a much higher mortality rate (~59%) within
  its population than both the Spanish Flu (~10%) and WWI (~15%).
  While those events caused far greater absolute numbers of deaths,
  a passenger aboard the Titanic faced a significantly higher
  probability of dying than a soldier in WWI or someone infected
  during the Spanish Flu pandemic.

  This comparison highlights not only the scale of the disaster
  relative to the ship's capacity, but also the influence of
  structural factors (class, gender, cabin location) in determining
  who would survive.
*/


-- =============================================================================
-- END OF CASE STUDY
-- =============================================================================