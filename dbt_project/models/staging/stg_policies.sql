select
    policy_id,
    customer_id,
    {{ clean_code('product') }}        as product,
    {{ clean_code('sales_channel') }}  as sales_channel,
    cover_limit_gbp,
    {{ to_pounds('premium_pence') }}   as premium_gbp,
    cast(start_date as date)           as start_date,
    cast(end_date as date)             as end_date,
    {{ clean_code('status') }}         as status,
    cover_limit_gbp >= {{ var('min_cover_gbp') }} as meets_min_cover,
    cast(updated_at as timestamp)      as updated_at
from {{ ref('policies') }}
