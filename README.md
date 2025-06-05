# Using R to convert a CSV file into SQL 'Create Table'

### Manually creating `CREATE TABLE` statements for PostgreSQL is time-consuming, especially with large healthcare datasets.
So I wrote an **R script** to auto-generate the SQL code for me.

 **Note:** The script sets every column as `TEXT` by default.  
> You'll need to manually change the data types to match the actual content (`INTEGER`, `NUMERIC`, `BOOLEAN`, etc.).


``
### loading the CSV file
data <- read.csv("C:/Users/computername/Downloads/healthcare_dataset.csv")
#turning the names sql safe
names(data) <- make.names(names(data), unique = TRUE)

#creating the SQL code
sql_cols <- paste(sprintf('"%s" TEXT', names(data)), collapse = ",\n  ")
create_sql <- sprintf("CREATE TABLE hospital_capacity (\n  %s\n);", sql_cols)

#printing for copy and paste
cat(create_sql)

**queries.sql**
### 1. How many unique patients are in the dataset?

### 👩‍🏫 Solution
``` sql
SELECT 
	COUNT(DISTINCT (lower (name))) AS Total_Unique_Patients
FROM hospital_capacity;
```



### Answer: 
There are 40,235 unique patients in the dataset.

![Image](https://github.com/user-attachments/assets/4459571e-bf07-452a-849e-2b13787916e0)

### 2. On average, which gender stays longer in the hospital?

### 👩‍🏫 Solution
```sql
SELECT
    gender,
    ROUND(AVG(discharge_date - date_of_admission)) || ' days' AS avg_duration
FROM hospital_capacity
GROUP BY gender
order by gender desc;
```


### Answer: 
On average, males stay 1 day longer than females in the hospital.

![Image](https://github.com/user-attachments/assets/543b0650-a0fd-4d7a-82e8-0ba0342b1509)

### 3. What are the 3 most common blood types?

### 👩‍🏫 Solution
```sql
SELECT 
    Blood_type, 
    COUNT(DISTINCT LOWER(name)) AS unique_patient_count
FROM hospital_capacity 
GROUP BY Blood_type
ORDER BY unique_patient_count DESC
LIMIT 3
;
```
### Answer: 
The three most common blood types are B+, AB+, and A-.

![Image](https://github.com/user-attachments/assets/7b8c047b-4ce1-47d7-8eda-3ee5e8ee04c7)


### 4. Who are the top 5 doctors with the highest cumulative billing?

### 👩‍🏫 Solution
```sql
SELECT
  INITCAP(LOWER(REPLACE(REPLACE(TRIM(doctor), ' ', '_'), '.', ''))) AS doctor,
  '$' || TO_CHAR(SUM(billing_amount), 'FM999,999,999.00') AS total_billing_amount,
  RANK() OVER (ORDER BY SUM(billing_amount) DESC) AS rank_by_billing
FROM hospital_capacity
GROUP BY INITCAP(LOWER(REPLACE(REPLACE(TRIM(doctor), ' ', '_'), '.', '')))
ORDER BY rank_by_billing
limit 5 ;
```
### Answer: 
The top 5 doctors with the highest cumulative billing are Michael_Smith, Robert_Smith, John_Smith, Robert_Johnson, and David_Smith.

![Image](https://github.com/user-attachments/assets/e4359310-6d10-4ded-90aa-aad769cbadd8)

### 5 List the unique patients who stayed in the hospital longer than the average length of stay.

### 👩‍🏫 Solution
```sql
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
```
### Answer: 
Here is the list:

![Image](https://github.com/user-attachments/assets/b80a3ff7-84e7-4ccf-97c8-b35cf423361b)

### 6 How many unique patients stayed in the hospital longer than the average length of stay?

### 👩‍🏫 Solution
```sql
WITH avg_stay AS (
  SELECT AVG(discharge_date - date_of_admission) AS avg_days 
  FROM hospital_capacity
)
SELECT 
  COUNT(DISTINCT LOWER(name)) AS num_patients_above_avg
FROM hospital_capacity, avg_stay
WHERE (discharge_date - date_of_admission) > avg_stay.avg_days;
```
### Answer: 
There are 21,875 unique patients who had hospital stays longer than the average.

![Image](https://github.com/user-attachments/assets/2b6ec4bb-2db6-408d-ab4c-64caa6d62bd1)

**7. Which season had the highest number of hospital admissions overall?**

### 👩‍🏫 Solution
longer version
```sql
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
```
### 👩‍🏫 alernative Solution
shorter code The second version uses a Common Table Expression (CTE) with a WITH clause to define the season once and reuse it throughout the query.

```sql
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
```
Answer:
The highest overall admission is Summer.

![Image](https://github.com/user-attachments/assets/18365fa3-013f-442c-a55b-ae2d0e2a21e5)

**8. What is the distribution of patients by breast cancer risk level based on gender and blood type?**

**I dont have external data. Generating dummy breast cancer risk level by blood type and gender.** 
Step 1: Create the temp table
```sql
CREATE TEMP TABLE female_blood_risk 
	(blood_type TEXT,
  breast_cancer_risk TEXT);
```
Step 2: Insert values 
```sql
INSERT INTO female_blood_risk VALUES
  ('O+', 'High Risk'),
  ('A+', 'High Risk'),
  ('A-', 'High Risk'),
  ('O-', 'Low Risk'),
  ('A-', 'Low Risk'),
  ('B-', 'Low Risk');
```
### 👩‍🏫 Solution

```sql
-- Classify patients by breast cancer risk
WITH risk_classified AS (
  SELECT
    CASE
      WHEN hc.gender ILIKE 'female' AND fbr.blood_type IS NOT NULL THEN fbr.breast_cancer_risk
      WHEN hc.gender ILIKE 'female' THEN 'Medium Risk'
      ELSE 'Unknown Risk'
    END AS breast_cancer_risk
  FROM hospital_capacity AS hc
-- Join on blood type
  LEFT JOIN female_blood_risk AS fbr
    ON hc.blood_type = fbr.blood_type
)
-- Count patients by risk level
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
```
**Answer:**
Here is the list of breast cancer risk categories and the number of patients in each group:

![Image](https://github.com/user-attachments/assets/7b25ffe9-5723-40cb-a078-a89e201b2162)


### 9. How are hospital patients distributed across billing amount quartiles?

### 👩‍🏫 Solution

```sql
--creating temp file for billing quartiles and unique_patient
with billing_quartile as (
	select 
		lower (trim(name)) as unique_patient,
		Billing_amount,
		ntile(4) over (order by billing_amount) as quartile
	from hospital_capacity
)
--writing the patient per quartile and billing range
select
	quartile as billing_quartile,
	count (distinct unique_patient ) as patient_count,
	min (billing_amount) as min_billing_amount,
	max (billing_amount) as max_billing_amount
from billing_quartile
group by quartile
order by quartile desc
;
```

### Answer: 

Patients are evenly split into four quartiles based on billing amount. The 1st quartile has the lowest billing range, while the 4th quartile has the highest.

![Image](https://github.com/user-attachments/assets/473c569c-163d-4df0-8a0c-4cd20bff3c97)




### 10. How many patients with Arthritis, Diabetes, Hypertension, Obesity, Cancer, and Asthma does each hospital treat? Present this information in a pivot table format.

### 👩‍🏫 Solution

``` sql
--checking the type of medical conditions
SELECT 
  medical_condition,
  COUNT(*) AS condition_count
FROM hospital_capacity
GROUP BY medical_condition
ORDER BY condition_count DESC;
-- creating a pivot table
SELECT
  hospital,
  COUNT(CASE WHEN medical_condition = 'Arthritis' THEN 1 END) AS arthritis_count,
  COUNT(CASE WHEN medical_condition = 'Diabetes' THEN 1 END) AS diabetes_count,
  COUNT(CASE WHEN medical_condition = 'Hypertension' THEN 1 END) AS hypertension_count,
  COUNT(CASE WHEN medical_condition = 'Obesity' THEN 1 END) AS obesity_count,
  COUNT(CASE WHEN medical_condition = 'Cancer' THEN 1 END) AS cancer_count,
  COUNT(CASE WHEN medical_condition = 'Asthma' THEN 1 END) AS asthma_count
FROM hospital_capacity
GROUP BY hospital
ORDER BY hospital;
```

### Answer: 
The pivot table above shows how many patients each hospital treats with the selected medical conditions: Arthritis, Diabetes, Hypertension, Obesity, Cancer, and Asthma. 

![image](https://github.com/user-attachments/assets/642af39a-79bd-4a86-8822-7504d2b07074)


