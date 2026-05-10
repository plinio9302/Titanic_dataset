USE case_study_hmw;

SELECT *
FROM titanic
WHERE Name LIKE '%John Bradley%' OR 
      Name LIKE '%Jacques Heath%'; -- ah, the ticket numbers are maybe unique?? 
      
-- 2. Perform EDA on at least 3 columns 
/* Fill in your code here */
/*
2.1. What does one row represent?
*/
SELECT *
FROM titanic
LIMIT 100;
/*
From the query excuted above, we can see 
that each row correspond to a single person/passanger, with 12 parameters, 
such as name, sex, age etc.
*/

/*
2.2. What are the table dimensions?
*/
SELECT COUNT(*)
FROM titanic; -- 714

DESCRIBE titanic;-- 12 COLUMNS
/*
From the queries above, the response was 714 rows/people, and  
12 columns, respectivly the resulting dimension is 714 * 12
*/

/*
2.3. Perform EDA on at least 3 columns?
What values can each column take?
*/

/*
From the query executed in section 2.1, we can see that most of the
columns are relatively self-explanatory. Therefore, I will start by
conducting an exploratory analysis on columns whose meaning may not
be immediately obvious, such as SibSp, Embarked, and Parch.
*/

/* --- SibSp --- */
SELECT SibSp, COUNT(*) AS count,
(COUNT(*)/(SELECT COUNT(*) FROM titanic)) * 100 AS proportion
FROM titanic
GROUP BY SibSp
ORDER BY SibSp;
/*
According to the dataset documentation, SibSp represents the number of
siblings or spouses a passenger had aboard the Titanic. The values in
this dataset range from 0 to 5. From the results, we observe that roughly
66% of passengers were traveling without siblings or spouses.
*/


/* --- Embarked --- */
SELECT Embarked,
       COUNT(*) AS count,
       (COUNT(*) / (SELECT COUNT(*) FROM titanic))*100 AS proportion
FROM titanic
GROUP BY Embarked
ORDER BY Embarked;
/*
Embarked represents the port where the passenger boarded the Titanic.
Possible values are:

C = Cherbourg
Q = Queenstown
S = Southampton

From the query results we see that approximately 77.6% of passengers
boarded in Southampton, making it the most common port of embarkation.
*/

/* --- Parch --- */
SELECT Parch, 
	   COUNT(*) AS count,
       (COUNT(*) / (SELECT COUNT(*) FROM titanic))*100 AS proportion
FROM titanic
GROUP BY Parch
ORDER BY Parch;
/*
Parch represents the number of parents or children traveling with
the passenger aboard the Titanic. The results show that around 73%
of passengers had no parents or children on board.
*/

-- I am also curious about the passenger class (Pclass).
-- Later in the analysis I want to investigate whether
-- passenger class is related to survival probability.

/* --- Pclass --- */
SELECT Pclass, 
	   COUNT(*) AS count,
       (COUNT(*) / (SELECT COUNT(*) FROM titanic))*100 AS proportion
FROM titanic
GROUP BY Pclass
ORDER BY Pclass;
/*
Interestingly, there were more passengers in first class than in
second class. I will return to this variable later in the analysis,
with the goal of computing the survival rate for each class
(e.g., how many passengers out of the 186 in first class survived,
and similarly for the other classes).
*/

-- 2.4 Check for duplicates
SELECT COUNT(PassengerId)
FROM titanic; -- Answer : 714

SELECT COUNT(DISTINCT PassengerId)
FROM titanic; -- Answer: 714

-- Great! no duplicates

-- 2.5 Check for Missing Values: NULLs

SELECT Pclass, SibSp, Parch, Embarked
FROM titanic
WHERE Pclass IS NULL; -- zero rows returned

SELECT Pclass, SibSp, Parch, Embarked
FROM titanic
WHERE SibSp IS NULL; -- zero rows returned

SELECT Pclass, SibSp, Parch, Embarked
FROM titanic
WHERE Parch IS NULL; -- zero rows returned

SELECT Pclass, SibSp, Parch, Embarked
FROM titanic
WHERE Embarked IS NULL; -- zero rows returned
 
 -- A better practice for checking missing values is as follow:
 SELECT 
