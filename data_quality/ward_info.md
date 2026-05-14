# Ward Info — Data Profiling & Quality Assessment

## Table Overview

The `ward_info` table describes the clinical care setting associated with microbiology culture collection.

The table contains binary ward classification indicators representing:
- inpatient encounters
- outpatient encounters
- emergency room (ER) involvement
- intensive care unit (ICU) involvement

---

## Expected Grain

> One row represents ward classification metadata for a single culture order.

---

# Data Quality Issues (DQ)

| Issue ID | Column | Issue Description | Magnitude | Affected Rows | Solvable? | Fix / Decision | Status |
|----------|--------|------------------|------------|----------------|------------|-----------------|--------|
| DQ-001 | Ward classification flags | Some records contain no ward assignment (`0,0,0,0`) across all ward indicators | Low | 11,658 rows (~1.55%) | Yes | Removed due to undefined clinical ward assignment | Resolved |
| DQ-002 | is_outpatient + is_er | Rare multi-label classification where outpatient encounters also involve ER service flags | Extremely Low | 5 rows | No | Retained as valid multi-context clinical workflows | Interpreted |
| DQ-003 | is_outpatient + is_icu | Rare multi-label classification where outpatient encounters also include ICU flag | Extremely Low | 3 rows | No | Retained as valid but unusual clinical encoding cases | Interpreted |

---

## DQ-001 Detection Query

```sql
SELECT COUNT(*) AS no_ward_assignment
FROM ward_info
WHERE (
    is_inpatient +
    is_outpatient +
    is_er +
    is_icu
) = 0;
```
---
## DQ-002 / DQ-003 Detection Query
```sql
SELECT
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu,
    COUNT(*) AS total
FROM ward_info
GROUP BY
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu
ORDER BY total DESC;
```
---

## DQ-001 Resolution Query
```sql
DELETE FROM ward_info
WHERE is_inpatient = 0
AND is_outpatient = 0
AND is_er = 0
AND is_icu = 0;
```
---


# Data Validation Checks (DV)
| Check ID | Validation Description                                              | Result                                            | Status |
| -------- | ------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| DV-001   | Checked for duplicate ward classification records per culture order | No duplicates found                               | Passed |
| DV-002   | Validated boolean integrity of ward indicator columns               | Only values `{0,1}` observed                      | Passed |
| DV-003   | Validated missingness across ward indicator columns                 | No NULL values detected                           | Passed |
| DV-004   | Evaluated multi-ward classification combinations                    | Most overlapping classifications clinically valid | Passed |
| DV-005   | Cross-table validation against `cohort_results.care_setting`        | Strong consistency observed                       | Passed |

---
## DV-001 Query
```sql
SELECT
    culture_order_id,
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu
FROM ward_info
GROUP BY
    culture_order_id,
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu
HAVING COUNT(*) > 1;
```
---

## DV-002 Query
```sql
SELECT COUNT(*) AS invalid_rows
FROM ward_info
WHERE is_inpatient NOT IN (0,1)
   OR is_outpatient NOT IN (0,1)
   OR is_er NOT IN (0,1)
   OR is_icu NOT IN (0,1);
```

---

## DV-003 Query
```sql
SELECT 
    COUNT(*) AS total_records, 
    SUM(is_inpatient IS NULL) AS null_ip,
    SUM(is_outpatient IS NULL) AS null_op,
    SUM(is_er IS NULL) AS null_er,
    SUM(is_icu IS NULL) AS null_icu
FROM ward_info;
```
---

## DV-004 Query
```sql
SELECT
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu,
    COUNT(*) AS total
FROM ward_info
GROUP BY
    is_inpatient,
    is_outpatient,
    is_er,
    is_icu
ORDER BY total DESC;
```
---

## DV-005 Query
```sql
SELECT
    c.care_setting,
    w.is_inpatient,
    w.is_outpatient,
    COUNT(*) AS total
FROM cohort_results c
JOIN ward_info w
    ON c.culture_order_id = w.culture_order_id
GROUP BY
    c.care_setting,
    w.is_inpatient,
    w.is_outpatient
ORDER BY total DESC;
```

---

# Additional Observations
| Observation ID | Observation                                                                                          |
| -------------- | ---------------------------------------------------------------------------------------------------- |
| OBS-001        | The table contains approximately 751,075 ward-linked culture records                                 |
| OBS-002        | Outpatient-only encounters represent the largest ward category                                       |
| OBS-003        | ER and ICU indicators behave as hierarchical sub-settings of inpatient care                          |
| OBS-004        | Most overlapping ward combinations are clinically explainable rather than contradictory              |
| OBS-005        | `care_setting` values from `cohort_results` align strongly with inpatient/outpatient ward flags      |
| OBS-006        | A small subset of records lack ward assignment entirely and correspond to NULL `care_setting` values |


---

## Interpretation Notes

Ward classifications are structurally consistent and represent a multi-label encoding system rather than mutually exclusive categories.

ER and ICU flags should be interpreted as supplemental encounter attributes that may co-exist with inpatient or outpatient classifications depending on workflow and billing/contextual recording practices.

Common multi-ward combinations such as:
- inpatient + ER
- inpatient + ICU
- inpatient + ER + ICU

are consistent with expected hospital care escalation pathways and are frequently observed in the dataset.

Less common combinations such as outpatient + ER or outpatient + ICU are rare and likely reflect specific care pathways, short-stay encounters, or EHR recording artifacts. These were retained due to negligible impact on downstream analysis.

Records with all ward flags equal to 0 represented undefined clinical ward assignments and were removed during cleaning to preserve interpretability in ward-level analysis.


