-- ============================================================
-- Portfolio Risk Summary
-- Purpose: Aggregate borrower risk metrics at the portfolio level
--          to support ongoing performance monitoring.
--          Mirrors the kind of SQL an R&A analyst writes to
--          track approval rates, default rates, and loss exposure
--          across risk tiers.
-- ============================================================

WITH risk_tiers AS (
    SELECT
        borrower_id,
        predicted_default_proba,
        actual_default,
        loan_amount,
        CASE
            WHEN predicted_default_proba < 0.10 THEN 'Tier 1 — Low Risk'
            WHEN predicted_default_proba < 0.15 THEN 'Tier 2 — Moderate Risk'
            WHEN predicted_default_proba < 0.20 THEN 'Tier 3 — Elevated Risk'
            ELSE                                     'Tier 4 — High Risk (Declined)'
        END AS risk_tier,
        CASE WHEN predicted_default_proba < 0.15 THEN 1 ELSE 0 END AS approved
    FROM borrower_predictions
),

portfolio_summary AS (
    SELECT
        risk_tier,
        COUNT(*)                                        AS total_applicants,
        SUM(approved)                                   AS approved_count,
        ROUND(AVG(approved) * 100, 1)                   AS approval_rate_pct,
        ROUND(AVG(CASE WHEN approved = 1
                       THEN actual_default END) * 100, 1) AS default_rate_pct,
        SUM(CASE WHEN approved = 1
                 THEN loan_amount END)                  AS total_approved_volume,
        SUM(CASE WHEN approved = 1
                      AND actual_default = 1
                 THEN loan_amount * 0.60 END)           AS estimated_loss_exposure
    FROM risk_tiers
    GROUP BY risk_tier
)

SELECT
    risk_tier,
    total_applicants,
    approved_count,
    approval_rate_pct,
    default_rate_pct,
    ROUND(total_approved_volume / 1e6, 2)    AS approved_volume_M,
    ROUND(estimated_loss_exposure / 1e6, 2)  AS est_loss_exposure_M,
    ROUND(
        estimated_loss_exposure
        / NULLIF(total_approved_volume, 0) * 100, 1
    )                                        AS loss_rate_pct
FROM portfolio_summary
ORDER BY risk_tier;