SUM(Pclass IS NULL) AS Pclass_missing,
SUM(SibSp IS NULL) AS SibSp_missing,
SUM(Parch IS NULL) AS Parch_missing,
SUM(Embarked IS NULL) AS EMbarked_missing
FROM titanic;



-- 3. Look into at least 3 factors that might influence survival. 
-- For example, how many men vs. women survived? ---

SELECT DISTINCT(survived)
FROM titanic;

SELECT SUM(Survived) AS survived, 
	   COUNT(*) AS total_passengers,
       Sex
FROM titanic
GROUP BY Sex;  -- looks like 21% of the men and 75% of the women


/* Remember I wanted to investigate whether
passenger class is related to survival probability. Now is the time!!
*/
-- 3.1 Was passenger class a factor that influenced survival?
SELECT Pclass,
		COUNT(*) AS total,
        SUM(Survived) AS survivors,
        (SUM(Survived)/COUNT(*))*100 AS survival_rate
FROM titanic
GROUP BY Pclass
ORDER BY Pclass;

/*
Wow! Around 66% of first-class passengers survived, while only about
24% of third-class passengers did. This suggests that passenger class
was a major factor influencing survival.
*/


-- 3.2 Was traveling alone within passenger classes
-- a factor that influenced survival?

/*
To answer this question, I will assume the following:
If SibSp = 0 and Parch = 0, then the passenger was traveling alone.
*/

-- Let's start by checking how likely a female passenger
-- traveling alone was to survive.

SELECT 
    Pclass,
    COUNT(*) AS solo_passanger,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate,
    SUM(Survived) AS survivors
FROM titanic
WHERE SibSp = 0
AND Parch = 0
AND Sex = 'female'
GROUP BY Pclass
ORDER BY Pclass;

/*
This result is remarkable. Solo female passengers in first and
second class had survival rates above 90%, while in third class
the rate drops to around 55%.
*/


-- Let's now check how likely a male passenger
-- traveling alone was to survive.

SELECT 
    Pclass,
    COUNT(*) AS solo_passanger,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate,
    SUM(Survived) AS survivors
FROM titanic
WHERE SibSp = 0
AND Parch = 0
AND Sex = 'male'
GROUP BY Pclass
ORDER BY Pclass;
/*
Among solo male passengers in first class, about 37% survived. However, the
survival rate drops sharply for second-class and third-class passengers, where only about
8%  and 14% survived respectively.
*/

/*
The previous queries show that survival patterns differ greatly
between male and female passengers. For example, solo female
passengers in first and second class had survival rates above 90%,
while solo male passengers had much lower survival probabilities
across all classes.

Therefore, in order to properly evaluate whether traveling alone
affected survival within each passenger class, the analysis must
be separated by gender. Otherwise, the very high survival rates
among female passengers would inflate the overall average and
lead to misleading conclusions.
*/

SELECT
	sf.Pclass,
    sf.survival_rate AS solo_f_rate,
    sm.survival_rate AS solo_m_rate,
    fc.survival_rate AS f_company_rate,
    mc.survival_rate AS m_company_rate

FROM
(
SELECT 
    Pclass,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic
WHERE SibSp = 0
AND Parch = 0
AND Sex = 'female'
GROUP BY Pclass
ORDER BY Pclass
) sf
JOIN
(
SELECT 
    Pclass,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic
WHERE SibSp = 0
AND Parch = 0
AND Sex = 'male'
GROUP BY Pclass
ORDER BY Pclass
) sm
ON sf.Pclass = sm.Pclass
JOIN
(
SELECT 
    Pclass,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic
WHERE (SibSp > 0 OR  Parch > 0) 
AND Sex = 'female'
GROUP BY Pclass
ORDER BY Pclass
) fc
ON sf.Pclass = fc.Pclass
JOIN
(
SELECT 
    Pclass,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic
WHERE (SibSp > 0 OR  Parch > 0) 
AND Sex = 'male'
GROUP BY Pclass
ORDER BY Pclass
) mc
ON sf.Pclass = mc.Pclass

ORDER BY sf.Pclass;

