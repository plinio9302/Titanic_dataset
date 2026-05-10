# Titanic Survival Analysis

**Author:** Plinio Durango | **Tool:** MySQL | **Dataset:** Titanic Passenger Data

---

## Overview

The RMS Titanic sank on April 15, 1912, after striking an iceberg in the North Atlantic Ocean. Of the estimated 2,224 passengers and crew aboard, more than 1,500 died, making it one of the deadliest maritime disasters in history.

This case study uses passenger-level data to investigate the factors that influenced survival. The analysis explores the roles of passenger class, gender, family structure, cabin location, and social title through a structured 7-step EDA followed by targeted survival queries.

---

## Dataset

**Source:** [Kaggle - Titanic Dataset](https://www.kaggle.com/datasets/yasserh/titanic-dataset)

| Property | Value |
|---|---|
| Rows | 714 passengers |
| Columns | 12 |
| Unique identifier | PassengerId |

### Key Columns

| Column | Description |
|---|---|
| Survived | Survival indicator (0 = No, 1 = Yes) |
| Pclass | Passenger class (1 = First, 2 = Second, 3 = Third) |
| Sex | Gender (male / female) |
| Age | Age in years |
| SibSp | Number of siblings or spouses aboard |
| Parch | Number of parents or children aboard |
| Cabin | Cabin number (>70% missing) |
| Embarked | Port of embarkation (C = Cherbourg, Q = Queenstown, S = Southampton) |

---

## Project Structure

```
Titanic_dataset/
├── Titanic_analysis.sql    # Full case study: EDA, cleaning view & survival analysis
├── Titanic-Dataset.csv     # Raw passenger dataset
└── README.md
```

---

## Research Questions

1. What was the overall survival rate?
2. Did gender affect survival?
3. Did passenger class affect survival?
4. Did traveling alone vs. with family affect survival?
5. Did cabin location influence survival?
6. Did family size affect survival?
7. Did social title (Mr., Mrs., Miss., Master.) predict survival?

---

## Methodology

### Data Cleaning View

A `titanic_clean` SQL view was created to:
- Exclude rows with NULL Age for age-based analysis
- Derive a `traveling_alone` flag (1 if SibSp = 0 AND Parch = 0)
- Extract social title from the Name column using LOCATE() and SUBSTRING()

Additional working tables were built for family analysis:
- `titanic_with_family_id` — assigns a family_id using CONCAT(last_name, ticket)
- `titanic_family_size` — computes family size per family_id
- `titanic_with_family_size` — joins family size back to the passenger record
- `titanic_with_title` — adds the extracted social title to each passenger

### EDA Issues Found

1. Cabin column has >70% missing values — cabin-based results should be interpreted with caution
2. Age column has some missing values — filtered out in the clean view
3. No explicit primary key — PassengerId used as the unique identifier
4. No duplicate records found (confirmed via COUNT vs COUNT DISTINCT on PassengerId)

---

## Key Findings

### Survival by Gender
| Gender | Survival Rate |
|---|---|
| Female | ~75% |
| Male | ~21% |

Gender was the strongest single predictor of survival, directly reflecting the "women and children first" evacuation policy.

### Survival by Passenger Class
| Class | Survival Rate |
|---|---|
| 1st | ~66% |
| 2nd | ~47% |
| 3rd | ~24% |

First-class passengers had nearly three times the survival rate of third-class passengers, likely due to cabin proximity to lifeboats and preferential boarding access.

### Survival by Family Size
| Family Size | Survival Rate |
|---|---|
| Solo (1) | ~36% |
| Small (2-4) | >50% |
| Large (5+) | ~0% |

Small families had the best outcomes. Very large families likely struggled to stay together during the chaotic evacuation.

### Survival by Title
| Title | Survival Rate |
|---|---|
| Mrs. | >80% |
| Miss. | >70% |
| Master. | ~58% |
| Mr. | ~17% |

The title analysis strongly confirms the "women and children first" policy. Master. (young boys) also benefited significantly compared to adult males.

### Solo Traveler Gender Gap
- Solo female passengers: **~80% survival rate**
- Solo male passengers: **~18% survival rate**

Even when traveling alone, gender remained the dominant factor.

### Cabin Decks
Decks C, D, and E had the highest survival rates (all >70%), likely due to proximity to lifeboat stations. However, >70% of cabin data is missing, so these results apply only to the subset of passengers with known cabin assignments.

---

## Historical Context

The Titanic mortality rate (~59%) was significantly higher than comparable disasters of the era:

| Event | Mortality Rate |
|---|---|
| Titanic (1912) | ~59% |
| Spanish Flu (1918-1920) | ~10% |
| World War I (1914-1918) | ~15% |

While the Spanish Flu and WWI caused far greater absolute numbers of deaths, a passenger aboard the Titanic faced a much higher individual probability of dying than a soldier in WWI or a person infected during the Spanish Flu.

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| MySQL | EDA, data cleaning, view and table creation, survival analysis |
| SQL (LOCATE, SUBSTRING, CONCAT) | String parsing for title and family_id extraction |
| SQL (JOIN, GROUP BY, CASE WHEN) | Multi-table analysis and conditional aggregation |
