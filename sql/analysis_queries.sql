-- Top 15 organisms
SELECT
    organism AS 'Organism',
    COUNT(*) AS 'Total Tested',
    SUM(susceptibility = 'Resistant') AS 'Resistant Count',
    ROUND(SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS '% Resistant'
FROM cohort_results
WHERE susceptibility <> 'NOT_TESTED'
GROUP BY organism
HAVING `Total Tested` >= 100
ORDER BY `% Resistant` DESC
LIMIT 15;


-- Top 15 antibiotics
SELECT
    antibiotic AS 'Antibiotic',
    COUNT(*) AS 'Total Tested',
    SUM(susceptibility = 'Resistant') AS 'Resistant Count',
    ROUND(SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS '% Resistant'
FROM cohort_results
WHERE susceptibility <> 'NOT_TESTED'
AND antibiotic IS NOT NULL
GROUP BY antibiotic
HAVING COUNT(*) >= 100
ORDER BY `% Resistant` DESC, `Resistant Count` DESC 
LIMIT 15;


-- Resistance rates with prior antibiotic classes
SELECT
    ae.antibiotic_class AS 'Antibiotic Class',
    COUNT(*) AS 'Total Tested',
    SUM(cr.susceptibility = 'Resistant') AS 'Resistant Count',
    ROUND(SUM(cr.susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS '% Resistant'
FROM cohort_results cr
JOIN antibiotic_exposure ae
    ON cr.culture_order_id = ae.culture_order_id
WHERE cr.susceptibility <> 'NOT_TESTED'
GROUP BY ae.antibiotic_class
ORDER BY `% Resistant` DESC;


-- Antibiotic classes resistance burden and rates
SELECT
    antibiotic AS 'Antibiotic',
    COUNT(*) AS 'Total Tested',
    SUM(susceptibility = 'Resistant') AS 'Resistant Count',
    ROUND(SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS '% Resistant'
FROM cohort_results
WHERE susceptibility <> 'NOT_TESTED'
AND antibiotic IS NOT NULL
GROUP BY antibiotic
HAVING COUNT(*) >= 100
ORDER BY `Resistant Count` DESC;


-- Antibiotics becoming less effective 
SELECT
    DATE_FORMAT(culture_time, '%Y') AS year,
    antibiotic,
    COUNT(*) AS total_tested,
    ROUND(SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS pct_resistant
FROM cohort_results
WHERE susceptibility <> 'NOT_TESTED'
AND antibiotic IS NOT NULL
GROUP BY year, antibiotic
HAVING total_tested >= 500
ORDER BY year ASC;


-- Yearly trend of antibiotics resistance
SELECT
    DATE_FORMAT(culture_time, '%Y') AS year,
    COUNT(*) AS total_tested,
    SUM(susceptibility = 'Resistant') AS resistant_count,
    ROUND(SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS pct_resistant
FROM cohort_results
WHERE susceptibility <> 'NOT_TESTED'
AND YEAR(culture_time) BETWEEN 2008 AND 2023
GROUP BY year
ORDER BY year ASC;



-- Inpatient VS outpatient settings resistance distribution
SELECT
    CASE
        WHEN care_setting = 'inpatient' THEN 'Inpatient'
        WHEN care_setting = 'outpatient' THEN 'Outpatient'
        ELSE care_setting
    END AS care_setting,
    COUNT(*) AS total_tested,
    SUM(susceptibility = 'Resistant') AS resistant_count,
    ROUND(
        SUM(susceptibility = 'Resistant') * 100.0 / COUNT(*),
        2
    ) AS pct_resistant

FROM cohort_results

WHERE susceptibility <> 'NOT_TESTED'

GROUP BY care_setting
ORDER BY pct_resistant DESC;


-- Inpatient ward patition
SELECT
    CASE
        WHEN w.is_icu = 1 THEN 'ICU'
        WHEN w.is_er = 1 THEN 'ER'
        ELSE 'Standard Ward'
    END AS ward_partition,
    COUNT(*) AS total_tested,
    SUM(c.susceptibility = 'Resistant') AS resistant_count,
    ROUND(
        SUM(c.susceptibility = 'Resistant') * 100.0 / COUNT(*),
        2
    ) AS pct_resistant
FROM cohort_results c
JOIN ward_info w
    ON c.culture_order_id = w.culture_order_id
WHERE c.susceptibility <> 'NOT_TESTED'
AND c.care_setting = 'inpatient'
GROUP BY ward_partition
ORDER BY pct_resistant DESC;


-- Antibiotic exposure recency VS resistance rates
SELECT
    CASE
        WHEN ae.days_before_culture <= 30 THEN '0-30 days'
        WHEN ae.days_before_culture <= 90 THEN '31-90 days'
        WHEN ae.days_before_culture <= 180 THEN '91-180 days'
        WHEN ae.days_before_culture <= 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS exposure_recency,
    COUNT(*) AS total_tested,
    SUM(c.susceptibility = 'Resistant') AS resistant_count,
    ROUND(SUM(c.susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS pct_resistant
FROM cohort_results c
JOIN antibiotic_exposure ae
    ON c.culture_order_id = ae.culture_order_id
WHERE c.susceptibility <> 'NOT_TESTED'
GROUP BY exposure_recency
ORDER BY
    CASE exposure_recency
        WHEN '0-30 days' THEN 1
        WHEN '31-90 days' THEN 2
        WHEN '91-180 days' THEN 3
        WHEN '181-365 days' THEN 4
        ELSE 5
    END;


-- Prior infection recency VS resistance rates
SELECT
    CASE
        WHEN pi.days_since_prior_infection <= 30 THEN '0-30 days'
        WHEN pi.days_since_prior_infection <= 90 THEN '31-90 days'
        WHEN pi.days_since_prior_infection <= 180 THEN '91-180 days'
        WHEN pi.days_since_prior_infection <= 365 THEN '181-365 days'
        WHEN pi.days_since_prior_infection <= 730 THEN '1-2 years'
        WHEN pi.days_since_prior_infection <= 1825 THEN '2-5 years'
        WHEN pi.days_since_prior_infection <= 3650 THEN '5-10 years'
        ELSE '10+ years'
    END AS infection_recency,
    COUNT(*) AS total_tested,
    SUM(cr.susceptibility = 'Resistant') AS resistant_count,
    ROUND((SUM(cr.susceptibility = 'Resistant') * 100.0) / COUNT(*), 2) AS pct_resistant
FROM cohort_results cr
JOIN prior_infections pi
    ON cr.culture_order_id = pi.culture_order_id
WHERE cr.susceptibility <> 'NOT_TESTED'
GROUP BY infection_recency
ORDER BY
    CASE infection_recency
        WHEN '0-30 days' THEN 1
        WHEN '31-90 days' THEN 2
        WHEN '91-180 days' THEN 3
        WHEN '181-365 days' THEN 4
        WHEN '1-2 years' THEN 5
        WHEN '2-5 years' THEN 6
        WHEN '5-10 years' THEN 7
        ELSE 8
    END;


-- ADI scores VS resistance rates
SELECT
    ad.adi_score,
    COUNT(*) AS total_tested,
    SUM(cr.susceptibility = 'Resistant') AS resistant_count,
    ROUND(SUM(cr.susceptibility = 'Resistant') * 100.0 / COUNT(*), 2) AS pct_resistant
FROM cohort_results cr
JOIN adi_complete_case_tbl ad
    ON cr.culture_order_id = ad.culture_order_id
WHERE cr.susceptibility <> 'NOT_TESTED'
GROUP BY ad.adi_score
HAVING total_tested >= 100
ORDER BY ad.adi_score ASC;


-- Resistance distribution across age groups
SELECT 
    d.age_group,
    COUNT(*) AS total_tested,
    SUM(c.susceptibility = 'Resistant') AS resistant_count,
    ROUND(
        SUM(c.susceptibility = 'Resistant') * 100.0 / COUNT(*),
        2
    ) AS pct_resistant
FROM demographics d
JOIN cohort_results c
    ON d.culture_order_id = c.culture_order_id
WHERE c.susceptibility != 'NOT_TESTED'
GROUP BY d.age_group
ORDER BY pct_resistant DESC;


-- Organism resistance cases
SELECT 
    organism,
    COUNT(*) AS total_tested,
    SUM(susceptibility = 'Resistant') AS resistant_count
FROM cohort_results
WHERE susceptibility != 'NOT_TESTED'
GROUP BY organism
HAVING resistant_count >= 100
ORDER BY resistant_count DESC;



