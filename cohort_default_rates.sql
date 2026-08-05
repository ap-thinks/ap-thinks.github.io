-- ============================================================
-- Cohort Default Rate Analysis
-- Purpose: Track default rates by origination cohort (month/quarter)
--          to identify whether portfolio quality is improving or
--          deteriorating over time — a core portfolio monitoring task.
-- ============================================================

WITH cohort_base AS (
    SELECT
        borrower_id,
        DATE_TRUNC('month', origination_date)   AS cohort_month,
        loan_amount,
        risk_tier,
        predicted_default_proba,
        actual_default,
        days_to_first_delinquency
    FROM loan_originations lo
    LEFT JOIN borrower_predictions bp USING (borrower_id)
    WHERE origination_date >= DATEADD('month', -18, CURRENT_DATE)
),

cohort_performance AS (
    SELECT
        cohort_month,
        risk_tier,
        COUNT(*)                                        AS loans_originated,
        SUM(loan_amount)                                AS total_volume,
        SUM(actual_default)                             AS defaults,
        ROUND(AVG(actual_default) * 100, 2)             AS default_rate_pct,
        ROUND(AVG(predicted_default_proba) * 100, 2)   AS avg_predicted_risk_pct,
        -- Early delinquency signal (30 DPD within 90 days of origination)
        ROUND(
            AVG(CASE WHEN days_to_first_delinquency <= 90 THEN 1.0 ELSE 0.0 END) * 100
        , 2)                                            AS early_delinquency_rate_pct
    FROM cohort_base
    GROUP BY 1, 2
),

-- Month-over-month default rate change to flag deterioration
cohort_trend AS (
    SELECT
        *,
        LAG(default_rate_pct) OVER (
            PARTITION BY risk_tier ORDER BY cohort_month
        )                                               AS prior_month_default_rate,
        default_rate_pct - LAG(default_rate_pct) OVER (
            PARTITION BY risk_tier ORDER BY cohort_month
        )                                               AS mom_default_rate_change
    FROM cohort_performance
)

SELECT
    cohort_month,
    risk_tier,
    loans_originated,
    ROUND(total_volume / 1e6, 2)          AS volume_M,
    default_rate_pct,
    avg_predicted_risk_pct,
    early_delinquency_rate_pct,
    mom_default_rate_change,
    -- Flag cohorts where actual defaults significantly exceed model predictions
    CASE
        WHEN default_rate_pct > avg_predicted_risk_pct * 1.5 THEN 'REVIEW — Model Underestimating Risk'
        WHEN mom_default_rate_change > 2.0                   THEN 'WATCH — Rising Default Trend'
        ELSE 'Normal'
    END                                   AS risk_flag
FROM cohort_trend
ORDER BY cohort_month DESC, risk_tier;
