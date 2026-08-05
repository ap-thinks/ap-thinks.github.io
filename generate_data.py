"""
Synthetic BNPL Checkout Funnel Data Generator
==============================================
Generates realistic simulated data for a buy-now-pay-later checkout funnel.
All data is synthetic — no real customer or proprietary data used.

Output files:
  - funnel_events.csv      : One row per funnel event per user session
  - loan_outcomes.csv      : One row per approved loan with repayment outcome
  - merchant_summary.csv   : Merchant-level metadata
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta

np.random.seed(42)

# ── Configuration ─────────────────────────────────────────────────────────────
N_SESSIONS    = 50_000
N_MERCHANTS   = 30
START_DATE    = datetime(2024, 1, 1)
END_DATE      = datetime(2024, 12, 31)

MERCHANT_VERTICALS = ['Electronics', 'Fashion', 'Home & Garden', 'Travel', 'Health & Beauty']

# Risk tier definitions
RISK_TIERS = {
    'Low':    {'share': 0.40, 'approval_rate': 0.93, 'default_rate': 0.031, 'avg_loan': 450},
    'Mid':    {'share': 0.42, 'approval_rate': 0.71, 'default_rate': 0.084, 'avg_loan': 650},
    'High':   {'share': 0.18, 'approval_rate': 0.31, 'default_rate': 0.182, 'avg_loan': 800},
}

# Funnel stage drop-off rates (conditional on reaching that stage)
STAGE_CONVERSION = {
    'page_load':         1.00,
    'bnpl_click':        0.62,   # 62% of page loads click BNPL option
    'form_start':        0.81,   # 81% of clickers start the form
    'form_complete':     0.88,   # 88% of starters complete form
    'credit_decision':   1.00,   # everyone who completes form gets a decision
    'approved':          None,   # depends on risk tier
    'purchase_complete': 0.91,   # 91% of approved users complete purchase
}

# ── Generate merchants ─────────────────────────────────────────────────────────
merchants = pd.DataFrame({
    'merchant_id':   [f'M{str(i).zfill(3)}' for i in range(N_MERCHANTS)],
    'merchant_name': [f'Merchant_{i}' for i in range(N_MERCHANTS)],
    'vertical':      np.random.choice(MERCHANT_VERTICALS, N_MERCHANTS),
    'avg_order_value': np.random.uniform(200, 1200, N_MERCHANTS).round(2),
    'integration_date': [
        START_DATE - timedelta(days=int(d))
        for d in np.random.uniform(0, 365, N_MERCHANTS)
    ]
})

# ── Generate sessions ─────────────────────────────────────────────────────────
def random_dates(n, start, end):
    delta = (end - start).days
    return [start + timedelta(days=int(d)) for d in np.random.uniform(0, delta, n)]

sessions = pd.DataFrame({
    'session_id':  [f'S{str(i).zfill(6)}' for i in range(N_SESSIONS)],
    'user_id':     [f'U{str(np.random.randint(0, 35000)).zfill(6)}' for _ in range(N_SESSIONS)],
    'merchant_id': np.random.choice(merchants['merchant_id'], N_SESSIONS),
    'session_date': random_dates(N_SESSIONS, START_DATE, END_DATE),
    'risk_tier':   np.random.choice(
        list(RISK_TIERS.keys()),
        N_SESSIONS,
        p=[v['share'] for v in RISK_TIERS.values()]
    ),
    'loan_amount': np.nan
})

# Assign loan amounts based on risk tier
for tier, cfg in RISK_TIERS.items():
    mask = sessions['risk_tier'] == tier
    sessions.loc[mask, 'loan_amount'] = np.random.normal(
        cfg['avg_loan'], cfg['avg_loan'] * 0.3, mask.sum()
    ).clip(50, 2000).round(2)

# ── Simulate funnel progression ───────────────────────────────────────────────
events = []

for _, sess in sessions.iterrows():
    tier_cfg = RISK_TIERS[sess['risk_tier']]
    reached = True
    stage_results = {'session_id': sess['session_id'], 'risk_tier': sess['risk_tier'],
                     'merchant_id': sess['merchant_id'], 'loan_amount': sess['loan_amount'],
                     'session_date': sess['session_date']}

    for stage, rate in STAGE_CONVERSION.items():
        if not reached:
            stage_results[f'reached_{stage}'] = 0
            continue

        if stage == 'approved':
            p = tier_cfg['approval_rate']
        else:
            p = rate

        passed = np.random.random() < p
        stage_results[f'reached_{stage}'] = 1
        stage_results[f'passed_{stage}'] = int(passed)
        reached = passed

    events.append(stage_results)

funnel_df = pd.DataFrame(events)

# ── Generate loan outcomes for approved sessions ───────────────────────────────
approved_mask = funnel_df['passed_approved'] == 1
approved = funnel_df[approved_mask].copy()

outcomes = []
for _, row in approved.iterrows():
    tier_cfg = RISK_TIERS[row['risk_tier']]
    defaulted = np.random.random() < tier_cfg['default_rate']
    outcomes.append({
        'session_id':        row['session_id'],
        'merchant_id':       row['merchant_id'],
        'risk_tier':         row['risk_tier'],
        'loan_amount':       row['loan_amount'],
        'origination_date':  row['session_date'],
        'defaulted':         int(defaulted),
        'days_to_default':   int(np.random.uniform(30, 180)) if defaulted else None,
        'amount_recovered':  round(row['loan_amount'] * np.random.uniform(0.2, 0.6), 2) if defaulted else None,
        'revenue_earned':    round(row['loan_amount'] * 0.08, 2) if not defaulted else 0,
    })

loan_outcomes = pd.DataFrame(outcomes)

# ── Save ───────────────────────────────────────────────────────────────────────
funnel_df.to_csv('funnel_events.csv', index=False)
loan_outcomes.to_csv('loan_outcomes.csv', index=False)
merchants.to_csv('merchant_summary.csv', index=False)

print(f'Generated {len(funnel_df):,} sessions | {len(loan_outcomes):,} approved loans')
print(f'Overall approval rate:  {approved_mask.mean():.1%}')
print(f'Overall default rate:   {loan_outcomes["defaulted"].mean():.1%}')
print(f'Files saved: funnel_events.csv, loan_outcomes.csv, merchant_summary.csv')
