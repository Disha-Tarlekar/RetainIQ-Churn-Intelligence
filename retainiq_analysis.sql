-- ============================================================
--  RetainIQ | Customer Churn Intelligence
--  MySQL Analysis Script
--  Author: Disha Tarlekar
--  Tool: MySQL Workbench
-- ============================================================


-- ============================================================
-- STEP 1: DATABASE & TABLE SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS retainiq;
USE retainiq;

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id               VARCHAR(15)    PRIMARY KEY,
    plan_type                 VARCHAR(20),
    industry_vertical         VARCHAR(30),
    region                    VARCHAR(20),
    acquisition_channel       VARCHAR(30),
    contract_type             VARCHAR(15),
    tenure_months             INT,
    monthly_revenue           DECIMAL(10,2),
    annual_revenue            DECIMAL(10,2),
    support_tickets_last_90d  INT,
    nps_score                 INT,
    login_frequency_per_month INT,
    cac_inr                   DECIMAL(12,2),
    signup_date               DATE,
    churn_date                DATE,
    churned                   TINYINT(1),
    arr_loss_inr              DECIMAL(12,2)
);


-- ============================================================
-- STEP 2: IMPORT DATA
-- Run this in MySQL Workbench:
-- Server > Data Import > Import from Self-Contained File
-- Select retainiq_raw.csv > Target Schema: retainiq > Start Import
-- ============================================================


-- ============================================================
-- STEP 3: DATA QUALITY CHECK (before cleaning)
-- ============================================================

-- 3a. Total records loaded
SELECT COUNT(*) AS total_records FROM customers;

-- 3b. Check nulls in key columns
SELECT
    SUM(CASE WHEN plan_type               IS NULL THEN 1 ELSE 0 END) AS null_plan_type,
    SUM(CASE WHEN nps_score               IS NULL THEN 1 ELSE 0 END) AS null_nps_score,
    SUM(CASE WHEN support_tickets_last_90d IS NULL THEN 1 ELSE 0 END) AS null_support_tickets,
    SUM(CASE WHEN monthly_revenue         IS NULL THEN 1 ELSE 0 END) AS null_monthly_revenue,
    SUM(CASE WHEN tenure_months           IS NULL THEN 1 ELSE 0 END) AS null_tenure
FROM customers;

-- 3c. Check plan_type inconsistencies (lowercase entries from dirty data)
SELECT DISTINCT plan_type, COUNT(*) AS count
FROM customers
GROUP BY plan_type
ORDER BY plan_type;

-- 3d. Check for duplicate customer IDs
SELECT customer_id, COUNT(*) AS duplicate_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3e. Revenue sanity check — any zero or negative revenue
SELECT COUNT(*) AS suspicious_revenue_records
FROM customers
WHERE monthly_revenue <= 0;


-- ============================================================
-- STEP 4: DATA CLEANING
-- ============================================================

-- 4a. Standardize plan_type casing (fix lowercase dirty entries)
UPDATE customers
SET plan_type = CONCAT(UPPER(LEFT(plan_type, 1)), LOWER(SUBSTRING(plan_type, 2)))
WHERE plan_type != CONCAT(UPPER(LEFT(plan_type, 1)), LOWER(SUBSTRING(plan_type, 2)));

-- 4b. Fill null nps_score with plan-level median (conservative imputation)
UPDATE customers
SET nps_score = (
    SELECT ROUND(AVG(nps_score))
    FROM (SELECT nps_score FROM customers
          WHERE plan_type = customers.plan_type
          AND nps_score IS NOT NULL) AS sub
)
WHERE nps_score IS NULL;

-- 4c. Fill null support_tickets with 0 (no ticket = no record assumption)
UPDATE customers
SET support_tickets_last_90d = 0
WHERE support_tickets_last_90d IS NULL;

-- 4d. Verify cleaning results
SELECT
    COUNT(*)                                                    AS total_records,
    SUM(CASE WHEN nps_score IS NULL THEN 1 ELSE 0 END)         AS remaining_null_nps,
    SUM(CASE WHEN support_tickets_last_90d IS NULL THEN 1 ELSE 0 END) AS remaining_null_tickets,
    COUNT(DISTINCT plan_type)                                   AS distinct_plan_types
FROM customers;


-- ============================================================
-- STEP 5: CORE METRICS — CHURN RATE & ARR LOSS BY SEGMENT
-- ============================================================

-- 5a. Overall churn summary
SELECT
    COUNT(*)                                          AS total_customers,
    SUM(churned)                                      AS total_churned,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)        AS overall_churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                      AS total_arr_loss_inr,
    ROUND(SUM(arr_loss_inr) / 10000000, 2)           AS total_arr_loss_crore
FROM customers;

-- 5b. Churn rate and ARR loss by plan type
SELECT
    plan_type,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(AVG(monthly_revenue), 0)                        AS avg_monthly_rev_inr,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr,
    ROUND(SUM(arr_loss_inr) * 100.0 /
          SUM(SUM(arr_loss_inr)) OVER (), 1)              AS pct_of_total_arr_loss
FROM customers
GROUP BY plan_type
ORDER BY arr_loss_inr DESC;

-- 5c. Churn rate and ARR loss by industry vertical
SELECT
    industry_vertical,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY industry_vertical
ORDER BY arr_loss_inr DESC;

-- 5d. Churn rate by region
SELECT
    region,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY region
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- STEP 6: COHORT ANALYSIS — CHURN BY TENURE BAND
-- ============================================================

