-- ============================================================
-- Unit Economics Summary
-- Purpose: Compute revenue, loss, and contribution margin
--          per originated loan by risk tier and merchant vertical.
--          Core input for approval policy and portfolio strategy decisions.
-- ============================================================

WITH loan_base AS (
    SELECT
        lo.session_id,
        lo.merchant_id,
        lo.risk_tier,
        lo.loan_amount,
        lo.origination_date,
        lo.defaulted,
        lo.amount_recovered,
        lo.revenue_earned,
        m.vertical,

        -- Loss given default: loan amount less recovered amount
        CASE
            WHEN lo.defaulted = 1
            THEN lo.loan_amount - COALESCE(lo.amount_recovered, 0)
            ELSE 0
        END AS realized_loss,

        -- Net value per loan
        lo.revenue_earned - CASE
            WHEN lo.defaulted = 1
            THEN lo.loan_amount - COALESCE(lo.amount_recovered, 0)
            ELSE 0
        END AS net_contribution

    FROM loan_outcomes lo
    LEFT JOIN merchant_summary m USING (merchant_id)
),

-- Aggregate by risk tier
by_risk_tier AS (
    SELECT
        'By Risk Tier'                                  AS dimension,
        risk_tier                                       AS segment,
        COUNT(*)                                        AS loan_count,
        ROUND(AVG(loan_amount), 2)                      AS avg_loan_size,
        ROUND(AVG(defaulted) * 100, 1)                  AS default_rate_pct,
        ROUND(AVG(revenue_earned), 2)                   AS avg_revenue_per_loan,
        ROUND(AVG(realized_loss), 2)                    AS avg_loss_per_loan,
        ROUND(AVG(net_contribution), 2)                 AS avg_contribution_per_loan,
        ROUND(
            AVG(net_contribution)
            / NULLIF(AVG(loan_amount), 0) * 100
        , 1)                                            AS contribution_margin_pct,
        ROUND(SUM(net_contribution) / 1e6, 3)           AS total_contribution_M
    FROM loan_base
    GROUP BY risk_tier
),

-- Aggregate by merchant vertical
by_vertical AS (
    SELECT
        'By Vertical'                                   AS dimension,
        vertical                                        AS segment,
        COUNT(*)                                        AS loan_count,
        ROUND(AVG(loan_amount), 2)                      AS avg_loan_size,
        ROUND(AVG(defaulted) * 100, 1)                  AS default_rate_pct,
        ROUND(AVG(revenue_earned), 2)                   AS avg_revenue_per_loan,
        ROUND(AVG(realized_loss), 2)                    AS avg_loss_per_loan,
        ROUND(AVG(net_contribution), 2)                 AS avg_contribution_per_loan,
        ROUND(
            AVG(net_contribution)
            / NULLIF(AVG(loan_amount), 0) * 100
        , 1)                                            AS contribution_margin_pct,
        ROUND(SUM(net_contribution) / 1e6, 3)           AS total_contribution_M
    FROM loan_base
    GROUP BY vertical
)

SELECT * FROM by_risk_tier
UNION ALL
SELECT * FROM by_vertical
ORDER BY dimension, contribution_margin_pct DESC;
