# Demographics — Data Profiling & Quality Assessment

## Table Overview

The `demographics` table contains de-identified patient demographic information associated with microbiology culture orders.

The table includes:
- age group classification
- binary encoded gender values (`0` and `1`) without disclosure of the corresponding gender mapping.

---

## Expected Grain

> One row represents patient demographic information for a single culture order.

---

# Data Quality Issues (DQ)

| Issue ID | Column | Issue Description | Magnitude | Affected Rows | Solvable? | Fix / Decision | Status |
|----------|--------|------------------|------------|----------------|------------|-----------------|--------|
| DQ-001 | gender | Missing gender values across a small number of records | Low | 120 rows (0.02%) | yes | Retained as NULL due to insignificant magnitude and lack of mapping definition | Interpreted |
| DQ-002 | age_group | Minor categorical formatting inconsistencies observed in age group labels (e.g. "30 years" and "above 90") | Low | All age_group rows | Yes | Resolved | Standardized to compact categorical labels |
---

## DQ-001 

```sql
SELECT
    COUNT(*) AS total_records,

    SUM(age_group IS NULL) AS null_age_group,
    ROUND(SUM(age_group IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_age_group,

    SUM(gender IS NULL) AS null_gender,
    ROUND(SUM(gender IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_gender

FROM demographics;
```
---

## DQ-002 Detection Query

```sql
SELECT COUNT(age_group) 
FROM demographics 
WHERE age_group LIKE '%years';
```
---

## DQ-002 Resolution Query
```sql
UPDATE demographics
SET age_group =
    CASE
        WHEN TRIM(age_group) = 'above 90' THEN '90+'
        ELSE REPLACE(age_group, ' years', '')
    END
WHERE age_group LIKE '%years'
   OR TRIM(age_group) = 'above 90';
```
---

# Data Validation Checks (DV)

| Check ID | Validation Description | Result | Status |
|----------|------------------------|--------|--------|
| DV-001   | Checked for duplicate demographic records per culture order | No duplicates found                                | Passed |
| DV-002   | Validated age group category integrity                      | Age groups fall within expected categorical ranges | Passed |
| DV-003   | Validated gender domain consistency                         | Only binary values `{0,1}` and NULL observed       | Passed |
| DV-004   | Checked for empty strings in demographic columns            | No empty strings detected                          | Passed |



---

## DV-001 Query

```sql
SELECT
    culture_order_id,
    age_group,
    gender,
    COUNT(*) AS duplicate_count
FROM demographics
GROUP BY
    culture_order_id,
    age_group,
    gender
HAVING COUNT(*) > 1;
```

---

## DV-002 Query

```sql
SELECT DISTINCT age_group
FROM demographics
ORDER BY age_group;
```

---

## DV-003 Query

```sql
SELECT DISTINCT gender
FROM demographics;
```
---

## DV-004 Query

```sql
SELECT
    SUM(age_group = '') AS empty_age_group
FROM demographics;
```
---



# Additional Observations

| Observation ID | Observation |
|----------------|------------|
| OBS-001        | The table contains approximately 751,075 demographic-linked culture records                            |
| OBS-002        | Most patients fall within older adult age groups, particularly between 55–84 years                     |
| OBS-003        | Demographic records appear structurally complete with very low missingness                             |
| OBS-004        | Gender encoding is intentionally anonymized and cannot be clinically interpreted as male/female labels |


---

# Interpretation Notes
- No major structural or relational data quality issues were identified.
- Missing gender values are minimal and unlikely to impact downstream analysis.
- Age groups were successful standardized into a consistent categorical format


