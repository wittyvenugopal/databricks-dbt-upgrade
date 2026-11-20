-- Singular test: a claim may only be DECLINED when the policy did not cover it.
select * from {{ ref('fct_claims') }}
where triage_outcome = 'DECLINED' and is_covered
