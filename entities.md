### Schema
```bash
                demographics
                      |
                      |
prior_infecting —— cohort —— antibiotic_exposure
                      |
                      |
                  ward_info
                      |
                      |
                  adi_scores
```

---

## Cohort

> Main microbiology culture table containing organism identification and antibiotic susceptibility testing results.

| Column Name      | Data Type    | Notes                                                         |
| ---------------- | ------------ | ------------------------------------------------------------- |
| anon_id          | VARCHAR(20)  | De-identified patient identifier                              |
| encounter_id     | BIGINT       | De-identified patient encounter identifier                    |
| culture_order_id | BIGINT       | Unique culture order identifier                               |
| culture_time     | TIMESTAMP    | Jittered culture order timestamp for privacy preservation     |
| care_setting     | VARCHAR(50)  | Clinical ordering setting (e.g., inpatient, outpatient)       |
| culture_type     | VARCHAR(100) | Culture source/type (e.g., Urine, Blood)                      |
| was_positive | BOOLEAN      | Indicates whether culture was positive for organism growth    |
| organism         | VARCHAR(150) | Identified microorganism from the culture                     |
| antibiotic       | VARCHAR(150) | Antibiotic tested against the organism                        |
| susceptibility   | VARCHAR(50)  | Susceptibility outcome (Susceptible, Resistant, Intermediate) |


---

## Prior infecting organism

> Contains historical microbiology culture information showing prior infecting organisms before the current culture event.

| Column Name                | Data Type    | Notes                                                            |
| -------------------------- | ------------ | ---------------------------------------------------------------- |
| anon_id                    | VARCHAR(20)  | De-identified patient identifier                                 |
| encounter_id               | BIGINT       | Patient encounter identifier                                     |
| culture_order_id           | BIGINT       | Culture order identifier                                         |
| culture_time               | TIMESTAMP    | Jittered timestamp of current culture                            |
| prior_organism          | VARCHAR(150) | Previously identified infecting organism                         |
| days_since_prior_infection | INT          | Number of days between prior infection and current culture order |


---

## ADI Scores

> Contains Area Deprivation Index (ADI) metrics representing socioeconomic disadvantage associated with patient ZIP code regions.

| Column Name      | Data Type    | Notes                                                                |
| ---------------- | ------------ | -------------------------------------------------------------------- |
| anon_id          | VARCHAR(20)  | De-identified patient identifier                                     |
| encounter_id     | BIGINT       | Patient encounter identifier                                         |
| culture_order_id | BIGINT       | Culture order identifier                                             |
| culture_time     | TIMESTAMP    | Jittered timestamp of culture order                                  |
| adi_score        | DECIMAL(5,2) | Area Deprivation Index score representing socioeconomic disadvantage |
| adi_state_rank   | INT          | State-level ranking of ADI score                                     |

---

## Antibiotic class exposure

> Tracks patient exposure to antibiotics prior to the culture event.

| Column Name         | Data Type    | Notes                                              |
| ------------------- | ------------ | -------------------------------------------------- |
| anon_id             | VARCHAR(20)  | De-identified patient identifier                   |
| encounter_id        | BIGINT       | Patient encounter identifier                       |
| culture_order_id    | BIGINT       | Culture order identifier                           |
| culture_time        | TIMESTAMP    | Jittered timestamp of culture order                |
| med_category        | VARCHAR(50)  | Medication category classification                 |
| medication          | VARCHAR(150) | Generic medication name                            |
| antibiotic_class    | VARCHAR(100) | Antibiotic drug class                              |
| days_before_culture | INT          | Days between antibiotic exposure and culture order |


---

## Demographics

> Contains patient demographic information associated with culture orders.

| Column Name      | Data Type   | Notes                                                                  |
| ---------------- | ----------- | ---------------------------------------------------------------------- |
| anon_id          | VARCHAR(20) | De-identified patient identifier                                       |
| encounter_id     | BIGINT      | Patient encounter identifier                                           |
| culture_order_id | BIGINT      | Culture order identifier                                               |
| age_group        | VARCHAR(20) | Age grouped into bins (e.g., 18–24, 25–34, 90+)                        |
| gender           | INT         | Binary encoded gender value (0 or 1) without gender mapping disclosure |


---

## Ward info

> Describes the hospital care setting where the culture was collected.

| Column Name      | Data Type   | Notes                                |
| ---------------- | ----------- | ------------------------------------ |
| anon_id          | VARCHAR(20) | De-identified patient identifier     |
| encounter_id     | BIGINT      | Patient encounter identifier         |
| culture_order_id | BIGINT      | Culture order identifier             |
| culture_time     | TIMESTAMP   | Jittered timestamp of culture order  |
| is_inpatient     | BOOLEAN     | Indicates inpatient ward collection  |
| is_outpatient    | BOOLEAN     | Indicates outpatient ward collection |
| is_er            | BOOLEAN     | Indicates emergency room collection  |
| is_icu           | BOOLEAN     | Indicates ICU collection             |


---

## ~ Column Renaming Documentation
| Original CSV Column                      | New Standardized Column    |
| ---------------------------------------- | -------------------------- |
| pat_enc_csn_id_coded                     | encounter_id               |
| order_proc_id_coded                      | culture_order_id           |
| order_time_jittered_utc                  | culture_time               |
| ordering_mode                            | care_setting               |
| culture_description                      | culture_type               |
| prior_infecting_organism_days_to_culture | days_since_prior_infection |
| medication_category                      | med_category               |
| medication_name                          | medication                 |
| time_to_culturetime                      | days_before_culture        |
| hosp_ward_IP                             | is_inpatient               |
| hosp_ward_OP                             | is_outpatient              |
| hosp_ward_ER                             | is_er                      |
| hosp_ward_ICU                            | is_icu                     |


## ~ General Dataset Notes
| Topic              | Notes                                                                                              |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| Dataset Purpose    | Designed for antimicrobial resistance (AMR) and antimicrobial stewardship research                 |
| Source             | Stanford Healthcare electronic health records (EHR)                                                |
| Population Size    | Over 283,000 adult patients                                                                        |
| De-identification  | IDs anonymized, timestamps jittered, ages grouped into bins                                        |
| Missing Values     | Missing values represented as `"null"` in raw CSV files                                            |
| Linking Keys       | `anon_id`, `encounter_id`, `culture_order_id`, `culture_time`                                      |
| Main Analysis Goal | Analyze resistance trends, susceptibility patterns, antibiotic exposure, and clinical risk factors |
| Ethical Approval   | Stanford IRB eProtocol #70466                                                                      |
