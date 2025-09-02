{% test expression_is_true(model, column_name, expression) %}
select *
from {{ model }}
where not ({{ expression }})
{% endtest %}
