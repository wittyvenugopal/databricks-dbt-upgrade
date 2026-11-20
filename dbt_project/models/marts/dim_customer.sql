select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    customer_id,
    full_name,
    age_band,
    postcode,
    {{ owner_team() }} as owner_team
from {{ ref('stg_customers') }}
