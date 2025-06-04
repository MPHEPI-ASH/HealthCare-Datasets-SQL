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









