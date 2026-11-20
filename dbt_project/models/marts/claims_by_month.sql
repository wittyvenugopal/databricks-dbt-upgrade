select
    date_trunc('month', received_at)                 as claim_month,
    triage_outcome,
    count(*)                                         as claims,
    sum(estimated_cost_gbp)                          as estimated_cost_gbp,
    round(avg(days_since_policy_start), 1)           as avg_days_since_policy_start,
    -- V2: pytz object attributes render as '' in v2 (no error) - use a plain string or a var
    '{{ modules.pytz.timezone("Europe/London").zone }}' as report_timezone
from {{ ref('fct_claims') }}
group by all
