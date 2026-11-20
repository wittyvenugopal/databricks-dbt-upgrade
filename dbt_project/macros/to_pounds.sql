{# Pence -> pounds. #}
{% macro to_pounds(pence) %}
    {{ return("cast(" ~ pence ~ " / 100.0 as decimal(12, 2))") }} -- V2: anything after return() is ignored
{% endmacro %}
