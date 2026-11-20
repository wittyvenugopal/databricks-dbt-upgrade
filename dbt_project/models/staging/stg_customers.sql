select
    customer_id,
    initcap(trim(full_name))         as full_name,
    cast(date_of_birth as date)      as date_of_birth,
    {{ age_band('cast(date_of_birth as date)') }} as age_band,
    lower(email)                     as email,
    upper(postcode)                  as postcode,
    cast(updated_at as timestamp)    as updated_at
from {{ ref('customers') }}
