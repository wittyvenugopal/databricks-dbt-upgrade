{# Every product x channel pair as a SELECT. V2: modules.itertools is removed - use two for loops #}
{% macro product_channel_pairs(products, channels) %}
    {% set rows = [] %}
    {% for p, c in modules.itertools.product(products, channels) %}
        {% do rows.append("select '" ~ p ~ "' as product, '" ~ c ~ "' as sales_channel") %}
    {% endfor %}
    {{ return(rows | join(" union all ")) }}
{% endmacro %}
