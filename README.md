# RetainIQ — Customer Churn Intelligence Dashboard

> A end-to-end marketing analytics project analyzing customer churn for a fictional B2B SaaS company — built to identify revenue loss patterns and propose data-backed retention strategies.

![Dashboard](https://img.shields.io/badge/Tool-Power%20BI-F2C811?style=flat-square&logo=powerbi) ![SQL](https://img.shields.io/badge/Tool-MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white) ![Python](https://img.shields.io/badge/Tool-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![Records](https://img.shields.io/badge/Dataset-7%2C500%20Records-brightgreen?style=flat-square)

---

## Project Overview

RetainIQ is a B2B SaaS company offering subscription plans (Basic, Pro, Enterprise) to businesses across E-commerce, Fintech, Edtech, and Healthcare verticals. This project analyzes **7,500 customer records** to answer one core business question:

> *Which customers are churning, how much ARR is being lost, and what can the marketing team do to stop it?*

**Headline finding:** Overall churn rate of **38.7%** resulted in **₹3.45 Cr ARR loss** — concentrated in the Basic plan tier, which accounts for 64.6% of total revenue lost despite being the lowest-revenue segment.

---

## Dashboard Pages

| Page | Title | Key Visual |
|------|-------|-----------|
| 1 | Executive Overview | 4 KPI cards · Donut chart · ARR loss by plan |
| 2 | Segment Deep-Dive | Churn by plan type · Regional breakdown · Summary table |
| 3 | Cohort & Channel Analysis | Tenure lifecycle curve · CAC wasted by channel · NPS impact |
| 4 | Retention Strategy | 3 data-backed strategies · High-risk outreach list |

---

## Key Findings

### 1. Churn is plan-driven, not industry-driven
| Plan | Churn Rate | ARR Lost |
|------|-----------|---------|
| Basic | 61.45% | ₹2.23 Cr |
| Pro | 15.07% | ₹0.91 Cr |
| Enterprise | 3.68% | ₹0.31 Cr |

All 4 industry verticals showed nearly identical churn rates (38.5–39.2%) — confirming that retention strategy should be **tier-based, not vertical-based**.

### 2. Early tenure = highest churn risk
Customers in their first 3 months churn at **~60%** — dropping to **~8%** at 24+ months. Onboarding is the single biggest retention lever.

### 3. Monthly contracts churn 3× more than Annual
- Monthly contract churn rate: **~57%**
- Annual contract churn rate: **~18%**

### 4. Social Media wastes the most acquisition budget
Social Media channel resulted in the highest CAC wasted on churned customers (~₹3.7M) — lowest retention ROI among all acquisition channels.

### 5. NPS is a leading churn indicator
- Detractors (NPS 0–39): **~55%** churn rate
- Promoters (NPS 70+): **~18%** churn rate

---

## Retention Strategies

### Strategy 1 — Annual Contract Push
**Finding:** Monthly customers churn at 57% vs 18% for annual — a 3× difference  
**Action:** Offer 20% discount on annual upgrade to Basic monthly customers within first 90 days  
**Est. ARR Recovered: ₹45L**

### Strategy 2 — Tenure Milestone Rewards
**Finding:** Churn drops from 60% to 8% between 0–3M and 24M+ tenure  
**Action:** Introduce loyalty rewards at 6M, 12M, 24M milestones — free feature unlock, dedicated support  
**Est. ARR Recovered: ₹32L**

### Strategy 3 — Proactive High-Risk Outreach
**Finding:** Monthly + tenure <6M + support tickets ≥2 + low login = highest churn probability  
**Action:** Auto-trigger CSM outreach when risk score hits threshold — personal call + save offer within 48 hours  
**Est. ARR Recovered: ₹28L**

**Total Estimated Recoverable ARR: ₹1.05 Cr**

---

## Metric Definitions

| Metric | Formula | Notes |
|--------|---------|-------|
| Churn Rate | Churned Customers / Total Customers × 100 | Calculated per segment |
| ARR Loss | Monthly Revenue × 12, summed for churned customers | Uses actual per-customer revenue |
| CAC Wasted | CAC summed for churned customers only | Per acquisition channel |
| ARR at Risk | Annual Revenue of active high-risk customers | Forward-looking metric |
| High-Risk Customer | Monthly contract + tenure ≤6M + tickets ≥2 + login ≤5/month | 5-factor risk definition |

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Python (Pandas, NumPy) | Synthetic dataset generation with realistic churn distributions |
| MySQL | Data cleaning, aggregations, ARR loss calculation, cohort analysis |
| Power BI + DAX | 4-page interactive dashboard with slicers and KPI cards |

---

## Project Structure

```
RetainIQ-Churn-Intelligence/
│
├── data/
│   └── retainiq_raw.csv          # 7,500 synthetic customer records
│
├── python/
│   └── generate_retainiq.py      # Dataset generation script
│
├── sql/
│   └── retainiq_analysis.sql     # Full SQL script (11 steps)
│
├── powerbi/
│   └── RetainIQ_Dashboard.pbix   # Power BI dashboard file
│
└── README.md
```

---

## How to Run

**1. Dataset**
The dataset (`retainiq_raw.csv`) is ready to use. To regenerate:
```bash
pip install pandas numpy
python generate_retainiq.py
```

**2. SQL Analysis**
- Open MySQL Workbench
- Run `retainiq_analysis.sql` step by step
- Import `retainiq_raw.csv` via Table Data Import Wizard

**3. Power BI Dashboard**
- Open `RetainIQ_Dashboard.pbix` in Power BI Desktop
- Refresh data source to point to your local `retainiq_raw.csv` path

---

## Author

**Disha Tarlekar**  
B.Sc. IT — Mumbai University (CGPA: 9.37)  
Marketing Data Analyst | SQL · Power BI · Python · GA4  
[GitHub](https://github.com/Disha-Tarlekar) · [LinkedIn](https://linkedin.com/in/disha-tarlekar)

---

*Built as part of a portfolio project to demonstrate end-to-end marketing analytics — from data generation to business recommendations.*
