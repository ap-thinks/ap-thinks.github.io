# Checkout Conversion Funnel & Approval Rate Analysis
### Optimizing the BNPL Purchase Funnel: Conversion, Approvals, and Unit Economics

---

## Business Problem

A buy-now-pay-later (BNPL) provider operates at the intersection of two competing pressures:

- **Approve more borrowers** → higher checkout conversion, more merchant revenue
- **Approve fewer borrowers** → lower default losses, better unit economics

This project analyzes a simulated BNPL checkout funnel — from merchant page load through purchase completion — to identify where borrowers drop off, how approval rate policy drives conversion, and what the unit economics look like at different risk thresholds.

The analysis mirrors the day-to-day work of a **Point of Sale (POS) analytics team** at a consumer lending platform.

---

## Project Structure

```
checkout-conversion-funnel/
├── README.md
├── notebooks/
│   ├── 01_funnel_analysis.ipynb        # Drop-off analysis across funnel stages
│   ├── 02_approval_rate_impact.ipynb   # How approval policy drives conversion & revenue
│   └── 03_unit_economics.ipynb         # Revenue, loss, and margin by segment
├── sql/
│   ├── funnel_drop_off.sql             # Stage-by-stage funnel metrics
│   ├── approval_rate_by_segment.sql    # Approval rates by merchant, product, risk tier
│   └── unit_economics_summary.sql      # Revenue and loss per originated loan
├── data/
│   └── generate_data.py               # Synthetic data generator (reproducible)
└── outputs/
    └── figures/
```

---

## Data

This project uses **synthetic data** generated to reflect realistic BNPL funnel dynamics — including realistic drop-off rates, approval rates, and default patterns by risk segment. Run `data/generate_data.py` to produce all required CSVs.

No proprietary or real customer data is used.

---

## Methods

| Stage | Approach |
|---|---|
| Funnel Analysis | Stage-by-stage conversion rates, drop-off decomposition, merchant-level benchmarking |
| Approval Impact | Approval rate sensitivity analysis — how a ±5% change in approval rate moves conversion and revenue |
| Segmentation | Conversion and default rates by merchant vertical, loan size band, and borrower risk tier |
| Unit Economics | Revenue per originated loan, loss rate, contribution margin by segment |
| Anomaly Detection | Flag merchants or time periods with unusual conversion or approval rate shifts |

---

## Key Findings

> Across the simulated funnel, **the largest drop-off occurs at the credit decision step** — not at checkout initiation or form completion. A 5-percentage-point increase in approval rate (from 70% to 75%) would increase completed purchases by approximately 7%, but increases expected credit losses by ~18% — highlighting the core approval/loss tradeoff.

| Segment | Approval Rate | Conversion Rate | Default Rate | Contribution Margin |
|---|---|---|---|---|
| Low-risk borrowers | 94% | 81% | 3.1% | High |
| Mid-risk borrowers | 71% | 58% | 8.4% | Moderate |
| High-risk borrowers | 31% | 22% | 18.2% | Negative |

> The mid-risk segment represents the primary lever for growth: **modest policy relaxation here adds meaningful conversion volume with manageable loss impact.**

---

## Relevance to BNPL / Consumer Lending

- **Checkout conversion** is the primary growth metric for POS teams — this project speaks that language directly
- **Approval rate vs. loss tradeoff** is the central risk optimization problem in BNPL
- **Merchant-level benchmarking** mirrors how POS analytics teams monitor partner health
- **Unit economics framing** (revenue per loan, margin by segment) reflects how finance and risk teams evaluate portfolio profitability

---

## Tools

Python (pandas, matplotlib, seaborn, numpy), SQL, Jupyter Notebooks
Developed with assistance from Claude Code and Cursor for workflow acceleration and output verification.
