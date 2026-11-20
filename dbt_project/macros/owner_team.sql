{# Reads the custom +owner_team config. V2: use config.meta_get('owner_team') #}
{% macro owner_team() %}
    '{{ config.get("owner_team", "unknown") }}'
{% endmacro %}
