-- Dispute types seen on claims.
-- V2: same name as the seed dispute_types. v1 warns and ref('dispute_types') picks the seed;
-- v2 stops with "ambiguous ref". Rename the model (stg_dispute_types_seen).
select distinct dispute_type
from {{ ref('claims') }}
