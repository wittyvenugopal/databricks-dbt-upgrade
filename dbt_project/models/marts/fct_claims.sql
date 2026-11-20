-- Intake & triage fact. Incremental: later runs only add/merge claims newer than the last load.
{{ config(materialized='incremental', unique_key='claim_id', incremental_strategy='merge') }}

with claims as (
    select * from {{ ref('stg_claims') }}
    {% if is_incremental() %}
    where received_at > (select max(received_at) from {{ this }})
    {% endif %}
)
select
    c.claim_id,
    p.policy_sk,
    p.customer_sk,
    c.received_at,
    c.intake_channel,
    c.dispute_type,
    c.dispute_category,
    c.estimated_cost_gbp,
    to_date(c.received_at) between p.start_date and p.end_date            as is_covered,
    {{ days_between('p.start_date', 'to_date(c.received_at)') }}           as days_since_policy_start,
    case
        when to_date(c.received_at) not between p.start_date and p.end_date then 'DECLINED'
        when c.refer_to_law_firm then 'REFER_TO_LAW_FIRM'
        else 'HELPLINE_ADVICE'
    end                                                                    as triage_outcome,
    row_number() over (partition by c.policy_id order by c.received_at)    as claim_number_on_policy,
    sum(c.estimated_cost_gbp) over (partition by c.policy_id order by c.received_at) as running_cost_on_policy_gbp,
    least(c.estimated_cost_gbp, p.cover_limit_gbp)                         as covered_cost_gbp
from claims c
join {{ ref('dim_policy') }} p on p.policy_id = c.policy_id
