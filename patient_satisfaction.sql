CREATE TABLE patients (
  patient_id VARCHAR(20) PRIMARY KEY,
  name VARCHAR(100),
  age INT,
  arrival_date DATE,
  departure_date DATE,
  service VARCHAR(50),
  satisfaction INT
);

SELECT COUNT(*) FROM patients; 

SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'patients';

-- Business Problems
--Q.1 Which service department has the highest average satisfaction score?

SELECT service, ROUND(AVG(satisfaction), 1) AS avg_satisfaction
FROM patients
GROUP BY service
ORDER BY avg_satisfaction DESC;


--Q.2 What's the average length of stay by service?
SELECT service, 
       ROUND(AVG(departure_date - arrival_date), 1) AS avg_length_of_stay_days
FROM patients
GROUP BY service
ORDER BY avg_length_of_stay_days DESC;


--Q.3 Is there a correlation between length of stay and satisfaction?
SELECT 
  CASE 
    WHEN (departure_date - arrival_date) <= 3 THEN '0-3 days'
    WHEN (departure_date - arrival_date) <= 7 THEN '4-7 days'
    WHEN (departure_date - arrival_date) <= 14 THEN '8-14 days'
    ELSE '15+ days'
  END AS stay_length_bucket,
  ROUND(AVG(satisfaction), 1) AS avg_satisfaction,
  COUNT(*) AS num_patients
FROM patients
GROUP BY stay_length_bucket
ORDER BY MIN(departure_date - arrival_date);


--Q.4 Which age group reports the lowest satisfaction?
SELECT 
  CASE 
    WHEN age <= 18 THEN '0-18'
    WHEN age <= 35 THEN '19-35'
    WHEN age <= 55 THEN '36-55'
    ELSE '56+'
  END AS age_group,
  ROUND(AVG(satisfaction), 1) AS avg_satisfaction,
  COUNT(*) AS num_patients
FROM patients
GROUP BY age_group
ORDER BY avg_satisfaction;


--Q.5 Does the service with longest stays also have the lowest satisfaction?
SELECT service,
       ROUND(AVG(departure_date - arrival_date), 1) AS avg_length_of_stay,
       ROUND(AVG(satisfaction), 1) AS avg_satisfaction
FROM patients
GROUP BY service
ORDER BY avg_length_of_stay DESC;


--Q.6 Top 10 longest patient stays and their service
SELECT patient_id, name, service, 
       (departure_date - arrival_date) AS length_of_stay_days
FROM patients
ORDER BY length_of_stay_days DESC
LIMIT 10;


--Q.7 Patient volume (arrivals) trend by month
SELECT DATE_TRUNC('month', arrival_date) AS month,
       COUNT(*) AS num_arrivals
FROM patients
GROUP BY month
ORDER BY month;


--Q.8 Which service has the most "at-risk" patients (satisfaction below 70)?

SELECT service,
       COUNT(*) AS at_risk_patients,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all_at_risk
FROM patients
WHERE satisfaction < 70
GROUP BY service
ORDER BY at_risk_patients DESC;


--Q.9 Rank patients within each service by satisfaction, flag bottom 10%
SELECT patient_id, name, service, satisfaction,
       NTILE(10) OVER (PARTITION BY service ORDER BY satisfaction) AS satisfaction_decile
FROM patients
ORDER BY service, satisfaction;