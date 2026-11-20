-- SCD Type 2 history of policies, in the older SQL-block snapshot style.
{% snapshot policies_snapshot %}
{{ config(target_schema=target.schema ~ '_snapshots', unique_key='policy_id',
          strategy='timestamp', updated_at='updated_at') }}
select * from {{ ref('policies') }}
{% endsnapshot %}