-- 6a. Define tenure bands and calculate churn per band
SELECT
    CASE
        WHEN tenure_months BETWEEN 0  AND 3  THEN '0-3 months'
        WHEN tenure_months BETWEEN 4  AND 6  THEN '4-6 months'
        WHEN tenure_months BETWEEN 7  AND 12 THEN '7-12 months'
        WHEN tenure_months BETWEEN 13 AND 24 THEN '13-24 months'
        ELSE '24+ months'
    END                                                   AS tenure_band,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY tenure_band
ORDER BY
    CASE tenure_band
        WHEN '0-3 months'   THEN 1
        WHEN '4-6 months'   THEN 2
        WHEN '7-12 months'  THEN 3
        WHEN '13-24 months' THEN 4
        ELSE 5
    END;

-- 6b. Tenure band × plan type cross-tab (high-value insight)
SELECT
    plan_type,
    CASE
        WHEN tenure_months BETWEEN 0  AND 6  THEN 'Early (0-6M)'
        WHEN tenure_months BETWEEN 7  AND 24 THEN 'Mid (7-24M)'
        ELSE 'Loyal (24M+)'
    END                                                   AS tenure_segment,
    COUNT(*)                                              AS customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY plan_type, tenure_segment
ORDER BY plan_type, churn_rate_pct DESC;


-- ============================================================
-- STEP 7: ACQUISITION CHANNEL ANALYSIS
-- (Unique angle: CAC wasted on churned customers)
-- ============================================================

SELECT
    acquisition_channel,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(AVG(cac_inr), 0)                               AS avg_cac_inr,
    ROUND(SUM(CASE WHEN churned = 1 THEN cac_inr ELSE 0 END), 0) AS total_cac_wasted_inr,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY acquisition_channel
ORDER BY total_cac_wasted_inr DESC;


-- ============================================================
-- STEP 8: CONTRACT TYPE ANALYSIS
-- ============================================================

SELECT
    contract_type,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr,
    ROUND(AVG(monthly_revenue), 0)                        AS avg_monthly_rev_inr
FROM customers
GROUP BY contract_type
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- STEP 9: HIGH-RISK CUSTOMER IDENTIFICATION
-- (Proactive outreach list — feeds Retention Strategy 3)
-- ============================================================

-- 9a. High-risk profile definition:
--     Monthly contract + tenure < 6M + support tickets >= 2 + low login frequency
SELECT
    customer_id,
    plan_type,
    industry_vertical,
    region,
    tenure_months,
    monthly_revenue,
    annual_revenue,
    support_tickets_last_90d,
    nps_score,
    login_frequency_per_month,
    contract_type,
    ROUND(monthly_revenue * 12, 0) AS arr_at_risk_inr
FROM customers
WHERE churned = 0
  AND contract_type = 'Monthly'
  AND tenure_months <= 6
  AND support_tickets_last_90d >= 2
  AND login_frequency_per_month <= 5
ORDER BY annual_revenue DESC
LIMIT 50;

-- 9b. Count of high-risk active customers + total ARR at risk
SELECT
    COUNT(*)                                              AS high_risk_active_customers,
    ROUND(SUM(annual_revenue), 0)                         AS arr_at_risk_inr
FROM customers
WHERE churned = 0
  AND contract_type = 'Monthly'
  AND tenure_months <= 6
  AND support_tickets_last_90d >= 2
  AND login_frequency_per_month <= 5;


-- ============================================================
-- STEP 10: NPS IMPACT ON CHURN
-- ============================================================

SELECT
    CASE
        WHEN nps_score >= 70 THEN 'Promoter (70-100)'
        WHEN nps_score >= 40 THEN 'Passive (40-69)'
        ELSE 'Detractor (0-39)'
    END                                                   AS nps_segment,
    COUNT(*)                                              AS total_customers,
    SUM(churned)                                          AS churned_customers,
    ROUND(SUM(churned) * 100.0 / COUNT(*), 1)            AS churn_rate_pct,
    ROUND(SUM(arr_loss_inr), 0)                           AS arr_loss_inr
FROM customers
GROUP BY nps_segment
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- STEP 11: METRIC DEFINITIONS (Documentation)
-- ============================================================

/*
  METRIC DEFINITIONS — RetainIQ Churn Intelligence Dashboard
  Documented for stakeholder consistency across all reporting

  1. Churn Rate (%)
     Formula : (Churned Customers / Total Customers) × 100
     Scope   : Calculated per segment (plan, vertical, region, tenure band)
     Note    : Based on historical churn status flag; not rolling/monthly rate

  2. ARR Loss (₹)
     Formula : Monthly Revenue × 12, summed for all churned customers
     Scope   : Reflects annualized revenue lost per segment
     Note    : Uses actual monthly_revenue per customer, not plan average

  3. CAC Wasted (₹)
     Formula : CAC (cost to acquire) summed for churned customers only
     Scope   : Per acquisition channel
     Note    : Highlights which channels produce low-retention customers

  4. ARR at Risk (₹)
     Formula : Annual Revenue of currently active high-risk customers
     Scope   : Customers meeting high-risk criteria (Step 9)
     Note    : Forward-looking metric — not historical loss

  5. Tenure Band
     Definition : Grouped tenure in months: 0-3 / 4-6 / 7-12 / 13-24 / 24+
     Purpose    : Cohort analysis — identifies churn concentration by lifecycle stage

  6. High-Risk Customer
     Definition : Active customer with Monthly contract + tenure ≤ 6M
                  + support tickets ≥ 2 + login frequency ≤ 5/month
     Purpose    : Proactive retention outreach targeting
*/
