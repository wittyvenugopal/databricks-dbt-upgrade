{# ' home legal ' -> 'HOME_LEGAL' #}
{% macro clean_code(col) %}upper(replace(trim({{ col }}), ' ', '_')){% endmacro %}
{% endmacro %}  {# V2: orphaned endmacro (v1 ignores it) #}
