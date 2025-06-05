*.sql linguist-language=SQL
--creating tables
CREATE TABLE hospital_capacity (
  name VARCHAR(100),
  age INTEGER,
  gender VARCHAR(10),
  blood_type VARCHAR(5),
  medical_condition VARCHAR(50),
  date_of_admission DATE,
  doctor VARCHAR(100),
  hospital VARCHAR(100),
  insurance_provider VARCHAR(100),
  billing_amount DECIMAL(12,2),
  room_number VARCHAR(10),
  admission_type VARCHAR(20),
  discharge_date DATE,
  medication VARCHAR(100),
  test_results VARCHAR(50)
);
--checking my data
select
*
from hospital_capacity

--1. How many unique patients are in the dataset?

SELECT 
	COUNT(DISTINCT (lower (name))) AS Total_Unique_Patients
FROM hospital_capacity;


--2. On average, which gender stays longer in the hospital?
SELECT
    gender,
    ROUND(AVG(discharge_date - date_of_admission)) || ' days' AS avg_duration
FROM hospital_capacity
GROUP BY gender
order by gender desc;


--3. What are the 3 most common blood types?
SELECT 
    Blood_type, 
    COUNT(DISTINCT LOWER(name)) AS unique_patient_count
FROM hospital_capacity 
GROUP BY Blood_type
ORDER BY unique_patient_count DESC
LIMIT 3
;

--4. Who are the top 5 doctors with the highest cumulative billing?


SELECT
  INITCAP(LOWER(REPLACE(REPLACE(TRIM(doctor), ' ', '_'), '.', ''))) AS doctor,
  '$' || TO_CHAR(SUM(billing_amount), 'FM999,999,999.00') AS total_billing_amount,
  RANK() OVER (ORDER BY SUM(billing_amount) DESC) AS rank_by_billing
FROM hospital_capacity
GROUP BY INITCAP(LOWER(REPLACE(REPLACE(TRIM(doctor), ' ', '_'), '.', '')))
ORDER BY rank_by_billing
limit 5 ;


--5 List the unique patients who stayed in the hospital longer than the average length of stay.

WITH avg_stay AS (
  SELECT AVG(discharge_date - date_of_admission) AS avg_days 
  FROM hospital_capacity
)
SELECT 
  DISTINCT INITCAP(LOWER(name)) AS patient_name,
  (discharge_date - date_of_admission) AS stay_length
FROM hospital_capacity, avg_stay
WHERE (discharge_date - date_of_admission) > avg_stay.avg_days
order by stay_length desc;

--6 How many unique patients stayed in the hospital longer than the average length of stay?

WITH avg_stay AS (
  SELECT AVG(discharge_date - date_of_admission) AS avg_days 
  FROM hospital_capacity
)
SELECT 
  COUNT(DISTINCT LOWER(name)) AS num_patients_above_avg
FROM hospital_capacity, avg_stay
WHERE (discharge_date - date_of_admission) > avg_stay.avg_days;

-- Ranking the season most admission count 
SELECT 
  CASE 
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (12, 1, 2) THEN 'Winter'
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (3, 4, 5) THEN 'Spring'
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (6, 7, 8) THEN 'Summer'
    ELSE 'Fall'
  END AS admission_season,
  COUNT(*) AS admissions_count
FROM hospital_capacity
GROUP BY 
  CASE 
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (12, 1, 2) THEN 'Winter'
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (3, 4, 5) THEN 'Spring'
    WHEN EXTRACT(MONTH FROM date_of_admission) IN (6, 7, 8) THEN 'Summer'
    ELSE 'Fall'
  END
ORDER BY admissions_count DESC;

--shorter code The second version uses a Common Table Expression (CTE) with a WITH clause to define the season once and reuse it throughout the query.
 
WITH seasonal_admissions AS (
  SELECT 
    CASE 
      WHEN EXTRACT(MONTH FROM date_of_admission) IN (12, 1, 2) THEN 'Winter'
      WHEN EXTRACT(MONTH FROM date_of_admission) IN (3, 4, 5) THEN 'Spring'
      WHEN EXTRACT(MONTH FROM date_of_admission) IN (6, 7, 8) THEN 'Summer'
      ELSE 'Fall'
    END AS season
  FROM hospital_capacity
)
SELECT 
  season AS admission_season,
  COUNT(*) AS admissions_count
FROM seasonal_admissions
GROUP BY season
ORDER BY admissions_count DESC;


--I dont have external data. Generating dummy breast cancer risk level by blood type and gender.
-- Step 1: Create the temp table
CREATE TEMP TABLE female_blood_risk 
	(blood_type TEXT,
  breast_cancer_risk TEXT);
  
-- Step 2: Insert values 
INSERT INTO female_blood_risk VALUES
  ('O+', 'High Risk'),
  ('A+', 'High Risk'),
  ('A-', 'High Risk'),
  ('O-', 'Low Risk'),
  ('A-', 'Low Risk'),
  ('B-', 'Low Risk');

-- Now joining 2 Tables
WITH risk_classified AS (
  SELECT
    CASE
      WHEN hc.gender ILIKE 'female' AND fbr.blood_type IS NOT NULL THEN fbr.breast_cancer_risk
      WHEN hc.gender ILIKE 'female' THEN 'Medium Risk'
      ELSE 'Unknown Risk'
    END AS breast_cancer_risk
  FROM hospital_capacity AS hc
  
  LEFT JOIN female_blood_risk AS fbr
    ON hc.blood_type = fbr.blood_type
)

SELECT 
  breast_cancer_risk,
  COUNT(*) AS patient_count
FROM risk_classified
GROUP BY breast_cancer_risk
ORDER BY 
  CASE breast_cancer_risk
    WHEN 'High Risk' THEN 1
    WHEN 'Medium Risk' THEN 2
    WHEN 'Low Risk' THEN 3
    ELSE 4
  END;














