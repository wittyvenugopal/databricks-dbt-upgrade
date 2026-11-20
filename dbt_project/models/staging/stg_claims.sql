-- Claims joined to the dispute-type lookup seed.
select
    c.claim_id,
    c.policy_id,
    {{ clean_code('c.intake_channel') }}       as intake_channel,
    cast(c.received_at as timestamp)           as received_at,
    {{ clean_code('c.dispute_type') }}         as dispute_type,
    {{ clean_code('d.category') }}             as dispute_category,
    cast(d.refer_to_law_firm as boolean)       as refer_to_law_firm,
    {{ to_pounds('c.estimated_cost_pence') }}  as estimated_cost_gbp
from {{ ref('claims') }} c
left join {{ ref('dispute_types') }} d on d.dispute_type = c.dispute_type
