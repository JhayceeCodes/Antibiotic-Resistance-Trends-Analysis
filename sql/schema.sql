CREATE TABLE IF NOT EXISTS cohort_results(
    culture_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    culture_time TIMESTAMP,
    care_setting VARCHAR(50),
    culture_type VARCHAR(100),
    was_positive BOOLEAN,
    organism VARCHAR(150),
    antibiotic VARCHAR(150),
    susceptibility VARCHAR(50)
);


CREATE TABLE IF NOT EXISTS prior_infections(
    prior_infection_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    culture_time TIMESTAMP,
    prior_organism VARCHAR(150),
    days_since_prior_infection INT
);


CREATE TABLE IF NOT EXISTS adi_scores(
    adi_score_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    culture_time TIMESTAMP,
    adi_score DECIMAL(5,2),
    adi_state_rank INT
);




CREATE TABLE IF NOT EXISTS antibiotic_exposure(
    exposure_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    culture_time TIMESTAMP,
    med_category VARCHAR(50),
    medication VARCHAR(150),
    antibiotic_class VARCHAR(100),
    days_before_culture INT
);


CREATE TABLE IF NOT EXISTS demographics(
    demographic_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    age_group VARCHAR(20),
    gender INT
);


CREATE TABLE IF NOT EXISTS ward_info(
    ward_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    anon_id VARCHAR(20),
    encounter_id BIGINT,
    culture_order_id BIGINT,
    culture_time TIMESTAMP,
    is_inpatient BOOLEAN,
    is_outpatient BOOLEAN,
    is_er BOOLEAN,
    is_icu BOOLEAN
);





