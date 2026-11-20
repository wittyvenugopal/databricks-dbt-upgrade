select
    date_trunc('month', received_at)                 as claim_month,
    triage_outcome,
    count(*)                                         as claims,
    sum(estimated_cost_gbp)                          as estimated_cost_gbp,
    round(avg(days_since_policy_start), 1)           as avg_days_since_policy_start
from {{ ref('fct_claims') }}
group by all
