# Antibiotic Exposure — Data Profiling & Quality Assessment

## Table Overview

The `antibiotic_exposure` table describes prior antibiotic exposure history associated with microbiology culture orders.

The table contains:
- medication name
- antibiotic class
- medication category code
- temporal distance between antibiotic exposure and culture collection

---

## Expected Grain

> One row represents prior exposure event to antibiotic for a single culture order.

---

# Data Quality Issues (DQ)

| Issue ID | Column                | Issue Description                                                                                                                     | Magnitude          | Affected Rows        | Solvable? | Fix / Decision                                                                                                                  | Status      |
| -------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------ | -------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| DQ-001   | days_before_culture   | Very long historical exposure windows (>10 years prior to culture) observed                                                           | Low                | 137,395 rows (2.54%) | Yes       | Retained after validation since exposure windows remain plausible within the dataset collection timeline and patient age ranges | Interpreted |
| DQ-002   | med_category          | Encoded medication category abbreviations require metadata interpretation due to undocumented suffix variants (e.g., `CIP1`, `CEF10`) | Low                | Multiple codes       | Partially | Retained as auxiliary metadata since medication and antibiotic class fields provide interpretable clinical meaning              | Interpreted |
| DQ-003   | exposure multiplicity | Multiple exposure records observed for single culture orders due to longitudinal medication history                                   | Expected Structure | Multiple rows        | N/A       | Retained as valid many-to-one exposure relationship                                                                             | Interpreted |
| DQ-004   | medication | Medication names are recorded as a mix of brand names, generic names, and formulation variants without standardization. For example, Zyvox and Linezolid refer to the same Oxazolidinone drug, and formulation variants such as Ceftazidime and Ceftazidime-Dextrose appear as distinct entries | Moderate | Multiple rows | Partially | Retained as recorded. Resistance analysis performed at antibiotic class level for greater accuracy. Medication-level rankings should be interpreted with caution. A medication name mapping table would be required to fully resolve this | Interpreted |

---
## DQ-001 Detection Query
```sql
SELECT
    CASE
        WHEN days_before_culture BETWEEN 0 AND 7 THEN '0-7 days'
        WHEN days_before_culture BETWEEN 8 AND 30 THEN '8-30 days'
        WHEN days_before_culture BETWEEN 31 AND 90 THEN '31-90 days'
        WHEN days_before_culture BETWEEN 91 AND 365 THEN '91-365 days'
        WHEN days_before_culture BETWEEN 366 AND 1825 THEN '1-5 years'
        WHEN days_before_culture BETWEEN 1826 AND 3650 THEN '6-10 years'
        ELSE '>10 years' 
    END AS time_bucket,
    COUNT(*) AS freq
FROM antibiotic_exposure
GROUP BY time_bucket
ORDER BY freq DESC;
```
---
## DQ-003 Detection Query
```sql
SELECT
    culture_order_id,
    COUNT(*) AS exposure_count
FROM antibiotic_exposure
GROUP BY culture_order_id
ORDER BY exposure_count DESC
LIMIT 20;
```

---

# Data Validation Checks (DV)
| Check ID | Validation Description                                              | Result                                            | Status |
| -------- | ------------------------------------------------------------------- | ------------------------------------------------- | ------ |
| DV-001   | Checked for duplicate exposure records per culture order | No duplicates found                               | Passed |
| DV-002   | Validated antibiotic class authenticity              | Antibiotic classes were clinically valid and consistently structured                     | Passed |
| DV-003   | Validated missingness across antibiotic exposure columns                 | No NULL values detected                           | Passed |
| DV-004   | Validated empty string rows across antibiotic exposure columns                 | No empty string values found                          | Passed |
| DV-005   | Validated temporal exposure range               | Minimum exposure window was 1 day and maximum was 5,748 days (~15.7 years), remaining admissible considering patients age groups                         | Passed |
| DV-006   | Checked referential integrity against cohort table             | No orphaned records exposure found                      | Passed |


---
## DV-001 Query
```sql
SELECT
    culture_order_id,
    medication,
    antibiotic_class,
    days_before_culture,
    COUNT(*) AS freq
FROM antibiotic_exposure
GROUP BY
    culture_order_id,
    medication,
    antibiotic_class,
    days_before_culture
HAVING COUNT(*) > 1;
```
---

## DV-002 Query
```sql
SELECT
    antibiotic_class,
    COUNT(*) AS freq
FROM antibiotic_exposure
GROUP BY antibiotic_class
ORDER BY freq DESC;
```

---

## DV-003 Query
```sql
SELECT
    COUNT(*) AS total_records,
    SUM(med_category IS NULL) AS null_med_category,
    SUM(medication IS NULL) AS null_medication,
    SUM(antibiotic_class IS NULL) AS null_antibiotic_class,
    SUM(days_before_culture IS NULL) AS null_days_before_culture
FROM antibiotic_exposure;
```
---

## DV-004 Query
```sql
SELECT
    COUNT(*) AS empty_string_rows
 FROM antibiotic_exposure
 WHERE medication = ''
    OR antibiotic_class = ''
    OR med_category = '';
```
---

## DV-005 Query
```sql
SELECT
     MIN(days_before_culture) AS min_days,
     MAX(days_before_culture) AS max_days
 FROM antibiotic_exposure;
```
---
## DV-006 Query
```sql
SELECT
    COUNT(*) AS total_exposures,
    SUM(c.culture_order_id IS NULL) AS orphan_exposures
FROM antibiotic_exposure a
LEFT JOIN cohort_results c
    ON a.culture_order_id = c.culture_order_id;
```
---

# Additional Observations
| Observation ID | Observation                                                                                                                    |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| OBS-001        | The table contains over 5.4 million antibiotic exposure records                                                                |
| OBS-002        | Most exposure histories fall within the 1–5 year period before culture collection                                              |
| OBS-003        | Beta-lactam-related antibiotic classes and Fluoroquinolones constitute a substantial proportion of historical exposure records   |
| OBS-004        | Exposure history is longitudinal in nature, resulting in many-to-one relationships between exposure records and culture orders |
| OBS-005        | Medication names contain brand name, generic name, and formulation duplicates which may understate resistance rates at the individual medication level. Antibiotic class grouping is recommended as the more reliable unit of analysis |



---
## Interpretation Notes

The antibiotic exposure table is structurally consistent and clinically plausible.

Very long exposure windows (>10 years) likely reflect retained historical EHR medication histories rather than data entry anomalies.

Multiple exposure rows per culture order are expected due to the longitudinal nature of antibiotic treatment histories.


