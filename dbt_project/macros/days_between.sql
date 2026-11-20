{% macro days_between(start_col, end_col) %}
    datediff({{ end_col }}, {{ start_col }})
{% endmacro %}
