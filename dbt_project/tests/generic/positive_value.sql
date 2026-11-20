{# Custom generic test: fails on rows where the column is not > 0. #}
{% test positive_value(model, column_name) %}
select * from {{ model }} where {{ column_name }} <= 0
{% endtest %}
