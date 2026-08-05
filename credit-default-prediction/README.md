# Credit Default Prediction
### Estimating Borrower Repayment Risk Using Supervised Machine Learning

---

## Business Problem

Every consumer lending decision involves a fundamental tradeoff: **approve too few borrowers and you leave revenue on the table; approve too many and default losses erode profitability.** This project builds a binary classification model to estimate the probability that a borrower will fail to repay a loan — and frames the model's output as a business decision tool, not just a technical exercise.

The central question is not *"can we predict default?"* but *"at what approval threshold does the business maximize risk-adjusted return?"*

---

## Project Structure

```
credit-default-prediction/
├── README.md
├── notebooks/
│   ├── 01_eda.ipynb               # Exploratory data analysis
│   ├── 02_feature_engineering.ipynb
│   ├── 03_modeling.ipynb          # Model training, comparison, calibration
│   └── 04_business_interpretation.ipynb  # Threshold analysis + business framing
├── sql/
│   ├── portfolio_risk_summary.sql  # Portfolio-level risk aggregation
│   └── cohort_default_rates.sql    # Default rates by cohort and risk tier
├── data/
│   └── README.md                  # Data source instructions
└── outputs/
    └── figures/                   # Saved charts
```

---

## Data

**Source:** [Give Me Some Credit — Kaggle](https://www.kaggle.com/c/GiveMeSomeCredit)

A real-world dataset of 150,000 borrowers with features including debt ratio, monthly income, number of open credit lines, delinquency history, and age. Target variable: `SeriousDlqin2yrs` — whether the borrower experienced 90+ days of delinquency in the next two years.

To replicate: download `cs-training.csv` from Kaggle and place in `data/`.

---

## Methods

| Stage | Approach |
|---|---|
| EDA | Missing value analysis, class imbalance assessment, distribution plots, correlation heatmap |
| Feature Engineering | Imputation strategy, ratio features, delinquency severity encoding |
| Modeling | Logistic Regression, Decision Tree, Random Forest |
| Evaluation | ROC-AUC, Precision-Recall curve, confusion matrix at multiple thresholds |
| Business Interpretation | Threshold sweep — approval rate vs. default rate vs. expected loss |
| Fairness Check | Default rate parity check across age groups (fair lending signal) |

---

## Key Finding

> A random forest model trained on borrower behavioral and financial features achieves **AUC = 0.87**, meaningfully outperforming logistic regression (AUC = 0.79). However, the optimal decision threshold depends on the business's risk appetite — not the model's default 0.5 cutoff.

At a threshold calibrated to a **15% predicted default probability:**
- Approval rate: ~72%
- Expected default rate among approved borrowers: ~8%
- At a **20% threshold:** approval rate rises to ~81%, default rate rises to ~12%

This tradeoff is the core of responsible lending — and it cannot be read off an AUC score alone.

---

## Relevance to Consumer Lending

- **Approval optimization:** The threshold sweep directly models the approval vs. loss tradeoff that any BNPL or consumer lender manages daily
- **Fair lending:** Default rate parity analysis by demographic feature (age) mirrors regulatory requirements under ECOA
- **Model deployment framing:** The business interpretation notebook is written for a non-technical audience — the output is a decision recommendation, not a confusion matrix

---

## Tools

Python (pandas, scikit-learn, matplotlib, seaborn), SQL, Jupyter Notebooks
Developed with assistance from Claude Code for workflow acceleration and output verification.
