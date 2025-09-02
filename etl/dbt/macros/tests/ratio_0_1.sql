{% test ratio_0_1(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} < 0 or {{ column_name }} > 1
{% endtest %}
