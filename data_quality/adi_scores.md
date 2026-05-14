# ADI Scores — Data Profiling & Quality Assessment

## Table Overview

The `adi_scores` table contains Area Deprivation Index (ADI) metrics associated with microbiology culture events.

ADI is a neighborhood-level socioeconomic disadvantage metric derived from patient ZIP-code linkage using the Neighborhood Atlas framework.

The table provides socioeconomic context for antimicrobial resistance analysis and related healthcare disparity investigations.

---

## Expected Grain

> One row represents ADI socioeconomic enrichment information for a single culture order.

---

# Data Quality Issues (DQ)
| Issue ID | Column                    | Issue Description                                                                                                        | Magnitude | Affected Rows | Solvable? | Fix / Decision                                        | Status      |
| -------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------ | --------- | ------------- | --------- | ----------------------------------------------------- | ----------- |
| DQ-001   | adi_score, adi_state_rank | Missing ADI values (~21.68%) across records                                                                              | High      | 162,803 rows  | No        | Retained as NULL values     | Interpreted |
| DQ-002   | adi_score, adi_state_rank | Missingness is methodology-driven (ZIP-code linkage limitations + partial upstream imputation using 5-digit aggregation) | Medium    | 162,803 rows  | No        | Preserved as NULL; handled via analysis layer (views) | Interpreted |
| DQ-003   | adi_score, adi_state_rank | Structural missingness consistency: both fields are always NULL together                                                 | Low       | 162,803 rows  | N/A       | No action required                                    | Validated   |


---

## DQ-001 / DQ-002 Detection Query

```sql
SELECT 
    COUNT(*) AS total_records, 

    SUM(adi_score IS NULL) AS null_adi_score,
    ROUND(SUM(adi_score IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_adi_score,

    SUM(adi_state_rank IS NULL) AS null_adi_state_rank,
    ROUND(SUM(adi_state_rank IS NULL) * 100.0 / COUNT(*), 2) AS pct_null_adi_state_rank

FROM adi_scores;
```

---

## DQ-003 Detection Query

```sql
SELECT
    COUNT(*) AS total,

    SUM(adi_score IS NULL AND adi_state_rank IS NULL) AS both_null,

    SUM(adi_score IS NULL AND adi_state_rank IS NOT NULL) AS score_only_null,

    SUM(adi_score IS NOT NULL AND adi_state_rank IS NULL) AS rank_only_null

FROM adi_scores;
```

---

# Data Validation Checks (DV)

| Check ID | Validation Description | Result | Status |
|----------|------------------------|--------|--------|
| DV-001 | Checked for duplicate ADI records per culture order | No duplicates found | Passed |
| DV-002 | Validated ADI numeric range | ADI scores fall within expected range (1–100) | Passed |
| DV-003 | Validated referential integrity with `cohort_results` | No orphaned records found | Passed |
| DV-004 | Validated cohort coverage | 100% cohort linkage coverage achieved | Passed |
| DV-005 | Evaluated temporal missingness trends | Missingness decreases in later years, consistent with EHR/geocoding improvements | Passed |
| DV-006 | Validated structural missingness consistency | No partial NULL inconsistencies detected | Passed |

---

## DV-001 Query

```sql
SELECT
    culture_order_id,
    adi_score,
    adi_state_rank,
    COUNT(*) AS duplicate_count
FROM adi_scores
GROUP BY
    culture_order_id,
    adi_score,
    adi_state_rank
HAVING COUNT(*) > 1;
```

---

## DV-002 Query

```sql
SELECT
    MIN(adi_score) AS min_score,
    MAX(adi_score) AS max_score,
    AVG(adi_score) AS mean_score
FROM adi_scores;
```

---

## DV-003 Query

```sql
SELECT
    COUNT(*) AS total_adi_rows,

    SUM(c.culture_order_id IS NULL) AS orphaned_rows,

    ROUND(
        SUM(c.culture_order_id IS NULL) * 100.0 / COUNT(*),
        2
    ) AS pct_orphaned

FROM adi_scores a
LEFT JOIN cohort_results c
    ON a.culture_order_id = c.culture_order_id;
```

---

## DV-004 Query

```sql
SELECT
    COUNT(*) AS cohort_rows,

    SUM(a.culture_order_id IS NOT NULL) AS matched_adi,

    ROUND(
        SUM(a.culture_order_id IS NOT NULL) * 100.0 / COUNT(*),
        2
    ) AS pct_covered

FROM cohort_results c
LEFT JOIN adi_scores a
    ON c.culture_order_id = a.culture_order_id;
```

---

## DV-005 Query

```sql
SELECT
    YEAR(c.culture_time) AS year,

    COUNT(*) AS total,

    SUM(a.adi_score IS NULL) AS missing_adi

FROM cohort_results c
LEFT JOIN adi_scores a
    ON c.culture_order_id = a.culture_order_id

GROUP BY YEAR(c.culture_time)
ORDER BY year;
```
---
### ADI Views 

```sql
-- null excluded
CREATE VIEW adi_complete_case AS
 SELECT *
 FROM adi_scores
 WHERE adi_score IS NOT NULL;
```
```sql
-- full dataset, grouped into categories
CREATE VIEW adi_full_analysis AS
 SELECT
     *,
     CASE
         WHEN adi_score IS NULL THEN 'UNKNOWN'
         WHEN adi_score < 25 THEN 'LOW'
         WHEN adi_score BETWEEN 25 AND 75 THEN 'MEDIUM'
         ELSE 'HIGH'
     END AS adi_group
 FROM adi_scores;
```

---

# Additional Observations

| Observation ID | Observation |
|----------------|------------|
| OBS-001 | The table contains 751,075 ADI-linked culture records |
| OBS-002 | The average ADI score is relatively low (~8.35), suggesting many patients originate from lower deprivation neighborhoods |

---

# Initial Interpretation Notes

- Missing ADI values are workflow-driven and methodology-driven rather than data corruption.

- According to the dataset documentation ([ARMD Article](https://pubmed.ncbi.nlm.nih.gov/40715119/)):
  - ADI values were derived using Neighborhood Atlas ZIP-code linkage.
  - Partial upstream imputation was already performed using 5-digit ZIP aggregation.
  - Remaining unresolved geographic mappings were intentionally preserved as NULL values.

- Missingness should therefore be interpreted as:
  - unavailable socioeconomic enrichment
  - unresolved ZIP-code linkage
  - invalid or incomplete geographic reference data

- Missingness appears relatively stable across outcome groups, reducing concern for major selection bias.

- ADI NULL values may themselves contain socioeconomic signal and should not be blindly imputed.



