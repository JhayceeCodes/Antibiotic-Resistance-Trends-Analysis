# Prior Infections — Data Profiling & Quality Assessment

## Table Overview

The `prior_infections` table captures historical microbiology infection records linked to each patient encounter and culture order.

It provides context on previous infections and the time elapsed between prior and current infection events.

---

## Expected Grain

> One row represents a prior infection event for a patient associated with a specific culture order.

The table is inherently **one-to-many**, as a single culture order may have multiple prior infection records.

---

# Data Quality Issues (DQ)

## No Issues Observed

All evaluated data quality dimensions passed validation:

- No missing values in `prior_organism`
- No missing values in `days_since_prior_infection`
- No invalid or out-of-range values detected
- No structural data corruption observed

The dataset is considered clean and consistent.

---

# Data Validation Checks (DV)

| Check ID | Validation Description | Result | Status |
|----------|------------------------|--------|--------|
| DV-001 | Checked for missing prior organism values | None found | Passed |
| DV-002 | Checked for missing temporal gap values | None found | Passed |
| DV-003 | Verified temporal range validity (min, max, avg) | Valid range (1–5770 days) | Passed |
| DV-004 | Checked for exact duplicate rows | No duplicates found | Passed |

---

## DV Queries
```sql
-- DV-001
SELECT COUNT(*) 
FROM prior_infections
WHERE prior_organism IS NULL;

-- DV-002
SELECT COUNT(*) 
FROM prior_infections
WHERE days_since_prior_infection IS NULL;

-- DV-003
SELECT 
    MIN(days_since_prior_infection),
    MAX(days_since_prior_infection),
    AVG(days_since_prior_infection)
FROM prior_infections;

-- DV-004
SELECT
    anon_id,
    encounter_id,
    culture_order_id,
    prior_organism,
    days_since_prior_infection,
    COUNT(*) AS freq
FROM prior_infections
GROUP BY
    anon_id,
    encounter_id,
    culture_order_id,
    prior_organism,
    days_since_prior_infection
HAVING COUNT(*) > 1;
```
---

# Additional Observations
| Observation ID | Observation                                                                              |
| -------------- | ---------------------------------------------------------------------------------------- |
| OBS-001        | The table contains ~1.08 million prior infection records                                 |
| OBS-002        | Multiple prior infections per culture order are expected and clinically meaningful       |
| OBS-003        | Temporal gap ranges from 1 to 5770 days, indicating long-term infection history tracking |
| OBS-004        | Mean time since prior infection is approximately 3 years                                 |

---
# Interpretation Notes
The dataset is clean and complete with respect to prior infection tracking.

No cleaning or transformation is required before analysis.

