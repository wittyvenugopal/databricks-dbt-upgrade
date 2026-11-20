{{ config(materialized='table', pii_level='low') }}  -- V2: custom key in config(), must move under meta
select
    {{ dbt_utils.generate_surrogate_key(['p.policy_id']) }} as policy_sk,
    p.policy_id,
    c.customer_sk,
    p.product,
    p.sales_channel,
    p.cover_limit_gbp,
    p.premium_gbp,
    p.start_date,
    p.end_date,
    p.status,
    p.meets_min_cover
from {{ ref('stg_policies') }} p
join {{ ref('dim_customer') }} c on c.customer_id = p.customer_id