/*
The results suggest that traveling alone was not a major factor
influencing survival, whether the passenger was female or male.
For both genders, survival rates remain relatively similar when
comparing solo passengers with those traveling with company.

However, an interesting exception appears for males in second
class, where the survival probability increases by more than
four times when moving from traveling alone to traveling with
company.
*/


-- 3.3 Did Cabin play and influential role in surviving?

SELECT 
LEFT(Cabin,1) AS Cabin_letter,
COUNT(*) AS passengers,
SUM(Survived) AS survivors,
(SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic
WHERE Cabin IS NOT NULL
GROUP BY LEFT(Cabin,1)
ORDER BY Cabin_letter;

/*
This is not ideal. More than 70% of the information related to the
passengers' cabins is missing, so all results should be interpreted
with caution. 

However, if we proceed with the available data, cabins C, D, and E
show the highest survival rates, all above 70%. This suggests that
cabin location may have played an important role in survival. 
Passengers located on certain decks likely had easier access to
lifeboats, increasing their chances of survival.
*/

-- 4. Did being part of a family group (either siblings or spouse) affect survival? 
-- https://www.encyclopedia-titanica.org/cabins.html
-- https://www.kaggle.com/code/lperez/titanic-a-deeper-look-on-family-size
-- Let's assign a family_id based on last name and ticket_number

-- In-class exploration 
SELECT *
FROM titanic
WHERE SibSp = 1 OR Parch = 1
ORDER BY Ticket;

-- Create a new table with last name and ticket number, which will form a family id
-- start with last name
SELECT Name,
  LOCATE(',', Name) AS ending_index,
  SUBSTRING(Name,
    1, -- starting
    LOCATE(',', Name) -- length
    ) AS last_name
FROM titanic;

-- concatenate with ticket id
CREATE TABLE titanic_with_family_id AS
SELECT *,
  CONCAT(
  SUBSTRING(Name,
    1, -- starting
    LOCATE(',', Name)), -- length
    Ticket) AS family_id
FROM titanic;

-- test the table
SELECT *
FROM titanic_with_family_id;

-- Create a new table
CREATE TABLE titanic_family_size AS 
SELECT COUNT(*) AS family_size,
  family_id
FROM titanic_with_family_id
GROUP BY family_id;

-- test the family table
SELECT *
FROM titanic_family_size;

-- JOIN back with titanic_with_family_id to get family_size
SELECT *
FROM titanic_family_size t1
JOIN titanic_with_family_id t2
ON t1.family_id = t2.family_id;

/* TODO: create a table, titanic_with_family_size */
CREATE TABLE titanic_with_family_size AS
SELECT *
FROM titanic_family_size t1
JOIN titanic_with_family_id t2
USING (family_id);

SELECT *
FROM titanic_with_family_size
ORDER BY family_id;

/* Investigate what effect family size had on survival */

SELECT 
    family_size,
    COUNT(*) AS passengers,
    SUM(Survived) AS survivors,
    (SUM(Survived)/COUNT(*)) * 100 AS survival_rate
FROM titanic_with_family_size
GROUP BY family_size
ORDER BY family_size;

/*
These results suggest that family size had some influence on survival.
Passengers traveling with small families (2–4 members) had noticeably
higher survival rates, all above 50%. In contrast, passengers traveling
alone had a lower survival rate of about 36%.

Interestingly, very large families (5 or more members) had extremely
poor outcomes, with survival rates dropping to 0%. This may indicate
that larger groups faced greater difficulties during the evacuation,
possibly because coordinating and staying together made escaping more
challenging.
*/


/* Write at least 2 queries. Consider separating single males traveling alone from single females */ 

SELECT
	COUNT(*) AS solo_female,
    SUM(Survived) AS survivors,
	(SUM(Survived) / COUNT(*)) * 100 AS survival_rate
FROM titanic_with_family_size
WHERE family_size = 1 AND Sex = 'female';
-- Females passangers traveling by themself hs 80% 
-- chances of surviving the accident.

SELECT
	COUNT(*) AS solo_male,
    SUM(Survived) AS survivors,
	(SUM(Survived) / COUNT(*)) * 100 AS survival_rate
FROM titanic_with_family_size
WHERE family_size = 1 AND Sex = 'male';
-- Waoo!! A solo Male traveling by themself had only 18.36% survival rate


-- 5. Let's do some REGEX

-- Trying to extract the title
-- it looks like the title comes after the first ','
-- and ends at the first '.'

SELECT Name,
  LOCATE(',', Name) AS starting_index,
  LOCATE('.', Name) AS ending_index,
  SUBSTRING(Name,
    LOCATE(',', Name), -- starting
    LOCATE('.', Name) - LOCATE(',', Name) -- length
    ) AS title
FROM titanic;

-- Clean the title a bit
SELECT Name,
  LOCATE(',', Name) AS starting_index,
  LOCATE('.', Name) AS ending_index,
  SUBSTRING(Name,
    LOCATE(',', Name) +2, -- starting
    LOCATE('.', Name) - LOCATE(',', Name)
    ) AS title
FROM titanic;

-- /* TODO: create a new table, titanic_with_table */
/* FILL IN YOUR CODE HERE */

CREATE TABLE titanic_with_title AS
SELECT *,
	SUBSTRING(NAME,
    LOCATE(',', NAME)+2,
    LOCATE('.', NAME) - LOCATE(',', NAME)) AS title
FROM titanic;

SELECT *
FROM titanic_with_title;


-- How many people have each title?
/* FILL IN YOUR CODE HERE */

SELECT  title,
COUNT(*) AS passengers
FROM titanic_with_title
GROUP BY title;

/* TODO: What impact, if any, did title have on survival
Fill in your code here
Write 1-2 queries and include any analysis in comments */

SELECT  title,
COUNT(*) AS passengers,
SUM(Survived) AS survivors,
(SUM(Survived) / COUNT(*)) * 100 AS survival_rate
FROM titanic_with_title
GROUP BY title
ORDER BY survival_rate DESC;

/*
This query shows that the passenger's title had a strong relationship
with survival. Titles such as "Mrs.", "Miss.", and "Master." have much
higher survival rates compared to "Mr.".

For example, "Mrs." and "Miss." have survival rates above 70%, while
"Master." (which usually refers to young boys) also shows a relatively
high survival rate of about 58%. In contrast, passengers with the title
"Mr." have a much lower survival rate of around 17%. This pattern reflects
the well-known "women and children first" policy during the evacuation.
*/

-- 6. What was the overal survival rate of passengers on the titanic? 

/* TODO: Your code here */
/* Include any comments on what you've found */
-- 6. What was the overall survival rate of passengers on the Titanic?

SELECT 
    COUNT(*) AS passengers,
    SUM(Survived) AS survivors,
    (SUM(Survived) / COUNT(*)) * 100 AS survival_rate
FROM titanic;

/*
The overall survival rate of passengers on the Titanic was approximately 40.6%.
Out of 714 passengers in the dataset, 290 survived while the remaining
passengers did not. This indicates that nearly two-thirds of the passengers
lost their lives in the disaster.
*/

-- 7. How did this compare with other major causes of death around that time? (+/- 10 years? ) 

/*
The Titanic disaster had a survival rate of about 38%, meaning that
approximately 62% of the passengers in the dataset died. To better
understand how severe this event was, it is useful to compare it with
other major causes of death from the same historical period.

For example, the Spanish Flu pandemic (1918–1920) infected roughly
500 million people worldwide and caused about 50 million deaths,
resulting in an estimated mortality rate of around 10%.
(Source: CDC)

Similarly, during World War I (1914–1918), approximately 65 million
soldiers were mobilized and about 9.7 million died, corresponding
to a mortality rate of roughly 15%.
(Source: Encyclopaedia Britannica)

Compared with these events, the Titanic disaster had a much higher
mortality rate within its population. While pandemics and wars caused
far greater total numbers of deaths, the proportion of people who died
on the Titanic was significantly larger.
*/


-- 8. Optional extra credit

/* TODO: Find another dataset you can join against titanic. 
This could be census records that you could join on name, 
Or a similar disaster you could compare against gender-based survival rates, for example

More extra credit for more complicated queries or more rich datasets

Include any sources
If joining new tables, include table name and additional .pdf screenshot of that table(s) loaded into your workbench
*/

