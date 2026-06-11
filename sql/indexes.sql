CREATE INDEX idx_cohort_culture_order
ON cohort_results(culture_order_id);

CREATE INDEX idx_abx_culture_order
ON antibiotic_exposure(culture_order_id);

CREATE INDEX idx_prior_culture_order
ON prior_infections(culture_order_id);

CREATE INDEX idx_adi_culture_order
ON adi_scores(culture_order_id);

CREATE INDEX idx_demo_culture_order
ON demographics(culture_order_id);

CREATE INDEX idx_ward_culture_order
ON ward_info(culture_order_id);


CREATE INDEX idx_cohort_organism ON cohort_results(organism);
CREATE INDEX idx_cohort_susc ON cohort_results(susceptibility);
CREATE INDEX idx_cohort_age_join ON cohort_results(culture_order_id, susceptibility);

CREATE INDEX idx_demo_age ON demographics(age_group);

CREATE INDEX idx_exp_med_cat ON antibiotic_exposure(med_category);
CREATE INDEX idx_exp_days ON antibiotic_exposure(days_before_culture);

CREATE INDEX idx_cohort_ward_analysis
ON cohort_results (
    culture_order_id,
    susceptibility,
    care_setting
);

CREATE INDEX idx_ward_flags
ON ward_info (
    culture_order_id,
    is_icu,
    is_er
);


CREATE INDEX idx_abx_duplicate_check
ON antibiotic_exposure(
    culture_order_id,
    medication,
    days_before_culture
);

CREATE INDEX idx_cohort_org_sus
ON cohort_results(organism, susceptibility);

CREATE INDEX idx_cohort_sus_per_culture
ON cohort_results(susceptibility, culture_order_id);

CREATE INDEX idx_adi_complete_culture 
ON adi_complete_case_tbl(culture_order_id);


ANALYZE TABLE cohort_results;
ANALYZE TABLE antibiotic_exposure;
ANALYZE TABLE prior_infections;
ANALYZE TABLE adi_scores;
ANALYZE TABLE demographics;
ANALYZE TABLE ward_info;