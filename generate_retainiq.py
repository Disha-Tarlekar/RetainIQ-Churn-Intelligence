import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

np.random.seed(42)
random.seed(42)

N = 7500

# --- Plan config: name, monthly_rev range, base_churn_rate
PLANS = {
    "Basic":      {"rev": (499, 999),   "churn": 0.38},
    "Pro":        {"rev": (1499, 2499), "churn": 0.18},
    "Enterprise": {"rev": (4999, 9999), "churn": 0.07},
}

VERTICALS = ["E-commerce", "Edtech", "Fintech", "Healthcare"]
REGIONS   = ["Mumbai", "Delhi", "Bengaluru", "Hyderabad", "Pune", "Chennai"]
CHANNELS  = ["Organic Search", "Paid Search", "Social Media", "Referral", "Email Campaign", "Direct"]

CHANNEL_CHURN_MULTIPLIER = {
    "Organic Search":  0.85,
    "Paid Search":     1.10,
    "Social Media":    1.20,
    "Referral":        0.75,
    "Email Campaign":  0.95,
    "Direct":          0.80,
}

plan_weights   = [0.55, 0.33, 0.12]
vertical_weights = [0.30, 0.25, 0.25, 0.20]
region_weights   = [0.22, 0.20, 0.20, 0.14, 0.14, 0.10]
channel_weights  = [0.20, 0.18, 0.22, 0.15, 0.15, 0.10]

records = []

for i in range(1, N + 1):
    customer_id = f"RIQ-{i:05d}"

    plan     = np.random.choice(list(PLANS.keys()), p=plan_weights)
    vertical = np.random.choice(VERTICALS, p=vertical_weights)
    region   = np.random.choice(REGIONS,   p=region_weights)
    channel  = np.random.choice(CHANNELS,  p=channel_weights)

    # Tenure: Basic skews low, Enterprise skews high
    if plan == "Basic":
        tenure_months = int(np.random.exponential(scale=8)) + 1
    elif plan == "Pro":
        tenure_months = int(np.random.exponential(scale=16)) + 1
    else:
        tenure_months = int(np.random.exponential(scale=28)) + 1
    tenure_months = min(tenure_months, 60)

    # Monthly revenue with small noise
    rev_min, rev_max = PLANS[plan]["rev"]
    monthly_revenue = round(random.uniform(rev_min, rev_max), -1)  # round to nearest 10

    # Support tickets: more tickets → more churn risk
    support_tickets = max(0, int(np.random.poisson(lam=2 if plan == "Basic" else 1)))

    # NPS score: correlated with churn risk
    nps_base = {"Basic": 45, "Pro": 62, "Enterprise": 75}[plan]
    nps_score = int(np.clip(np.random.normal(nps_base, 18), 0, 100))

    # Login frequency (days/month): low login → high churn
    login_freq = max(1, int(np.random.normal(
        loc={"Basic": 6, "Pro": 14, "Enterprise": 22}[plan], scale=4
    )))

    # Contract type
    contract = np.random.choice(["Monthly", "Annual"],
                                p=[0.70, 0.30] if plan == "Basic"
                                else [0.45, 0.55] if plan == "Pro"
                                else [0.20, 0.80])

    # --- Churn probability calculation ---
    base_churn = PLANS[plan]["churn"]

    # Tenure effect: longer tenure = much lower churn
    if tenure_months <= 3:
        tenure_mod = 1.55
    elif tenure_months <= 6:
        tenure_mod = 1.25
    elif tenure_months <= 12:
        tenure_mod = 1.00
    elif tenure_months <= 24:
        tenure_mod = 0.70
    else:
        tenure_mod = 0.40

    channel_mod  = CHANNEL_CHURN_MULTIPLIER[channel]
    contract_mod = 1.30 if contract == "Monthly" else 0.55
    ticket_mod   = 1 + (support_tickets * 0.08)
    nps_mod      = 1.0 if nps_score >= 70 else (1.15 if nps_score >= 40 else 1.35)
    login_mod    = 1.30 if login_freq <= 4 else (1.00 if login_freq <= 10 else 0.80)

    churn_prob = base_churn * tenure_mod * channel_mod * contract_mod * ticket_mod * nps_mod * login_mod
    churn_prob = min(churn_prob, 0.92)  # cap

    churned = int(np.random.random() < churn_prob)

    # Dates
    signup_date = datetime(2022, 1, 1) + timedelta(days=random.randint(0, 700))
    if churned:
        churn_date = signup_date + timedelta(days=tenure_months * 30 + random.randint(-15, 15))
        churn_date_str = churn_date.strftime("%Y-%m-%d")
    else:
        churn_date_str = None

    # ARR loss (only for churned)
    arr_loss = round(monthly_revenue * 12, 2) if churned else 0.0

    # CAC (realistic SaaS Indian market)
    cac = {"Basic": round(random.uniform(2000, 5000), -2),
           "Pro":   round(random.uniform(6000, 15000), -2),
           "Enterprise": round(random.uniform(20000, 60000), -2)}[plan]

    records.append({
        "customer_id":      customer_id,
        "plan_type":        plan,
        "industry_vertical": vertical,
        "region":           region,
        "acquisition_channel": channel,
        "contract_type":    contract,
        "tenure_months":    tenure_months,
        "monthly_revenue":  monthly_revenue,
        "annual_revenue":   round(monthly_revenue * 12, 2),
        "support_tickets_last_90d": support_tickets,
        "nps_score":        nps_score,
        "login_frequency_per_month": login_freq,
        "cac_inr":          cac,
        "signup_date":      signup_date.strftime("%Y-%m-%d"),
        "churn_date":       churn_date_str,
        "churned":          churned,
        "arr_loss_inr":     arr_loss,
    })

df = pd.DataFrame(records)

# Introduce ~2% realistic data quality issues for SQL cleaning story
dirty_idx = df.sample(frac=0.02, random_state=7).index
df.loc[dirty_idx[:len(dirty_idx)//3], "nps_score"] = np.nan
df.loc[dirty_idx[len(dirty_idx)//3:2*len(dirty_idx)//3], "support_tickets_last_90d"] = np.nan
# A few plan name inconsistencies
df.loc[dirty_idx[2*len(dirty_idx)//3:], "plan_type"] = df.loc[
    dirty_idx[2*len(dirty_idx)//3:], "plan_type"].str.lower()

df.to_csv("/home/claude/retainiq_raw.csv", index=False)

# --- Quick validation summary ---
df_clean = df.copy()
df_clean["plan_type"] = df_clean["plan_type"].str.capitalize()
df_clean["churned_bool"] = df_clean["churned"] == 1

print("=== RetainIQ Dataset Summary ===")
print(f"Total records: {len(df_clean):,}")
print(f"Overall churn rate: {df_clean['churned_bool'].mean()*100:.1f}%")
print()
print("Churn rate by plan:")
print(df_clean.groupby("plan_type")["churned_bool"].mean().apply(lambda x: f"{x*100:.1f}%"))
print()
print("Avg monthly revenue by plan:")
print(df_clean.groupby("plan_type")["monthly_revenue"].mean().apply(lambda x: f"₹{x:,.0f}"))
print()
total_arr_loss = df_clean["arr_loss_inr"].sum()
print(f"Total ARR at risk: ₹{total_arr_loss:,.0f}")
print()
print("Records by plan:")
print(df_clean["plan_type"].value_counts())
