-- ============================================================
-- Checkout Funnel Drop-off Analysis
-- Purpose: Compute stage-by-stage conversion rates and identify
--          where in the BNPL checkout funnel the most volume is lost.
--          Supports merchant performance benchmarking and product
--          optimization decisions.
-- ============================================================

WITH funnel_base AS (
    SELECT
        session_id,
        merchant_id,
        risk_tier,
        session_date,
        DATE_TRUNC('week', session_date)  AS session_week,

        -- Funnel stage flags (1 = reached/passed this stage)
        reached_page_load,
        passed_bnpl_click,
        passed_form_start,
        passed_form_complete,
        passed_approved,
        passed_purchase_complete
    FROM funnel_events
),

-- Overall funnel metrics
overall_funnel AS (
    SELECT
        'Overall'                                       AS segment,
        SUM(reached_page_load)                          AS page_loads,
        SUM(passed_bnpl_click)                          AS bnpl_clicks,
        SUM(passed_form_start)                          AS form_starts,
        SUM(passed_form_complete)                       AS form_completions,
        SUM(passed_approved)                            AS approvals,
        SUM(passed_purchase_complete)                   AS purchases,

        -- Step conversion rates
        ROUND(AVG(passed_bnpl_click)         * 100, 1) AS click_rate_pct,
        ROUND(AVG(passed_form_start)         * 100, 1) AS form_start_rate_pct,
        ROUND(AVG(passed_form_complete)      * 100, 1) AS form_complete_rate_pct,
        ROUND(AVG(passed_approved)           * 100, 1) AS approval_rate_pct,
        ROUND(AVG(passed_purchase_complete)  * 100, 1) AS purchase_rate_pct,

        -- End-to-end conversion
        ROUND(
            SUM(passed_purchase_complete) * 1.0
            / NULLIF(SUM(reached_page_load), 0) * 100
        , 1)                                            AS e2e_conversion_pct
    FROM funnel_base
),

-- Funnel by risk tier
tier_funnel AS (
    SELECT
        risk_tier                                       AS segment,
        SUM(reached_page_load)                          AS page_loads,
        SUM(passed_bnpl_click)                          AS bnpl_clicks,
        SUM(passed_form_start)                          AS form_starts,
        SUM(passed_form_complete)                       AS form_completions,
        SUM(passed_approved)                            AS approvals,
        SUM(passed_purchase_complete)                   AS purchases,
        ROUND(AVG(passed_bnpl_click)         * 100, 1) AS click_rate_pct,
        ROUND(AVG(passed_form_start)         * 100, 1) AS form_start_rate_pct,
        ROUND(AVG(passed_form_complete)      * 100, 1) AS form_complete_rate_pct,
        ROUND(AVG(passed_approved)           * 100, 1) AS approval_rate_pct,
        ROUND(AVG(passed_purchase_complete)  * 100, 1) AS purchase_rate_pct,
        ROUND(
            SUM(passed_purchase_complete) * 1.0
            / NULLIF(SUM(reached_page_load), 0) * 100
        , 1)                                            AS e2e_conversion_pct
    FROM funnel_base
    GROUP BY risk_tier
)

SELECT * FROM overall_funnel
UNION ALL
SELECT * FROM tier_funnel
ORDER BY segment;
