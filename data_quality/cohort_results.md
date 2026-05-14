# Cohort Results — Data Profiling & Quality Assessment

## Table Overview

The `cohort_results` table is the primary microbiology culture fact table in the ARMD dataset.  
It contains organism identification and antibiotic susceptibility testing results associated with patient culture orders.

### Expected Grain
One row represents:

> One organism–antibiotic susceptibility result for a specific culture order.

---

# Data Quality Issues (DQ)

| Issue ID | Column                               | Issue Description                                                                                                            | Magnitude | Affected Rows                                                                     | Solvable?         | Status   | Fix Applied                                                                                               |
| -------- | ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------- | --------- | --------------------------------------------------------------------------------- | ----------------- | -------- | --------------------------------------------------------------------------------------------------------- |
| DQ-001   | Multiple Columns                     | Missing values represented as the string `"null"` instead of actual SQL `NULL` values in raw CSV files                       | High      | Multiple tables                                                                   | Yes               | Resolved | `NULLIF()` applied during import                                                                          |
| DQ-002   | organism, antibiotic, susceptibility | High missingness driven primarily by `was_positive = 0` (negative cultures / no organism growth, therefore no AST performed) | High      | 632,308 organism/antibiotic NULLs (28.21%), 634,468 susceptibility NULLs (28.31%) | Yes (interpreted) | Resolved | Negative cultures mapped to `NO_GROWTH` and `NOT_TESTED` analytical states                                |
| DQ-003   | care_setting                         | Missing care setting values affecting ward-based analysis                                                                    | Low       | 73,042 rows (3.26%)                                                               | Yes               | Removed  | Rows with NULL `care_setting` deleted prior to ward-based analysis                                        |
| DQ-004   | organism, antibiotic, susceptibility | Positive cultures (`was_positive = 1`) with entirely missing microbiology results                                            | Very Low  | 1,208 rows (0.06%)                                                                | Yes               | Removed  | Deleted anomalous rows with NULL organism, antibiotic, and susceptibility despite positive culture status |
| DQ-005   | susceptibility                       | Missing susceptibility values despite identified organism and antibiotic in positive cultures                                | Very Low  | ~2,160 rows (0.10%)                                                               | Yes               | Removed  | Deleted unresolved AST outcome records where susceptibility could not be inferred                         |
---

## DQ-002 Notes (Key Interpretation)
Some NULL values in microbiology fields are structurally driven by the clinical microbiology workflow rather than representing true data quality failures:

- was_positive = 0 → no organism growth detected
- No organism growth → no antibiotic susceptibility testing (AST) performed 
- Therefore:
    - organism → NO_GROWTH
    - antibiotic → NOT_TESTED
    - susceptibility → NOT_TESTED

These values were standardized to improve analytical interpretability while preserving the underlying clinical meaning.

---

## DQ Resolution Decisions

### 1. Care Setting Handling

To support ward-based resistance analysis (ICU, inpatient, outpatient, ER):

```sql
DELETE FROM cohort_results
WHERE care_setting IS NULL;
```

### Justification:
- Low missingness (~3%)
- Critical variable for objective: **ward-based resistance analysis**
- Removing preserves interpretability across clinical settings

---

### 2. Standardizing Microbiology NULL Values

To ensure consistent clinical interpretation:

```sql
-- negative cultures represent no organism growth
UPDATE cohort_results
SET organism = 'NO_GROWTH'
WHERE organism IS NULL
AND was_positive = 0;
```

```sql
-- negative culture means no organism, therefore no AST (Antimicrobial Sensitivity Test)
UPDATE cohort_results
SET antibiotic = 'NOT_TESTED'
WHERE antibiotic IS NULL
AND was_positive = 0;
```

```sql
-- no AST for negative cultures
UPDATE cohort_results
SET susceptibility = 'NOT_TESTED'
WHERE susceptibility IS NULL
AND was_positive = 0;
```
---
### 3. Removing the anomalies

```sql
-- unresolved susceptibility despite organism and antibiotic being present
DELETE FROM cohort_results
WHERE susceptibility IS NULL
AND organism IS NOT NULL
AND antibiotic IS NOT  NULL
AND was_positive = 1;
```
### Justification:
- AST outcome cannot be reliably inferred
- Magnitude is extremely low
- Retaining such rows could bias resistance calculations

```sql
-- positive cultures with entirely missing microbiology results
DELETE FROM cohort_results
WHERE was_positive = 1
  AND organism IS NULL
  AND antibiotic IS NULL
  AND susceptibility IS NULL;
```
### Justification:
- Positive cultures should produce organism identification and/or AST output
- Low magnitude makes removal analytically safe
---

## DQ-002 / DQ-003 Detection Query

```sql
SELECT
    COUNT(*) AS total_records,

    SUM(care_setting IS NULL) AS null_care_setting,
    ROUND(SUM(care_setting IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_care_setting,

    SUM(organism IS NULL) AS null_organism,
    ROUND(SUM(organism IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_organism,

    SUM(antibiotic IS NULL) AS null_antibiotic,
    ROUND(SUM(antibiotic IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_antibiotic,

    SUM(susceptibility IS NULL) AS null_susceptibility,
    ROUND(SUM(susceptibility IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_susceptibility
    
FROM cohort_results;
```

---

# Data Validation Checks (DV)

| Check ID | Validation Description | Result | Status |
|----------|------------------------|--------|--------|
| DV-001 | Checked for duplicate organism–antibiotic–susceptibility records per culture order | No duplicates found | Passed |
| DV-002 | Validated `was_positive` domain consistency | Only values {0,1} observed | Passed |
| DV-003 | Validated care_setting categorical integrity | Only inpatient and outpatient observed after cleaning | Passed |
| DV-004 | Checked empty string contamination | None found | Passed |
| DV-005 | Whitespace validation on categorical fields | No issues found | Passed |
| DV-006 | Temporal validation of culture_time | 1999–2024 valid range confirmed | Passed |
| DV-007 | organism vs was_positive dependency check | Deterministic relationship confirmed | Passed |

---

## DV-001 Query

```sql
SELECT
    culture_order_id,
    organism,
    antibiotic,
    susceptibility,
    COUNT(*) AS duplicate_count
FROM cohort_results
GROUP BY
    culture_order_id,
    organism,
    antibiotic,
    susceptibility
HAVING COUNT(*) > 1;
```

---

# Additional Table Observations

| Observation ID | Observation                                                                                                                                      |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| OBS-001        | ~2.16 million microbiology susceptibility records retained after cleaning                                                                        |
| OBS-002        | ~283,000 unique patients represented                                                                                                             |
| OBS-003        | One culture order expands into multiple antibiotic susceptibility tests                                                                          |
| OBS-004        | Up to ~32 antibiotics tested per culture order                                                                                                   |
| OBS-005        | Susceptibility completeness reflects conditional AST workflow dependent on organism growth                                                       |
| OBS-006        | Organism distribution is clinically realistic and dominated by common bacterial pathogens such as *Escherichia coli* and *Klebsiella pneumoniae* |
| OBS-007        | Resistance distributions align with expected hospital-associated infection patterns                                                              |


---

# Interpretation Notes

- Missing values in microbiology fields are workflow-driven, not data corruption
- `was_positive` is the key driver of organism and susceptibility availability
- Standardized analytical states were introduced to preserve microbiological meaning:
    - **NO_GROWTH** → culture-negative specimen
    - **NOT_TESTED** → AST not performed
- Extremely low-frequency anomalous positive cultures with unresolved microbiology outputs were removed
- Rows with missing care_setting were removed to preserve interpretability in ward-based resistance analysis
