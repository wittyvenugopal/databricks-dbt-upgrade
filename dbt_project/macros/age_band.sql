{# Date of birth -> age band, as at a date. Uses SQL functions only - no v2 issue. #}
{% macro age_band(dob_col, as_at='current_date()') %}
    case
        when floor(months_between({{ as_at }}, {{ dob_col }}) / 12) < 25 then '18-24'
        when floor(months_between({{ as_at }}, {{ dob_col }}) / 12) < 45 then '25-44'
        when floor(months_between({{ as_at }}, {{ dob_col }}) / 12) < 65 then '45-64'
        else '65+'
    end
{% endmacro %}
