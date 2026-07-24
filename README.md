# Patient Satisfaction SQL Analysis Project

## 📌 Project Overview
This project analyzes hospital patient data using **PostgreSQL** to explore how satisfaction scores relate to length of stay, patient age, and service department. It covers the full pipeline: validating the raw dataset, loading it into PostgreSQL, and answering **9 business questions** related to satisfaction, length of stay, at-risk patients, and admission trends. The project demonstrates core SQL concepts including **window functions, CASE-based bucketing, date/time math, and aggregation**.

---

## 🛠️ Tools & Technologies
- PostgreSQL
- pgAdmin
- GitHub

---

## 📂 Dataset
- **Fields:** patient_id, name, age, arrival_date, departure_date, service, satisfaction
- 1,000 patient records across 4 service departments: surgery, ICU, emergency, general_medicine

---

## 🧹 Data Validation

Before loading into PostgreSQL, the dataset was checked for nulls, duplicate patient IDs, invalid dates, and out-of-range values.

```python
import pandas as pd

df = pd.read_csv('patients.csv')
df.isnull().sum()
df['patient_id'].duplicated().sum()
```

The dataset came back clean — **0 nulls, 0 duplicate patient IDs, no invalid or out-of-order dates** — so no cleaning steps were needed before loading.

---

## 🗄️ Loading Data into PostgreSQL

```sql
CREATE TABLE patients (
  patient_id VARCHAR(20) PRIMARY KEY,
  name VARCHAR(100),
  age INT,
  arrival_date DATE,
  departure_date DATE,
  service VARCHAR(50),
  satisfaction INT
);
```

Data was loaded via pgAdmin's Import/Export tool.

Verify the load:
```sql
SELECT COUNT(*) FROM patients;
```

---

## 🔍 Business Problems & SQL Solutions

### 1️⃣ Highest-rated service department
Which service department has the highest average satisfaction score?

```sql
SELECT service, ROUND(AVG(satisfaction), 1) AS avg_satisfaction
FROM patients
GROUP BY service
ORDER BY avg_satisfaction DESC;
```

---

### 2️⃣ Average length of stay by service
What's the average length of stay by service?

```sql
SELECT service, 
       ROUND(AVG(departure_date - arrival_date), 1) AS avg_length_of_stay_days
FROM patients
GROUP BY service
ORDER BY avg_length_of_stay_days DESC;
```

---

### 3️⃣ Length of stay vs. satisfaction
Is there a correlation between length of stay and satisfaction?

```sql
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
```

---

### 4️⃣ Satisfaction by age group
Which age group reports the lowest satisfaction?

```sql
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
```

---

### 5️⃣ Longest stays vs. lowest satisfaction
Does the service with the longest stays also have the lowest satisfaction?

```sql
SELECT service,
       ROUND(AVG(departure_date - arrival_date), 1) AS avg_length_of_stay,
       ROUND(AVG(satisfaction), 1) AS avg_satisfaction
FROM patients
GROUP BY service
ORDER BY avg_length_of_stay DESC;
```

---

### 6️⃣ Top 10 longest patient stays
What are the top 10 longest patient stays, and which service were they in?

```sql
SELECT patient_id, name, service, 
       (departure_date - arrival_date) AS length_of_stay_days
FROM patients
ORDER BY length_of_stay_days DESC
LIMIT 10;
```

---

### 7️⃣ Monthly arrival trends
How does patient volume (arrivals) trend by month?

```sql
SELECT DATE_TRUNC('month', arrival_date) AS month,
       COUNT(*) AS num_arrivals
FROM patients
GROUP BY month
ORDER BY month;
```

---

### 8️⃣ At-risk patients by service
Which service has the most "at-risk" patients (satisfaction below 70)?

```sql
SELECT service,
       COUNT(*) AS at_risk_patients,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_all_at_risk
FROM patients
WHERE satisfaction < 70
GROUP BY service
ORDER BY at_risk_patients DESC;
```

---

### 9️⃣ Bottom 10% by satisfaction, within each service
Within each service, who falls in the bottom 10% for satisfaction?

```sql
SELECT patient_id, name, service, satisfaction,
       NTILE(10) OVER (PARTITION BY service ORDER BY satisfaction) AS satisfaction_decile
FROM patients
ORDER BY service, satisfaction;
```

---

## 📊 Key Findings
- **Surgery has the highest average satisfaction (80.3)**, followed by ICU (79.9), emergency (79.5), and general medicine (78.6) — a narrow spread, so service alone isn't a strong driver of satisfaction.
- **Surgery also has the longest average stay (7.9 days)**, ahead of ICU (7.6), emergency (7.2), and general medicine (7.0). Longer stays don't correlate with lower satisfaction here — surgery has both the longest stays and the highest satisfaction.
- **Age has a mild effect**: patients 0–18 report the highest satisfaction (80.7), while patients 56+ report the lowest (78.7).
- **24.3% of all patients (243 of 1,000) are "at-risk"** (satisfaction below 70), with general medicine having the most (64), followed by ICU (62) and emergency (62), and surgery the fewest (55).
- Monthly arrival volume is fairly steady year-round, averaging ~83 patients/month, with no extreme seasonal spikes.
